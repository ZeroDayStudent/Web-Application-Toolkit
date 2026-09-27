#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${GREEN}"
echo "======================================"
echo "        RECONNAISSANCE"
echo "======================================"
echo -e "${NC}"

# Check if target is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <target>${NC}"
    echo "Example: $0 example.com"
    exit 1
fi

TARGET=$1
OUTPUT_DIR="recon_${TARGET}_$(date +%Y%m%d_%H%M%S)"
HTML_REPORT="$OUTPUT_DIR/report.html"
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}[+] Target: $TARGET${NC}"
echo -e "${BLUE}[+] Output directory: $OUTPUT_DIR${NC}"
echo -e "${BLUE}[+] HTML Report: $HTML_REPORT${NC}"
echo ""

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}[-] $1 is not installed${NC}"
        return 1
    fi
    return 0
}

# Function to escape HTML characters
escape_html() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Function to clean WHOIS output
clean_whois() {
    local whois_output="$1"
    
    # Remove common legal text and unwanted sections
    echo "$whois_output" | grep -v -i -E \
        -e "TERMS OF USE" \
        -e "NOTICE:" \
        -e "The data in" \
        -e "By submitting" \
        -e "you agree" \
        -e "compilation, repackaging" \
        -e "For more information" \
        -e "Please note:" \
        -e "Access to" \
        -e ">>>" \
        -e "Copyright" \
        -e "All rights reserved" \
        -e "This service is intended" \
        -e "You may not" \
        -e "The information" \
        -e "This information" \
        -e "Registry database" \
        -e "For details" \
        -e "Refer to" \
        -e "See" \
        -e "More info" \
        -e "Whois Server" \
        -e "Sponsoring Registrar" \
        -e "Domain Name:" | head -30
}

# Function to check target reachability
check_target_reachable() {
    echo -e "${YELLOW}[*] Checking target reachability...${NC}"
    
    # Try ping with short timeout
    if check_command "ping"; then
        if timeout 5 ping -c 2 -W 1 "$TARGET" &> /dev/null; then
            echo -e "${GREEN}[+] Target is reachable via ping${NC}"
            return 0
        fi
    fi
    
    # Try curl for web services
    if check_command "curl"; then
        if timeout 5 curl -s -I "http://$TARGET" &> /dev/null || \
           timeout 5 curl -s -I "https://$TARGET" &> /dev/null; then
            echo -e "${GREEN}[+] Target has web services running${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}[!] Target may be unreachable - continuing with limited scans${NC}"
    return 1
}

# Initialize HTML report
initialize_html() {
    cat > "$HTML_REPORT" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reconnaissance Report - $TARGET</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #2c3e50, #34495e);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .header .subtitle {
            opacity: 0.9;
            font-size: 1.1em;
        }
        .content {
            padding: 30px;
        }
        .section {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 25px;
            margin-bottom: 25px;
            border-left: 4px solid #007cba;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
        }
        .section h2 {
            color: #2c3e50;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .data-box {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin: 10px 0;
            border: 1px solid #e9ecef;
        }
        .clean-data {
            font-family: 'Courier New', monospace;
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            white-space: pre-wrap;
            font-size: 0.9em;
        }
        .status-good {
            color: #28a745;
            font-weight: bold;
        }
        .status-warning {
            color: #ffc107;
            font-weight: bold;
        }
        .status-error {
            color: #dc3545;
            font-weight: bold;
        }
        .tool-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 15px 0;
        }
        .tool-card {
            background: white;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            border: 2px solid #e9ecef;
            transition: transform 0.2s;
        }
        .tool-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
        }
        .tool-available {
            border-color: #28a745;
            background: #f8fff9;
        }
        .tool-missing {
            border-color: #dc3545;
            background: #fff8f8;
        }
        .summary-box {
            background: linear-gradient(135deg, #e3f2fd, #f3e5f5);
            border-radius: 10px;
            padding: 20px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🕵️ Reconnaissance Report</h1>
            <div class="subtitle">
                Target: <strong>$TARGET</strong> | 
                Generated: <strong>$(date)</strong>
            </div>
        </div>
        <div class="content">
EOF
}

# Function to add section to HTML
add_section() {
    local title=$1
    local content=$2
    local icon=$3
    
    cat >> "$HTML_REPORT" << EOF
            <div class="section">
                <h2>$icon $title</h2>
                $content
            </div>
EOF
}

# Initialize HTML report
initialize_html

# 1. Target Status
echo -e "${YELLOW}[1] Checking target status...${NC}"
if check_target_reachable; then
    status_content="<div class='data-box'><p class='status-good'>✅ Target is reachable</p></div>"
else
    status_content="<div class='data-box'><p class='status-warning'>⚠️ Target may be unreachable - some scans may fail</p></div>"
fi
add_section "Target Status" "$status_content" "🎯"

# 2. Tool Availability
echo -e "${YELLOW}[2] Checking tool availability...${NC}"
tools=("whois" "dig" "nslookup" "curl" "nmap" "ping")
tools_html="<div class='tool-grid'>"

for tool in "${tools[@]}"; do
    if check_command "$tool"; then
        tools_html+="<div class='tool-card tool-available'>✅ $tool</div>"
    else
        tools_html+="<div class='tool-card tool-missing'>❌ $tool</div>"
    fi
done

tools_html+="</div>"
add_section "Tool Availability" "$tools_html" "🔧"

# 3. WHOIS Information (Cleaned)
echo -e "${YELLOW}[3] Running WHOIS lookup...${NC}"
if check_command "whois"; then
    whois_raw=$(timeout 10 whois "$TARGET" 2>/dev/null)
    
    if [ -n "$whois_raw" ]; then
        whois_clean=$(clean_whois "$whois_raw")
        
        if [ -n "$whois_clean" ]; then
            whois_content="<div class='data-box'><div class='clean-data'>$(escape_html "$whois_clean")</div></div>"
            echo -e "${GREEN}[+] WHOIS completed (cleaned output)${NC}"
        else
            whois_content="<div class='data-box'><p class='status-warning'>No relevant WHOIS information found</p></div>"
        fi
    else
        whois_content="<div class='data-box'><p class='status-error'>WHOIS lookup failed or timed out</p></div>"
    fi
else
    whois_content="<div class='data-box'><p class='status-error'>WHOIS tool not available</p></div>"
fi
add_section "WHOIS Information" "$whois_content" "📋"

# 4. DNS Information
echo -e "${YELLOW}[4] Running DNS reconnaissance...${NC}"
dns_content=""

# Using nslookup (most reliable)
if check_command "nslookup"; then
    dns_content+="<h3>DNS Records (nslookup)</h3>"
    nslookup_result=$(timeout 10 nslookup "$TARGET" 2>/dev/null)
    if [ -n "$nslookup_result" ]; then
        dns_content+="<div class='data-box'><div class='clean-data'>$(escape_html "$nslookup_result")</div></div>"
    else
        dns_content+="<div class='data-box'><p class='status-warning'>DNS lookup failed</p></div>"
    fi
fi

# Using dig for additional info
if check_command "dig"; then
    dns_content+="<h3>Quick DNS Scan</h3>"
    
    # Get A records
    a_records=$(timeout 10 dig +short "$TARGET" A 2>/dev/null)
    if [ -n "$a_records" ]; then
        dns_content+="<div class='data-box'><strong>A Records:</strong><br><div class='clean-data'>$(escape_html "$a_records")</div></div>"
    fi
    
    # Check if domain exists
    domain_check=$(timeout 10 dig "$TARGET" SOA +short 2>/dev/null)
    if [ -n "$domain_check" ]; then
        dns_content+="<div class='data-box'><p class='status-good'>✅ Domain is registered and has DNS records</p></div>"
    else
        dns_content+="<div class='data-box'><p class='status-warning'>⚠️ No DNS records found - domain may not exist</p></div>"
    fi
fi

add_section "DNS Information" "$dns_content" "🌐"

# 5. HTTP Information
echo -e "${YELLOW}[5] Checking HTTP services...${NC}"
http_content=""

if check_command "curl"; then
    # Test HTTP
    http_test=$(timeout 10 curl -I -s "http://$TARGET" 2>/dev/null | head -10)
    if [ -n "$http_test" ] && [[ ! "$http_test" =~ "Could not resolve host" ]]; then
        http_content+="<h3>HTTP Service (Port 80)</h3>"
        http_content+="<div class='data-box'><div class='clean-data'>$(escape_html "$http_test")</div></div>"
    else
        http_content+="<h3>HTTP Service</h3>"
        http_content+="<div class='data-box'><p class='status-warning'>No HTTP service detected on port 80</p></div>"
    fi
    
    # Test HTTPS
    https_test=$(timeout 10 curl -I -s -k "https://$TARGET" 2>/dev/null | head -10)
    if [ -n "$https_test" ] && [[ ! "$https_test" =~ "Could not resolve host" ]]; then
        http_content+="<h3>HTTPS Service (Port 443)</h3>"
        http_content+="<div class='data-box'><div class='clean-data'>$(escape_html "$https_test")</div></div>"
    else
        http_content+="<h3>HTTPS Service</h3>"
        http_content+="<div class='data-box'><p class='status-warning'>No HTTPS service detected on port 443</p></div>"
    fi
else
    http_content="<div class='data-box'><p class='status-error'>curl not available for HTTP testing</p></div>"
fi

add_section "HTTP Services" "$http_content" "🔗"

# 6. Quick Port Scan (if nmap available and user wants)
echo -e "${YELLOW}[6] Quick port scan...${NC}"
if check_command "nmap"; then
    read -p "Run quick port scan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[-] Running quick nmap scan...${NC}"
        nmap_result=$(timeout 60 nmap -T4 -F "$TARGET" 2>/dev/null)
        if [ -n "$nmap_result" ]; then
            nmap_content="<div class='data-box'><div class='clean-data'>$(escape_html "$nmap_result")</div></div>"
            echo -e "${GREEN}[+] Port scan completed${NC}"
        else
            nmap_content="<div class='data-box'><p class='status-error'>Port scan failed or timed out</p></div>"
        fi
    else
        nmap_content="<div class='data-box'><p class='status-warning'>Port scan skipped by user</p></div>"
    fi
else
    nmap_content="<div class='data-box'><p class='status-warning'>nmap not available for port scanning</p></div>"
fi
add_section "Port Scan" "$nmap_content" "🔍"

# Final Summary
summary_content="<div class='summary-box'>"
summary_content+="<h3>Scan Summary</h3>"
summary_content+="<p><strong>Target:</strong> $TARGET</p>"
summary_content+="<p><strong>Scan Time:</strong> $(date)</p>"
summary_content+="<p><strong>Report Location:</strong> $HTML_REPORT</p>"
summary_content+="<p><strong>Note:</strong> Always ensure proper authorization before scanning targets.</p>"
summary_content+="</div>"

add_section "Summary" "$summary_content" "📊"

# Close HTML
cat >> "$HTML_REPORT" << EOF
        </div>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}"
echo "======================================"
echo "         SCAN COMPLETED"
echo "======================================"
echo -e "${NC}"
echo -e "${GREEN}[+] HTML Report generated: ${HTML_REPORT}${NC}"
echo -e "${GREEN}[+] Open the report with:${NC}"
echo -e "    ${BLUE}xdg-open \"$HTML_REPORT\"${NC}"

# Open report automatically
if command -v xdg-open &> /dev/null; then
    xdg-open "$HTML_REPORT" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$HTML_REPORT" 2>/dev/null &
fi
