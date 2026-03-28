#!/bin/bash

url=$1
custom_wordlist=$2

# Function to validate if input is an IP address
is_ip() {
    if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    return 1
}

# Function to validate if input is a domain
is_domain() {
    if [[ $1 =~ ^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        return 0
    fi
    return 1
}

# Determine target type
TARGET_TYPE="unknown"
if is_ip "$url"; then
    TARGET_TYPE="ip"
elif is_domain "$url"; then
    TARGET_TYPE="domain"
else
    echo "[-] Invalid input. Please provide a valid domain or IP address."
    exit 1
fi

# Check for common required tools
if [ ! -x "$(command -v httprobe)" ]; then
    echo "[-] httprobe required to run script"
    exit 1
fi

if [ ! -x "$(command -v nikto)" ]; then
    echo "[-] nikto required to run script"
    exit 1
fi

# Check domain-specific tools
if [ "$TARGET_TYPE" = "domain" ]; then
    if [ ! -x "$(command -v assetfinder)" ]; then
        echo "[-] assetfinder required to run script for domain targets"
        exit 1
    fi

    if [ ! -x "$(command -v amass)" ]; then
        echo "[-] amass required to run script for domain targets"
        exit 1
    fi

    if [ ! -x "$(command -v sublist3r)" ]; then
        echo "[-] sublist3r required to run script for domain targets"
        exit 1
    fi
fi

# Check IP-specific tools
if [ "$TARGET_TYPE" = "ip" ]; then
    if [ ! -x "$(command -v feroxbuster)" ]; then
        echo "[-] feroxbuster required to run script for IP targets"
        exit 1
    fi
fi

# Create directory structure
if [ ! -d "$url" ]; then
    mkdir "$url"
fi
if [ ! -d "$url/recon" ]; then
    mkdir "$url/recon"
fi

# Create domain-specific directories
if [ "$TARGET_TYPE" = "domain" ]; then
    if [ ! -d "$url/recon/3rd-lvls" ]; then
        mkdir "$url/recon/3rd-lvls"
    fi
    if [ ! -d "$url/recon/potential_takeovers" ]; then
        mkdir "$url/recon/potential_takeovers"
    fi
fi

# Create common directories
if [ ! -d "$url/recon/scans" ]; then
    mkdir "$url/recon/scans"
fi
if [ ! -d "$url/recon/httprobe" ]; then
    mkdir "$url/recon/httprobe"
fi
if [ ! -d "$url/recon/nikto" ]; then
    mkdir "$url/recon/nikto"
fi

# Initialize output files
if [ ! -f "$url/recon/httprobe/alive.txt" ]; then
    touch "$url/recon/httprobe/alive.txt"
fi
if [ ! -f "$url/recon/final.txt" ]; then
    touch "$url/recon/final.txt"
fi
if [ "$TARGET_TYPE" = "domain" ]; then
    if [ ! -f "$url/recon/3rd-lvl-domains.txt" ]; then
        touch "$url/recon/3rd-lvl-domains.txt"
    fi
fi

echo "[+] Target type: $TARGET_TYPE"

if [ "$TARGET_TYPE" = "domain" ]; then
    echo "[+] Harvesting subdomains with assetfinder..."
    assetfinder "$url" | grep "\.$url" | sort -u | tee -a "$url/recon/final1.txt"

    echo "[+] Double checking for subdomains with amass..."
    amass enum -d "$url" | tee -a "$url/recon/final1.txt"

    sort -u "$url/recon/final1.txt" >> "$url/recon/final.txt"
    rm -f "$url/recon/final1.txt"

    echo "[+] Compiling 3rd level domains..."
    cat "$url/recon/final.txt" | grep -Po '(\w+\.\w+\.\w+)$' | sort -u >> "$url/recon/3rd-lvl-domains.txt"

    # Add 3rd level domains to final list
    while IFS= read -r line; do
        echo "$line" | sort -u | tee -a "$url/recon/final.txt"
    done < "$url/recon/3rd-lvl-domains.txt"

    echo "[+] Harvesting subdomains with sublist3r..."
    while IFS= read -r domain; do
        sublist3r -d "$domain" -o "$url/recon/3rd-lvls/$domain.txt" 2>/dev/null || true
    done < "$url/recon/3rd-lvl-domains.txt"

    echo "[+] Probing for alive domains..."
    cat "$url/recon/final.txt" | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' | sort -u >> "$url/recon/httprobe/alive.txt"
else
    # For IP addresses, add them directly to final and alive lists
    echo "[+] Processing IP address..."
    echo "$url" | sort -u >> "$url/recon/final.txt"
    echo "$url" | sort -u >> "$url/recon/httprobe/alive.txt"
fi

echo "[+] Checking for possible subdomain takeover..."
if [ "$TARGET_TYPE" = "domain" ]; then
    if [ ! -f "$url/recon/potential_takeovers/domains.txt" ]; then
        touch "$url/recon/potential_takeovers/domains.txt"
    fi
    if [ ! -f "$url/recon/potential_takeovers/potential_takeovers.txt" ]; then
        touch "$url/recon/potential_takeovers/potential_takeovers.txt"
    fi

    while IFS= read -r line; do
        echo "$line" | sort -u >> "$url/recon/potential_takeovers/domains.txt"
    done < "$url/recon/final.txt"

    fp="$HOME/go/src/github.com/haccer/subjack/fingerprints.json"
    if [ -f "$fp" ]; then
        subjack -w "$url/recon/httprobe/alive.txt" -t 100 -timeout 30 -ssl -c "$fp" -v 3 >> "$url/recon/potential_takeovers/potential_takeovers.txt" 2>/dev/null || true
    else
        echo "[-] subjack fingerprints.json not found, running without fingerprints..."
        subjack -w "$url/recon/httprobe/alive.txt" -t 100 -timeout 30 -ssl -v 3 >> "$url/recon/potential_takeovers/potential_takeovers.txt" 2>/dev/null || true
    fi
else
    echo "[*] Skipping subdomain takeover check for IP address"
fi

echo "[+] Probing alive targets for web enumeration..."
# For both domain and IP targets, use the alive hosts list
web_targets="$(cat "$url/recon/httprobe/alive.txt" 2>/dev/null | sort -u)"

echo "[+] Scanning for directories..."
if [ -n "$web_targets" ]; then
    echo "[+] Web targets found, enumerating directories..."
    if [ ! -d "$url/recon/directories" ]; then
        mkdir "$url/recon/directories"
    fi
    
    for target in $web_targets; do
        echo "[*] Running feroxbuster on $target with 2-level recursion $(date +'%Y-%m-%d %T')"
        # Run feroxbuster with custom wordlist if provided
        if [ -n "${custom_wordlist:-}" ] && [ -f "$custom_wordlist" ]; then
            feroxbuster -u "$target" -r --depth 2 -w "$custom_wordlist" -o "$url/recon/directories/ferox_full.txt" 2>/dev/null || true
        else
            feroxbuster -u "$target" -r --depth 2 -o "$url/recon/directories/ferox_full.txt" 2>/dev/null || true
        fi
        
        # Filter for 200 status codes and redirects, exclude only binary files
        ferox_file="$url/recon/directories/ferox_full.txt"
        if [ -f "$ferox_file" ]; then
            echo "=== Directory Enumeration Results for $target ===" > "$url/recon/directories/enum_results.txt"
            echo "" >> "$url/recon/directories/enum_results.txt"
            grep -E '(200|301|302|307|308).*GET' "$ferox_file" | grep -vE '\.(gif|png|jpg|jpeg|svg|ico|webp|woff|woff2|ttf|otf|eot|zip|gz|tgz)' >> "$url/recon/directories/enum_results.txt" 2>/dev/null || true
            rm -f "$ferox_file"
        fi
        
        sleep 1
    done
else
    echo "[*] No web targets found, skipping directory enumeration"
fi

echo "[+] Scanning for web vulnerabilities with nikto..."
if [ -z "$web_targets" ]; then
    echo "[*] No web targets found for nikto scanning"
else
    for target in $web_targets; do
        echo "[*] Running nikto on $target..."
        # Extract hostname/IP from URL for filename
        target_host=$(echo "$target" | sed 's|^https\?://||' | sed 's|/.*||' | sed 's/\./_/g')
        nikto -h "$target" -Format HTML -output "$url/recon/nikto/${target_host}.html" 2>/dev/null || true
    done
fi

echo "[+] Recon complete! Results saved to $url/recon/"
echo ""
echo "Key files:"
echo "  - Targets: $url/recon/final.txt"
echo "  - Alive hosts: $url/recon/httprobe/alive.txt"
echo "  - Open ports: $url/recon/scans/scanned.nmap"
echo "  - Web vulnerabilities: $url/recon/nikto/"

if [ "$TARGET_TYPE" = "domain" ]; then
    echo "  - Subdomains: $url/recon/final.txt"
    echo "  - Potential takeovers: $url/recon/potential_takeovers/potential_takeovers.txt"
else
    echo "  - Directories: $url/recon/directories/"
fi

