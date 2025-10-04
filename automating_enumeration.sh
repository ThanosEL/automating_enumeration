#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  echo "Usage: $0 <domain>"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

url="$1"
base_dir="$url/recon"

for cmd in assetfinder httprobe subjack nmap waybackurls sort sed awk; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[-] Required command '$cmd' not found. Install it first." >&2
    exit 2
  fi
done

mkdir -p "$base_dir/httprobe" \
         "$base_dir/scans" \
         "$base_dir/potential_takeovers" \
         "$base_dir/wayback/params" \
         "$base_dir/wayback/extensions"

: > "$base_dir/httprobe/alive.txt"
: > "$base_dir/final.txt"

echo "[+] Harvesting subdomains with assetfinder..."
assetfinder "$url" | sort -u > "$base_dir/assets_raw.txt"
grep -i "$url" "$base_dir/assets_raw.txt" | sort -u >> "$base_dir/final.txt"
rm -f "$base_dir/assets_raw.txt"

echo "[+] Probing for alive domains..."
sort -u "$base_dir/final.txt" | httprobe -s -p https:443 \
  | sed -E 's#https?://##' | sed -E 's/:443$//' \
  > "$base_dir/httprobe/alive.tmp"

sort -u "$base_dir/httprobe/alive.tmp" > "$base_dir/httprobe/alive.txt"
rm -f "$base_dir/httprobe/alive.tmp"

echo "[+] Checking for possible subdomain takeover..."
ptake_file="$base_dir/potential_takeovers/potential_takeovers.txt"
: > "$ptake_file"

fp="$HOME/go/src/github.com/haccer/subjack/fingerprints.json"
if [ ! -f "$fp" ]; then
  echo "[-] subjack fingerprint file not found at $fp. Running without -c may still work."
  subjack -w "$base_dir/final.txt" -t 100 -timeout 30 -ssl -v 3 -o "$ptake_file" || true
else
  subjack -w "$base_dir/final.txt" -t 100 -timeout 30 -ssl -c "$fp" -v 3 -o "$ptake_file" || true
fi

echo "[+] Scanning for open ports with nmap..."
nmap -iL "$base_dir/httprobe/alive.txt" -T4 -oA "$base_dir/scans/scanned" || true

echo "[+] Scraping wayback data..."
sort -u "$base_dir/final.txt" | while IFS= read -r host; do
  waybackurls "$host"
done > "$base_dir/wayback/wayback_output.txt"

sort -u "$base_dir/wayback/wayback_output.txt" -o "$base_dir/wayback/wayback_output.txt"

echo "[+] Pulling and compiling all possible params found in wayback data..."
grep -E '\?.+=' "$base_dir/wayback/wayback_output.txt" \
  | sed -E 's/=.*//' \
  | sort -u > "$base_dir/wayback/params/wayback_params.txt"

while IFS= read -r p; do
  printf '%s=\n' "$p"
done < "$base_dir/wayback/params/wayback_params.txt" > "$base_dir/wayback/params/wayback_params_equals.txt"

echo "[+] Pulling and compiling js/php/html/json/aspx files from wayback output..."
> "$base_dir/wayback/extensions/js.txt"
> "$base_dir/wayback/extensions/jsp.txt"
> "$b

