#!/bin/bash
# install_dependencies.sh - Install all dependencies for automating_enumeration.sh
# Run this first before using the main script

set -euo pipefail

echo "[+] Updating package manager..."
sudo apt-get update -y

echo "[+] Installing system packages..."
sudo apt-get install -y \
  python3 \
  python3-pip \
  golang-go \
  git \
  nmap \
  curl \
  wget \
  jq

echo "[+] Installing Go-based tools..."
export PATH=$PATH:$HOME/go/bin

echo "[*] Installing assetfinder..."
go install github.com/tomnomnom/assetfinder@latest

echo "[*] Installing httprobe..."
go install github.com/tomnomnom/httprobe@latest

echo "[*] Installing waybackurls..."
go install github.com/tomnomnom/waybackurls@latest

echo "[*] Installing subjack..."
go install github.com/haccer/subjack@latest

echo "[+] Installing Python-based tools..."

echo "[*] Installing sublist3r..."
pip3 install sublist3r

echo "[*] Installing whatweb..."
pip3 install whatweb

echo "[*] Installing amass..."
go install -v github.com/owasp-amass/amass/v3/...@master

echo "[*] Installing EyeWitness..."
git clone https://github.com/FortyNorthSecurity/EyeWitness.git $HOME/EyeWitness || true
cd $HOME/EyeWitness && pip3 install -r requirements.txt || true

echo "[+] Adding Go bin to PATH..."
if ! grep -q 'export PATH=\$PATH:\$HOME/go/bin' ~/.bashrc; then
  echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
fi

echo "[+] Setting up subjack fingerprints..."
mkdir -p $HOME/go/src/github.com/haccer/subjack
if [ ! -f "$HOME/go/src/github.com/haccer/subjack/fingerprints.json" ]; then
  curl -s 'https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json' \
    -o $HOME/go/src/github.com/haccer/subjack/fingerprints.json
fi

echo "[+] Verifying installations..."
export PATH=$PATH:$HOME/go/bin
echo ""

missing_tools=0
declare -a tools=("assetfinder" "amass" "sublist3r" "httprobe" "waybackurls" "whatweb" "nmap")

for tool in "${tools[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "✓ $tool installed"
  else
    echo "✗ $tool NOT found"
    ((missing_tools++))
  fi
done

echo ""

if [ $missing_tools -eq 0 ]; then
  echo "[+] All dependencies installed successfully!"
  echo "[+] To use the main script, run: ./automating_enumeration.sh <domain>"
  echo "[+] Example: ./automating_enumeration.sh example.com"
  exit 0
else
  echo "[-] $missing_tools tool(s) missing. Please check installation errors above."
  exit 1
fi
