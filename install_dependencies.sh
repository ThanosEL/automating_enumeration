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
  jq \
  wordlists \
  dirbuster

echo "[+] Installing Go-based tools..."
export PATH=$PATH:$HOME/go/bin

echo "[*] Installing assetfinder..."
go install github.com/tomnomnom/assetfinder@latest

echo "[*] Installing httprobe..."
go install github.com/tomnomnom/httprobe@latest

echo "[*] Installing subjack..."
go install github.com/haccer/subjack@latest

echo "[*] Installing gobuster..."
go install github.com/OJ/gobuster/v3@latest

echo "[+] Installing Python-based tools..."

# For Kali Linux and Debian-based systems with Python restrictions
# Try apt first, then pip with --break-system-packages if needed

echo "[*] Installing sublist3r..."
if apt list --installed 2>/dev/null | grep -q "^sublist3r"; then
  echo "sublist3r already installed via apt"
else
  pip3 install --break-system-packages sublist3r 2>/dev/null || apt-get install -y sublist3r 2>/dev/null || true
fi

echo "[*] Installing whatweb..."
if apt list --installed 2>/dev/null | grep -q "^whatweb"; then
  echo "whatweb already installed via apt"
else
  pip3 install --break-system-packages whatweb 2>/dev/null || apt-get install -y whatweb 2>/dev/null || true
fi

echo "[*] Installing amass..."
go install -v github.com/owasp-amass/amass/v3/...@master

echo "[+] Adding Go bin to PATH..."

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
declare -a tools=("assetfinder" "amass" "sublist3r" "httprobe" "whatweb" "nmap" "gobuster")

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
