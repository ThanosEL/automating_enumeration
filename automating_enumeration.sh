#!/bin/bash

url=$1

# Check for required tools
if [ ! -x "$(command -v assetfinder)" ]; then
    echo "[-] assetfinder required to run script"
    exit 1
fi

if [ ! -x "$(command -v amass)" ]; then
    echo "[-] amass required to run script"
    exit 1
fi

if [ ! -x "$(command -v sublist3r)" ]; then
    echo "[-] sublist3r required to run script"
    exit 1
fi

if [ ! -x "$(command -v httprobe)" ]; then
    echo "[-] httprobe required to run script"
    exit 1
fi

if [ ! -x "$(command -v waybackurls)" ]; then
    echo "[-] waybackurls required to run script"
    exit 1
fi

if [ ! -x "$(command -v whatweb)" ]; then
    echo "[-] whatweb required to run script"
    exit 1
fi

if [ ! -x "$(command -v nmap)" ]; then
    echo "[-] nmap required to run script"
    exit 1
fi

# Create directory structure
if [ ! -d "$url" ]; then
    mkdir $url
fi
if [ ! -d "$url/recon" ]; then
    mkdir $url/recon
fi
if [ ! -d "$url/recon/3rd-lvls" ]; then
    mkdir $url/recon/3rd-lvls
fi
if [ ! -d "$url/recon/scans" ]; then
    mkdir $url/recon/scans
fi
if [ ! -d "$url/recon/httprobe" ]; then
    mkdir $url/recon/httprobe
fi
if [ ! -d "$url/recon/potential_takeovers" ]; then
    mkdir $url/recon/potential_takeovers
fi
if [ ! -d "$url/recon/wayback" ]; then
    mkdir $url/recon/wayback
fi
if [ ! -d "$url/recon/wayback/params" ]; then
    mkdir $url/recon/wayback/params
fi
if [ ! -d "$url/recon/wayback/extensions" ]; then
    mkdir $url/recon/wayback/extensions
fi
if [ ! -d "$url/recon/whatweb" ]; then
    mkdir $url/recon/whatweb
fi
if [ ! -d "$url/recon/eyewitness" ]; then
    mkdir $url/recon/eyewitness
fi

# Initialize output files
if [ ! -f "$url/recon/httprobe/alive.txt" ]; then
    touch $url/recon/httprobe/alive.txt
fi
if [ ! -f "$url/recon/final.txt" ]; then
    touch $url/recon/final.txt
fi
if [ ! -f "$url/recon/3rd-lvl-domains.txt" ]; then
    touch $url/recon/3rd-lvl-domains.txt
fi

echo "[+] Harvesting subdomains with assetfinder..."
assetfinder $url | grep ".$url" | sort -u | tee -a $url/recon/final1.txt

echo "[+] Double checking for subdomains with amass..."
amass enum -d $url | tee -a $url/recon/final1.txt

sort -u $url/recon/final1.txt >> $url/recon/final.txt
rm -f $url/recon/final1.txt

echo "[+] Compiling 3rd level domains..."
cat $url/recon/final.txt | grep -Po '(\w+\.\w+\.\w+)$' | sort -u >> $url/recon/3rd-lvl-domains.txt

# Add 3rd level domains to final list
for line in $(cat $url/recon/3rd-lvl-domains.txt); do
    echo $line | sort -u | tee -a $url/recon/final.txt
done

echo "[+] Harvesting subdomains with sublist3r..."
for domain in $(cat $url/recon/3rd-lvl-domains.txt); do
    sublist3r -d $domain -o $url/recon/3rd-lvls/$domain.txt 2>/dev/null || true
done

echo "[+] Probing for alive domains..."
cat $url/recon/final.txt | sort -u | httprobe -s -p https:443 | sed 's/https\?:\/\///' | tr -d ':443' | sort -u >> $url/recon/httprobe/alive.txt

echo "[+] Checking for possible subdomain takeover..."
if [ ! -f "$url/recon/potential_takeovers/domains.txt" ]; then
    touch $url/recon/potential_takeovers/domains.txt
fi
if [ ! -f "$url/recon/potential_takeovers/potential_takeovers.txt" ]; then
    touch $url/recon/potential_takeovers/potential_takeovers.txt
fi

for line in $(cat $url/recon/final.txt); do
    echo $line | sort -u >> $url/recon/potential_takeovers/domains.txt
done

fp="$HOME/go/src/github.com/haccer/subjack/fingerprints.json"
if [ -f "$fp" ]; then
    subjack -w $url/recon/httprobe/alive.txt -t 100 -timeout 30 -ssl -c $fp -v 3 >> $url/recon/potential_takeovers/potential_takeovers.txt 2>/dev/null || true
else
    echo "[-] subjack fingerprints.json not found, running without fingerprints..."
    subjack -w $url/recon/httprobe/alive.txt -t 100 -timeout 30 -ssl -v 3 >> $url/recon/potential_takeovers/potential_takeovers.txt 2>/dev/null || true
fi

echo "[+] Running whatweb on compiled domains..."
for domain in $(cat $url/recon/httprobe/alive.txt); do
    if [ ! -d "$url/recon/whatweb/$domain" ]; then
        mkdir -p $url/recon/whatweb/$domain
    fi
    if [ ! -f "$url/recon/whatweb/$domain/output.txt" ]; then
        touch $url/recon/whatweb/$domain/output.txt
    fi
    if [ ! -f "$url/recon/whatweb/$domain/plugins.txt" ]; then
        touch $url/recon/whatweb/$domain/plugins.txt
    fi
    echo "[*] Pulling plugins data on $domain $(date +'%Y-%m-%d %T')"
    whatweb --info-plugins -t 50 $domain >> $url/recon/whatweb/$domain/plugins.txt 2>/dev/null || true
    sleep 2
    echo "[*] Running whatweb on $domain $(date +'%Y-%m-%d %T')"
    whatweb -t 50 $domain >> $url/recon/whatweb/$domain/output.txt 2>/dev/null || true
    sleep 2
done

echo "[+] Scraping wayback data..."
cat $url/recon/final.txt | waybackurls | tee -a $url/recon/wayback/wayback_output1.txt
sort -u $url/recon/wayback/wayback_output1.txt >> $url/recon/wayback/wayback_output.txt
rm -f $url/recon/wayback/wayback_output1.txt

echo "[+] Pulling and compiling all possible params found in wayback data..."
cat $url/recon/wayback/wayback_output.txt | grep '\?.*=' | cut -d '=' -f 1 | sort -u >> $url/recon/wayback/params/wayback_params.txt
for line in $(cat $url/recon/wayback/params/wayback_params.txt); do
    echo $line'='
done > $url/recon/wayback/params/wayback_params_equals.txt

echo "[+] Pulling and compiling js/php/aspx/jsp/json files from wayback output..."
for line in $(cat $url/recon/wayback/wayback_output.txt); do
    ext="${line##*.}"
    if [[ "$ext" == "js" ]]; then
        echo $line | sort -u | tee -a $url/recon/wayback/extensions/js.txt
    fi
    if [[ "$ext" == "html" ]]; then
        echo $line | sort -u | tee -a $url/recon/wayback/extensions/html.txt
    fi
    if [[ "$ext" == "json" ]]; then
        echo $line | sort -u | tee -a $url/recon/wayback/extensions/json.txt
    fi
    if [[ "$ext" == "php" ]]; then
        echo $line | sort -u | tee -a $url/recon/wayback/extensions/php.txt
    fi
    if [[ "$ext" == "aspx" ]]; then
        echo $line | sort -u | tee -a $url/recon/wayback/extensions/aspx.txt
    fi
done

echo "[+] Sorting and deduplicating all extension files..."
for file in $url/recon/wayback/extensions/*.txt; do
    sort -u "$file" -o "$file"
done

echo "[+] Scanning for open ports..."
nmap -iL $url/recon/httprobe/alive.txt -T4 -oA $url/recon/scans/scanned 2>/dev/null || true

echo "[+] Checking for EyeWitness..."
if command -v eyewitness >/dev/null 2>&1; then
    echo "[+] Running EyeWitness against all compiled domains..."
    eyewitness --web -f $url/recon/httprobe/alive.txt -d $url/recon/eyewitness --resolve --no-prompt 2>/dev/null || true
else
    echo "[-] EyeWitness not found. Skipping screenshots."
fi

echo "[+] Recon complete! Results saved to $url/recon/"
echo ""
echo "Key files:"
echo "  - Subdomains: $url/recon/final.txt"
echo "  - Alive hosts: $url/recon/httprobe/alive.txt"
echo "  - Potential takeovers: $url/recon/potential_takeovers/potential_takeovers.txt"
echo "  - Open ports: $url/recon/scans/scanned.nmap"
echo "  - Wayback URLs: $url/recon/wayback/wayback_output.txt"
echo "  - Web tech: $url/recon/whatweb/"
echo "  - Screenshots: $url/recon/eyewitness/"

