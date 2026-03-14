# Automation Enumeration Script

## What It Does

This is a **comprehensive automated reconnaissance (recon) tool** for security professionals and bug bounty hunters. It automates the entire passive and light-active enumeration process for a target **domain or IP address**, collecting and organizing data into a structured directory.

### Key Features:

#### For Domains:
- **Subdomain Enumeration** - Discovers all known subdomains using multiple sources (assetfinder, amass, sublist3r)
- **Host Probing** - Identifies which subdomains are alive and responding
- **Subdomain Takeover Detection** - Detects vulnerable subdomains that could be taken over

#### For IPs:
- **Directory Enumeration** - Brute-forces web directories using gobuster

#### For Both Domains & IPs:
- **Port Scanning** - Maps open ports and services on live hosts (nmap)
- **Technology Detection** - Identifies technologies/frameworks on target (whatweb)

---

## Setup Instructions

### Step 1: On Linux/WSL, Install Dependencies

First, run the dependency installer (only needs to run once):

```bash
cd automating_enumeration
chmod +x install_dependencies.sh
./install_dependencies.sh
```

This will install:
- Go-based tools: assetfinder, amass, httprobe, subjack, gobuster
- Python tools: sublist3r, whatweb
- System tools: nmap, git, jq
- Subjack fingerprints database

### Step 2: Make the Main Script Executable

```bash
chmod +x automating_enumeration.sh
```

---

## How to Run

### Basic Usage - Domain:
```bash
./automating_enumeration.sh example.com
```

### Basic Usage - IP Address:
```bash
./automating_enumeration.sh 192.168.1.10
```
### IP Address with Custom Wordlist:
```bash
./automating_enumeration.sh 192.168.1.10 /path/to/wordlist.txt
```
### What Happens:
1. Detects whether input is a domain or IP address
2. For domains: Runs subdomain enumeration, takeover detection, wayback analysis
3. For IPs: Runs directory enumeration with gobuster, port scanning, technology detection
4. Outputs progress messages for each stage
5. Saves all results to organized subdirectories

### Example Output (Domain):
```
[+] Target type: domain
[+] Harvesting subdomains with assetfinder...
[+] Double checking for subdomains with amass...
[+] Compiling 3rd level domains...
[+] Harvesting subdomains with sublist3r...
[+] Probing for alive domains...
[+] Checking for possible subdomain takeover...
[+] Scanning for directories...
[*] Skipping directory enumeration for domain target
[+] Running whatweb on compiled domains...
[+] Scanning for open ports...
[+] Recon complete!
```

### Example Output (IP):
```
[+] Target type: ip
[+] Processing IP address...
[+] Checking for possible subdomain takeover...
[*] Skipping subdomain takeover check for IP address
[+] Scanning for directories...
[*] Running gobuster on 192.168.1.10...
[+] Running whatweb on compiled domains...
[+] Scanning for open ports...
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
├── whatweb/
│   ├── domain1.com/
│   │   ├── output.txt                 # Technology info
│   │   └── plugins.txt                # Plugin details
│   └── ...
```

### For IP Address Targets:

Results are saved in `<ip>/recon/` with the following structure:

```
192.168.1.10/recon/
├── final.txt                          # The target IP address
├── httprobe/
│   └── alive.txt                      # Target IP (probing result)
├── directories/
│   └── 192.168.1.10.txt               # Gobuster directory scan results
├── scans/
│   ├── scanned.nmap                   # Raw nmap output
│   ├── scanned.gnmap                  # Greppable nmap format
│   └── scanned.xml                    # XML nmap output
├── whatweb/
│   └── 192.168.1.10/
│       ├── output.txt                 # Technology info
│       └── plugins.txt                # Plugin details
```

**Note**: Focused on core enumeration (subdomains for domains, directories for IPs) and port/tech detection.

---

## Requirements

### Tools Installed:
- **assetfinder** - Subdomain enumeration (passive) - *Domains only*
- **amass** - Advanced subdomain enumeration - *Domains only*
- **sublist3r** - Subdomain enumeration (multiple sources) - *Domains only*
- **httprobe** - Host probing (port 80, 443) - *Domains & IPs*
- **subjack** - Subdomain takeover detection - *Domains only*
- **gobuster** - Directory brute-forcing - *IPs only*
- **whatweb** - Web technology identification - *Domains & IPs*
- **nmap** - Port scanning - *Domains & IPs*
- **Go, Python3, Git, jq**

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
| `command not found: assetfinder` | Run `./install_dependencies.sh` first |
| Script exits immediately | Missing required tools; re-run installer |
| nmap permission denied | Make sure nmap is installed; may need `sudo` |
| No subdomain results | Domain may have no public discovery; check domain name |

---

## Tips

- Run on a VPS for faster execution and better stability
- Use a VPN if doing reconnaissance on external targets
- Keep subjack fingerprints updated: `curl -s https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json -o $HOME/go/src/github.com/haccer/subjack/fingerprints.json`

---

## Wordlists for Directory Enumeration

The script auto-detects wordlists on Kali Linux:
- Primary: `/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt` (installed via `dirbuster` package)
- Fallback: `/usr/share/wordlists/dirb/common.txt` (installed via `wordlists` package)

**To provide a custom wordlist:**
```bash
./automating_enumeration.sh 192.168.1.10 /path/to/custom-wordlist.txt
```

**Popular wordlists:**
- SecLists: `https://github.com/danielmiessler/SecLists` (recommended)
- Dirbuster default: `/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt`
- Common paths: `/usr/share/wordlists/dirb/common.txt`

---

## Quick Start (TL;DR)

```bash
# First time only:
./install_dependencies.sh

# Enumerate a domain:
./automating_enumeration.sh example.com
# Results in: example.com/recon/

# Enumerate an IP:
./automating_enumeration.sh 192.168.1.10
# Results in: 192.168.1.10/recon/

# Enumerate an IP with custom wordlist:
./automating_enumeration.sh 192.168.1.10 /path/to/wordlist.txt
```
