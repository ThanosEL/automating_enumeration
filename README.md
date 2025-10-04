# Recon Automation Script

## Purpose
This Bash script automates passive and light active reconnaissance steps for a single target domain. It aggregates subdomain enumeration, alive-host probing, takeover detection, port scanning and archived-URL collection into a structured output directory.

## Tools required
- assetfinder
- httprobe
- subjack (+ fingerprints.json recommended)
- nmap
- waybackurls
- standard Unix utilities (sed, grep, sort, awk)

## Quickstart
1. Ensure dependencies are installed and available in PATH.
2. Make the script executable: `chmod +x recon-script.sh`
3. Run: `./recon-script.sh <domain>`

## Outputs
Results live under `<domain>/recon/`. Key files: `final.txt`, `httprobe/alive.txt`, `scans/scanned.*`, `potential_takeovers/potential_takeovers.txt`, `wayback/wayback_output.txt` and categorized extension files.

## Legal / Safety
**Only run on assets you own or have explicit permission to test.** Unauthorized scanning or probing is illegal. Use caution with port scanning and large-scale enumeration.

## Maintenance notes
- Keep `subjack` fingerprints updated.
- Consider adding `amass` for comprehensive enumeration.
- Add logging and resume capabilities for production use.

## Contact / author
This repository is private. Maintain strict access control and do not expose raw outputs containing confidential data.
