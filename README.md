# Automation Enumeration Script

## What It Does

This is a **comprehensive automated reconnaissance (recon) tool** for security professionals and bug bounty hunters. It automates the entire passive and light-active enumeration process for a target domain, collecting and organizing data into a structured directory.

### Key Features:
- **Subdomain Enumeration** - Discovers all known subdomains using multiple sources (assetfinder, amass, sublist3r)
- **Host Probing** - Identifies which subdomains are alive and responding
- **Subdomain Takeover Detection** - Detects vulnerable subdomains that could be taken over
- **Port Scanning** - Maps open ports and services on live hosts (nmap)
- **Wayback Archive Mining** - Collects historical URLs from Internet Archive
- **Parameter Extraction** - Extracts URL parameters for testing
- **File Type Categorization** - Separates discovery into file types (.js, .php, .json, .aspx, .html)
- **Technology Detection** - Identifies technologies/frameworks on target (whatweb)
- **Screenshots** - Captures screenshots of all discovered domains (EyeWitness)

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
- Go-based tools: assetfinder, amass, httprobe, waybackurls, subjack
- Python tools: sublist3r, whatweb, EyeWitness
- System tools: nmap, git, jq
- Subjack fingerprints database

### Step 2: Make the Main Script Executable

```bash
chmod +x automating_enumeration.sh
```

---

## How to Run

### Basic Usage:
```bash
./automating_enumeration.sh example.com
```

### What Happens:
1. Creates `example.com/recon/` directory structure
2. Runs all enumeration and scanning modules
3. Outputs progress messages for each stage
4. Saves all results to organized subdirectories

### Example Output:
```
[+] Harvesting subdomains with assetfinder...
[+] Double checking for subdomains with amass...
[+] Compiling 3rd level domains...
[+] Harvesting subdomains with sublist3r...
[+] Probing for alive domains...
[+] Checking for possible subdomain takeover...
[+] Running whatweb on compiled domains...
[+] Scraping wayback data...
[+] Pulling and compiling all possible params...
[+] Pulling and compiling js/php/aspx/jsp/json files...
[+] Scanning for open ports...
[+] Running EyeWitness...
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
├── wayback/
│   ├── wayback_output.txt             # All archived URLs
│   ├── params/
│   │   ├── wayback_params.txt         # URL parameters found
│   │   └── wayback_params_equals.txt  # Parameters with = sign
│   └── extensions/
│       ├── js.txt                     # JavaScript files
│       ├── php.txt                    # PHP files
│       ├── json.txt                   # JSON files
│       ├── aspx.txt                   # ASPX files
│       └── html.txt                   # HTML files
└── eyewitness/                        # Screenshots of all domains
    └── report.html
```

---

## Requirements

### Tools Installed:
- **assetfinder** - Subdomain enumeration (passive)
- **amass** - Advanced subdomain enumeration
- **sublist3r** - Subdomain enumeration (multiple sources)
- **httprobe** - Host probing (port 80, 443)
- **waybackurls** - URL collection from Wayback Machine
- **subjack** - Subdomain takeover detection
- **whatweb** - Web technology identification
- **nmap** - Port scanning
- **EyeWitness** - Screenshot automation
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
| EyeWitness not found | Optional feature; script will skip if missing |
| No subdomain results | Domain may have no public discovery; check domain name |

---

## Tips

- Run on a VPS for faster execution and better stability
- Consider running overnight for large-scale targets
- Use a VPN if doing reconnaissance on external targets
- Results can be very large; use grep/awk to filter data
- Keep subjack fingerprints updated: `curl -s https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json -o $HOME/go/src/github.com/haccer/subjack/fingerprints.json`

---

## Quick Start (TL;DR)

```bash
# First time only:
./install_dependencies.sh

# Every time:
./automating_enumeration.sh example.com

# Results in: example.com/recon/
```
