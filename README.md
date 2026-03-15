# Automation Enumeration Script

## What It Does

This is a **comprehensive automated reconnaissance (recon) tool** for security professionals and bug bounty hunters. It automates the entire passive and light-active enumeration process for a target **domain or IP address**, collecting and organizing data into a structured directory.

### Key Features:

#### For Domains:
- **Subdomain Enumeration** - Discovers all known subdomains (assetfinder, amass, sublist3r)
- **Host Probing** - Identifies which subdomains are alive
- **Subdomain Takeover Detection** - Finds vulnerable subdomains

#### For IPs:
- **Port Scanning & Service Detection** - nmap with version detection (-sV), OS detection (-O), and default scripts (-sC)

#### For Both Domains & IPs (only if ports 80/443 open):
- **Directory Enumeration** - Brute-forces web directories using feroxbuster with 2-level recursion
- **Web Vulnerability Scanning** - nikto scans for web vulnerabilities

---

## Setup Instructions

### Step 1: On Linux/WSL, Install Dependencies

First, run the dependency installer (only needs to run once):

```bash
cd automating_enumeration
chmod +x install_dependencies.sh
./install_dependencies.sh
```

### Step 2: Update PATH (Important!)

After installation completes, update your shell's PATH to include Go tools:

```bash
source ~/.bashrc
```

This adds `$HOME/go/bin` to your PATH so the script can find all tools.

### Step 3: Make the Main Script Executable

```bash
chmod +x automating_enumeration.sh
```

---

## What Gets Installed

The installer (`install_dependencies.sh`) will install:

**Go Tools:**
- assetfinder - Subdomain enumeration
- amass - Advanced subdomain discovery
- httprobe - Host probing
- subjack - Subdomain takeover detection

**Rust Tools:**
- feroxbuster - Directory brute-forcing with recursive scanning

**System Packages:**
- nmap - Port scanning
- nikto - Web vulnerability scanner
- seclists - Wordlists for feroxbuster (web content discovery)
- git, curl, wget, jq, build-essential

---

## How to Run

### First Time Setup:
```bash
./install_dependencies.sh
source ~/.bashrc
```

### Basic Usage - Domain:
```bash
./automating_enumeration.sh example.com
```

### Basic Usage - IP Address:
```bash
./automating_enumeration.sh 192.168.1.10
```

### What Happens:
1. Detects whether input is a domain or IP address
2. For domains: Runs subdomain enumeration and takeover detection
3. Performs comprehensive port scanning with service/OS detection using nmap
4. If ports 80/443 are open: Runs feroxbuster for directory enumeration and nikto for web vulnerabilities
5. Outputs progress messages for each stage
6. Saves all results to organized subdirectories

### Example Output (Domain):
```
[+] Target type: domain
[+] Harvesting subdomains with assetfinder...
[+] Double checking with amass...
[+] Compiling 3rd level domains...
[+] Harvesting subdomains with sublist3r...
[+] Probing for alive domains...
[+] Checking for possible subdomain takeover...
[+] Scanning for directories...
[*] Skipping directory enumeration for domain target
[+] Scanning for open ports...
[+] Scanning for web vulnerabilities with nikto...
[*] Running nikto on example.com...
[+] Recon complete!
```

### Example Output (IP):
```
[+] Target type: ip
[+] Processing IP address...
[+] Checking for possible subdomain takeover...
[*] Skipping subdomain takeover check for IP address
[+] Scanning for directories...
[*] Running feroxbuster on 192.168.1.10 with 2-level recursion...
[+] Scanning for open ports...
[+] Scanning for web vulnerabilities with nikto...
[*] Running nikto on 192.168.1.10...
[+] Recon complete!
```

---

## Output Structure

Results are saved in `<domain>/recon/` with the following structure:

```
example.com/recon/
├── final.txt                          # All discovered subdomains
├── 3rd-lvl-domains.txt                # Third-level domains
├── 3rd-lvls/                          # Sublist3r results per domain
│   ├── sub.example.com.txt
│   └── ...
├── httprobe/
│   └── alive.txt                      # Verified live hosts
├── potential_takeovers/
│   ├── domains.txt                    # Domains checked
│   └── potential_takeovers.txt        # Vulnerable takeover targets
├── scans/
│   ├── scanned.nmap                   # Raw nmap output
│   ├── scanned.gnmap                  # Greppable nmap format
│   └── scanned.xml                    # XML nmap output
└── nikto/                             # Web vulnerability scan results

### For IP Address Targets:

Results are saved in `<ip>/recon/` with the following structure:

```
192.168.1.10/recon/
├── final.txt                          # The target IP address
├── httprobe/
│   └── alive.txt                      # Target IP (probing result)
├── directories/
│   └── 192.168.1.10.html               # Feroxbuster directory scan report
├── scans/
│   ├── scanned.nmap                   # Raw nmap output
│   ├── scanned.gnmap                  # Greppable nmap format
│   └── scanned.xml                    # XML nmap output
└── nikto/                             # Web vulnerability scan results (if ports 80/443 open)

**Note**: Nikto scanning runs automatically on targets with ports 80 or 443 open. Results are saved as HTML reports in the nikto/ directory.

---

## Requirements

### Tools Installed:
- **assetfinder** - Subdomain enumeration (passive) - *Domains only*
- **amass** - Advanced subdomain enumeration - *Domains only*
- **sublist3r** - Subdomain enumeration (multiple sources) - *Domains only*
- **httprobe** - Host probing (port 80, 443) - *Domains & IPs*
- **subjack** - Subdomain takeover detection - *Domains only*
- **nmap** - Port scanning with service/OS detection - *Domains & IPs*
- **feroxbuster** - Directory brute-forcing with recursion - *Domains & IPs (only if ports 80/443 open)*
- **nikto** - Web vulnerability scanning - *Domains & IPs (only if ports 80/443 open)*
- **Rust toolchain, Go, Python3, Git, jq**

### System Requirements:
- **OS:** Linux, macOS, or Windows (WSL2/Git Bash)
- **RAM:** 2GB minimum (4GB+ recommended)
- **Disk Space:** 500MB+ (varies by target)
- **Network:** Active internet connection

---

## Legal / Safety Warning

⚠️ **IMPORTANT: Only run this script on domains/assets you own or have explicit written permission to test.**

- Unauthorized port scanning, domain enumeration, and network probing is **illegal**.
- Only use on systems you have permission to test.
- Respect privacy and legal regulations in your jurisdiction.
- Do not expose raw outputs containing confidential data.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `command not found: httprobe` | Run `source ~/.bashrc` after installation |
| `command not found: assetfinder` | PATH not updated; run `source ~/.bashrc` |
| Script exits immediately | Missing required tools; re-run installer |
| nmap permission denied | Make sure nmap is installed; may need `sudo` |
| No subdomain results | Domain may have no public discovery; check domain name |

**If tools still not found after `source ~/.bashrc`:**
```bash
export PATH=$PATH:$HOME/go/bin
```

---

## Tips

- Run on a VPS for faster execution and better stability
- Use a VPN if doing reconnaissance on external targets
- Keep subjack fingerprints updated: `curl -s https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json -o $HOME/go/src/github.com/haccer/subjack/fingerprints.json`

---

## Directory Scanning with Feroxbuster

**Feroxbuster Features:**
- **Built-in Wordlists** - Uses default SecLists wordlists automatically
- **Redirect Following** - Follows HTTP redirects with `-r` flag
- **2-Level Recursion** - Automatically scans subdirectories (uses `--depth 2`)
- **HTML Reports** - Generates detailed reports for easy review
- **Fast Scanning** - Written in Rust for optimal performance

The script automatically:
- Detects web servers on IPs (via nmap port detection)
- Initiates recursive directory brute-forcing with built-in wordlists
- Follows redirects during scanning
- Generates detailed HTML reports per target
- No manual wordlist configuration needed

---

## Quick Start (TL;DR)

```bash
# First time only (includes Rust toolchain installation):
./install_dependencies.sh
source ~/.bashrc
source ~/.cargo/env

# Enumerate a domain:
./automating_enumeration.sh example.com
# Results in: example.com/recon/

# Enumerate an IP:
./automating_enumeration.sh 192.168.1.10
# Results in: 192.168.1.10/recon/
```
