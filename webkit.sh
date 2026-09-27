#!/usr/bin/env bash
# Web Application Toolkit v1.2 - main menu launcher (All-in-One removed)
# Usage: sudo ./webkit <target-domain>

set -o errexit
set -o pipefail
set -o nounset

# --- Colors ---
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[1;33m"
BOLD="\e[1m"
UNDERLINE="\e[4m"
NC="\e[0m" # No Color

# Simple domain validator
valid_domain() {
    [[ $1 =~ ^(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})$ ]]
}

# Check args
if [ $# -lt 1 ]; then
    echo -e "${RED}[!] No target specified.${NC}"
    echo -e "Usage: ${YELLOW}$0 <target-domain>${NC}"
    exit 1
fi

if ! valid_domain "$1"; then
    echo -e "${RED}[!] Invalid domain format: $1${NC}"
    exit 1
fi
TARGET="$1"

# Setup logs
BASE_LOGDIR="/home/kali/webkit/logs"
RUN_TS=$(date +%Y%m%d-%H%M%S)
LOGDIR="$BASE_LOGDIR/$TARGET-$RUN_TS"
mkdir -p "$LOGDIR"

# --- Utility: run module ---
run_module() {
    local path="$1"
    local name="$2"
    if [ ! -f "$path" ]; then
        echo -e "${RED}[!] Missing module: $path${NC}"
        return 1
    fi
    echo -e "${GREEN}==> Running $name${NC}"
    bash "$path" "$TARGET" | tee -a "$LOGDIR/${name}.log"
    echo ""
}

# --- Menu ---
while true; do

    echo -e "${YELLOW}======================================${NC}"
    echo -e "${BOLD} Web Application Toolkit v1.2 ${NC}"
    echo -e "${YELLOW}======================================${NC}"
    echo ""
    echo -e "${BOLD}Target domain:${NC} ${GREEN}$TARGET${NC}"
    echo ""
    echo "1. Reconnaissance"
    echo "2. Vulnerability Scanning"
    echo "3. Exploitation"
    echo "4. Post-Exploitation"
    echo "5. Exit"
    echo ""

    read -rp "Select an option (1-5) for $TARGET: " choice
    echo ""

    case "$choice" in
        1)
            run_module "/home/kali/webkit/modules/recon.sh" "Reconnaissance"
            ;;
        2)
            run_module "/home/kali/webkit/modules/vulnscan.sh" "Vulnerability Scan"
            ;;
        3)
            read -rp "Proceed with exploitation? (y/n): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_module "/home/kali/webkit/modules/exploit.sh" "Exploitation"
            else
                echo -e "${YELLOW}Skipping exploitation.${NC}"
            fi
            ;;
        4)
            read -rp "Proceed with post-exploitation? (y/n): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                run_module "/home/kali/webkit/modules/postexploit.sh" "Post-Exploitation"
            else
                echo -e "${YELLOW}Skipping post-exploitation.${NC}"
            fi
            ;;
        5)
            echo -e "${GREEN}Thank you for using Web Application Toolkit. Stay safe!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please enter a number between 1 and 5.${NC}"
            ;;
    esac

    echo ""
    read -rp "Press Enter to continue..." dummy
done
