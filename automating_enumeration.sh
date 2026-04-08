#!/bin/bash
set -euo pipefail

# ─── Usage ────────────────────────────────────────────────────────────────────
usage() {
    echo "Usage: $0 <domain|IP> [custom_wordlist]"
    echo "  domain|IP       Target domain name or IP address"
    echo "  custom_wordlist Optional path to a custom wordlist for directory brute-forcing"
    exit 1
}

[[ $# -lt 1 ]] && usage

TARGET="$1"
WORDLIST="${2:-}"

# ─── Input Validation ─────────────────────────────────────────────────────────
is_ip() {
    local ip="$1" IFS='.'
    local -a octets
    read -ra octets <<< "$ip"
    [[ ${#octets[@]} -eq 4 ]] || return 1
    local o
    for o in "${octets[@]}"; do
        [[ "$o" =~ ^[0-9]+$ ]] && [[ "$o" -le 255 ]] || return 1
    done
}

is_domain() {
    [[ "$1" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]
}

TARGET_TYPE="unknown"
if is_ip "$TARGET"; then
    TARGET_TYPE="ip"
elif is_domain "$TARGET"; then
    TARGET_TYPE="domain"
else
    echo "[-] Invalid input: '$TARGET'. Provide a valid domain or IP address."
    exit 1
fi

# ─── Tool Checks ──────────────────────────────────────────────────────────────
check_tool() {
    if ! command -v "$1" &>/dev/null; then
        echo "[-] Required tool not found: $1  (run install_dependencies.sh)"
        exit 1
    fi
}

for t in httprobe nikto feroxbuster; do check_tool "$t"; done

if [[ "$TARGET_TYPE" == "domain" ]]; then
    for t in assetfinder amass subjack; do check_tool "$t"; done
fi

# Optional tools – used if present
HAS_WHATWEB=false; command -v whatweb   &>/dev/null && HAS_WHATWEB=true
HAS_WAYBACK=false; command -v waybackurls &>/dev/null && HAS_WAYBACK=true

# ─── Directory Setup ──────────────────────────────────────────────────────────
OUTDIR="$TARGET"
RECON="$OUTDIR/recon"

mkdir -p \
    "$RECON/scans"       \
    "$RECON/httprobe"    \
    "$RECON/nikto"       \
    "$RECON/directories" \
    "$RECON/whatweb"

[[ "$TARGET_TYPE" == "domain" ]] && mkdir -p \
    "$RECON/subdomains"           \
    "$RECON/potential_takeovers"

# Reset output files on each run
: > "$RECON/final.txt"
: > "$RECON/httprobe/alive.txt"

echo "[+] Target : $TARGET ($TARGET_TYPE)"
echo "[+] Output : $RECON"
echo ""

# ─── Subdomain Enumeration (domain only) ──────────────────────────────────────
if [[ "$TARGET_TYPE" == "domain" ]]; then
    echo "[+] Harvesting subdomains with assetfinder..."
    assetfinder --subs-only "$TARGET" \
        | grep -E "(^|\.)${TARGET}$" \
        | sort -u > "$RECON/subdomains/assetfinder.txt"

    echo "[+] Harvesting subdomains with amass..."
    amass enum -passive -d "$TARGET" \
        | sort -u > "$RECON/subdomains/amass.txt" 2>/dev/null || true

    echo "[+] Merging subdomain sources..."
    sort -u \
        "$RECON/subdomains/assetfinder.txt" \
        "$RECON/subdomains/amass.txt"        \
        > "$RECON/final.txt"

    echo "[+] Probing for alive web services..."
    # httprobe outputs full URLs (http:// or https://) — keep them as-is
    httprobe -prefer-https < "$RECON/final.txt" \
        | sort -u > "$RECON/httprobe/alive.txt"

    echo "[+] Checking for subdomain takeovers..."
    FINGERPRINTS="$HOME/go/src/github.com/haccer/subjack/fingerprints.json"
    SUBJACK_ARGS=(-w "$RECON/httprobe/alive.txt" -t 100 -timeout 30 -ssl -v 3)
    [[ -f "$FINGERPRINTS" ]] && SUBJACK_ARGS+=(-c "$FINGERPRINTS") \
        || echo "[-] subjack fingerprints.json not found, running without fingerprints..."
    subjack "${SUBJACK_ARGS[@]}" \
        > "$RECON/potential_takeovers/potential_takeovers.txt" 2>/dev/null || true

else
    echo "[+] Probing IP for live web services..."
    # httprobe probes http:80 and https:443 by default; -prefer-https picks https if both answer
    echo "$TARGET" | httprobe -prefer-https -p https:8443 -p http:8080 \
        | sort -u > "$RECON/httprobe/alive.txt"
    echo "$TARGET" > "$RECON/final.txt"
fi

ALIVE_COUNT=$(wc -l < "$RECON/httprobe/alive.txt")
echo "[+] Live web hosts found: $ALIVE_COUNT"

if [[ "$ALIVE_COUNT" -eq 0 ]]; then
    echo "[-] No live web targets — skipping web enumeration."
    exit 0
fi

# ─── Technology Detection ──────────────────────────────────────────────────────
if $HAS_WHATWEB; then
    echo "[+] Detecting web technologies with whatweb..."
    while IFS= read -r host; do
        whatweb --color=never "$host" >> "$RECON/whatweb/results.txt" 2>/dev/null || true
    done < "$RECON/httprobe/alive.txt"
fi

# ─── Directory / File Enumeration ─────────────────────────────────────────────
echo "[+] Starting directory enumeration with feroxbuster..."
while IFS= read -r host; do
    # Build a filesystem-safe name from the full URL
    safe_name=$(printf '%s' "$host" | sed 's|[^a-zA-Z0-9._-]|_|g')
    outfile="$RECON/directories/${safe_name}.txt"

    echo "[*] feroxbuster → $host  ($(date +'%H:%M:%S'))"

    FEROX_ARGS=(
        -u "$host"
        --depth 2
        --redirects
        --silent
        --filter-status 404,403
        -o "$outfile"
    )
    [[ -n "$WORDLIST" && -f "$WORDLIST" ]] && FEROX_ARGS+=(-w "$WORDLIST")

    feroxbuster "${FEROX_ARGS[@]}" 2>/dev/null || true
done < "$RECON/httprobe/alive.txt"

# ─── Wayback URL Harvesting ────────────────────────────────────────────────────
if $HAS_WAYBACK && [[ "$TARGET_TYPE" == "domain" ]]; then
    echo "[+] Fetching historical URLs from Wayback Machine..."
    mkdir -p "$RECON/wayback"
    waybackurls "$TARGET" \
        | sort -u > "$RECON/wayback/urls.txt" 2>/dev/null || true
    echo "    Saved $(wc -l < "$RECON/wayback/urls.txt") URLs"
fi

# ─── Nikto Vulnerability Scans ────────────────────────────────────────────────
echo "[+] Running nikto vulnerability scans..."
while IFS= read -r host; do
    safe_name=$(printf '%s' "$host" | sed 's|[^a-zA-Z0-9._-]|_|g')
    echo "[*] nikto → $host"
    nikto -h "$host" -Format htm \
          -output "$RECON/nikto/${safe_name}.html" 2>/dev/null || true
done < "$RECON/httprobe/alive.txt"

# ─── Summary ──────────────────────────────────────────────────────────────────
TOTAL_COUNT=$(wc -l < "$RECON/final.txt")

echo ""
echo "========================================="
echo "[+] Recon complete!  Results in: $RECON/"
echo "========================================="
printf "  %-22s %s\n" "Hosts enumerated:"  "$TOTAL_COUNT"
printf "  %-22s %s\n" "Live web hosts:"    "$ALIVE_COUNT"
echo ""
echo "Key output files:"
printf "  %-36s %s\n" "All hosts:"          "$RECON/final.txt"
printf "  %-36s %s\n" "Alive (HTTP/S):"     "$RECON/httprobe/alive.txt"
printf "  %-36s %s\n" "Directory results:"  "$RECON/directories/"
printf "  %-36s %s\n" "Nikto reports:"      "$RECON/nikto/"
$HAS_WHATWEB && printf "  %-36s %s\n" "Tech fingerprints:" "$RECON/whatweb/results.txt"
if [[ "$TARGET_TYPE" == "domain" ]]; then
    printf "  %-36s %s\n" "Subdomain lists:"   "$RECON/subdomains/"
    printf "  %-36s %s\n" "Takeover check:"    "$RECON/potential_takeovers/potential_takeovers.txt"
    $HAS_WAYBACK && printf "  %-36s %s\n" "Wayback URLs:" "$RECON/wayback/urls.txt"
fi

