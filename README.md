# 🛡️ Web Application Toolkit

A modular **Bash-based penetration testing framework** built for web developers, cybersecurity learners, and security analysts to automate reconnaissance, vulnerability scanning, exploitation, and post-exploitation reporting — all from one simple menu-driven interface.

---

## 📖 Overview

The Web Application Toolkit consolidates multiple web-related security tasks into a single automation suite, eliminating the need to juggle many separate command-line tools. It follows a structured four-phase methodology aligned with industry standards (OWASP, NIST, PTES):

**Reconnaissance → Vulnerability Scanning → Exploitation → Post-Exploitation**

All outputs — logs, HTML reports, and scan results — are automatically organized into timestamped folders for easy review.

---

## ✨ Features

- **Automation** – Runs full testing phases with a single command, minimal manual effort
- **Centralized Framework** – Integrates tools like Nmap, Nikto, Dirbuster, and SQLMap under one controller
- **Standardized HTML Reporting** – Clean, styled reports generated automatically after each scan
- **Modular Design** – Each module (`recon`, `vulnscan`, `exploit`, `postexploit`) can run independently
- **Logging** – Every run is logged with timestamps for auditability
- **Ethical & Educational Focus** – Encourages authorized, responsible testing only

---

## 🧩 Modules

| Module | Description |
|---|---|
| `recon.sh` | WHOIS/DNS enumeration, port scanning, HTTP service detection |
| `vulnscan.sh` | Security header checks, SSL/TLS config, HTTP method testing, info disclosure |
| `exploit.sh` | Controlled exploitation / proof-of-concept verification |
| `postexploit.sh` | System audit — SUID files, password policy, firewall, updates |
| `webkit.sh` | Main controller menu that ties all modules together |

---

## ⚙️ Requirements

**Hardware**
- CPU: Intel i5 or equivalent
- RAM: 8 GB
- Disk: 500 GB – 1 TB (SSD preferred)

**Software**
- OS: Kali Linux (latest)
- Shell: Bash
- Browser: Firefox (for viewing HTML reports)

---

## 🚀 Usage

```bash
sudo webkit <target-domain>
```

Example:
```bash
sudo webkit example.com
```

You'll get a menu:
```
1. Reconnaissance
2. Vulnerability Scanning
3. Exploitation
4. Post-Exploitation
5. Exit
```

Reports are auto-generated as HTML and opened in your default browser.

---

## 📸 Screenshots

> Add your screenshots here — create a `screenshots/` folder in the repo and reference them like below:

```markdown
![Main Menu](screenshots/main_menu.png)
![Reconnaissance Report](screenshots/recon_report.png)
![Vulnerability Scan Report](screenshots/vuln_scan_report.png)
![Exploitation Report](screenshots/exploit_report.png)
![Post-Exploitation Report](screenshots/postexploit_report.png)
```

---

## ⚠️ Legal & Ethical Notice

This toolkit is intended **strictly for authorized security testing and educational purposes**.
- Only test systems you own or have explicit written permission to test.
- Unauthorized use against systems you do not own is illegal.
- Follow responsible disclosure practices for any vulnerabilities found.

---

## 🔮 Future Enhancements

- Cross-platform support (PowerShell for Windows)
- AI-assisted vulnerability prioritization
- GUI / web-based dashboard
- Advanced exploitation modules and payload generation
- Analytics dashboard for report trends

---

## 📚 References

- OWASP Testing Guide v5
- NIST Cybersecurity Framework
- PTES (Penetration Testing Execution Standard)
- Nmap Official Documentation
- Nikto Web Scanner Documentation

---

## 📄 License

Add your preferred license here (e.g., MIT, GPL-3.0).
