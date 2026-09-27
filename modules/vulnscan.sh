#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${GREEN}"
cat << "EOF"
EOF
echo -e "${NC}"

# Check if target is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Usage: $0 <target> [options]${NC}"
    echo "Examples:"
    echo "  $0 example.com"
    echo "  $0 192.168.1.1"
    echo "  $0 https://example.com --full-scan"
    exit 1
fi

TARGET=$1
FULL_SCAN=false

# Parse options
if [[ "$2" == "--full-scan" ]] || [[ "$3" == "--full-scan" ]]; then
    FULL_SCAN=true
fi

OUTPUT_DIR="vuln_scan_${TARGET}_$(date +%Y%m%d_%H%M%S)"
HTML_REPORT="$OUTPUT_DIR/vulnerability_report.html"
mkdir -p "$OUTPUT_DIR"

echo -e "${BLUE}[+] Target: $TARGET${NC}"
echo -e "${BLUE}[+] Output directory: $OUTPUT_DIR${NC}"
echo -e "${BLUE}[+] HTML Report: $HTML_REPORT${NC}"
echo -e "${BLUE}[+] Full Scan: $FULL_SCAN${NC}"
echo ""

# Vulnerability database (common vulnerabilities)
declare -A VULN_DB=(
    ["http-trace-enabled"]="TRACE method enabled - can be used for XST attacks"
    ["http-options-enabled"]="OPTIONS method enabled - may reveal server information"
    ["insecure-cookies"]="Cookies without secure flag"
    ["missing-security-headers"]="Missing security headers"
    ["exposed-version-info"]="Exposed version information"
    ["robots-txt-exposed"]="Sensitive paths exposed in robots.txt"
    ["directory-listing"]="Directory listing enabled"
    ["ssl-weak-ciphers"]="Weak SSL/TLS ciphers"
    ["ssl-expired"]="Expired SSL certificate"
    ["ssh-weak-algorithms"]="Weak SSH algorithms"
)

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

# Initialize HTML report
initialize_html() {
    cat > "$HTML_REPORT" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Vulnerability Scan Report - $TARGET</title>
    <style>
        :root {
            --critical: #dc3545;
            --high: #fd7e14;
            --medium: #ffc107;
            --low: #20c997;
            --info: #17a2b8;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            border-bottom: 4px solid var(--critical);
            padding-bottom: 20px;
            margin-bottom: 30px;
            background: linear-gradient(135deg, #2c3e50, #34495e);
            color: white;
            padding: 30px;
            margin: -30px -30px 30px -30px;
            border-radius: 15px 15px 0 0;
        }
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .risk-summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .risk-card {
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            color: white;
            font-weight: bold;
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        .risk-critical { background: var(--critical); }
        .risk-high { background: var(--high); }
        .risk-medium { background: var(--medium); color: #000; }
        .risk-low { background: var(--low); }
        .risk-info { background: var(--info); }
        .section {
            margin-bottom: 30px;
            padding: 25px;
            border: 2px solid #e9ecef;
            border-radius: 12px;
            background: #f8f9fa;
            transition: transform 0.2s;
        }
        .section:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.1);
        }
        .section h2 {
            color: #2c3e50;
            border-bottom: 3px solid;
            padding-bottom: 12px;
            margin-top: 0;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .vulnerability {
            background: white;
            margin: 15px 0;
            padding: 20px;
            border-left: 5px solid;
            border-radius: 8px;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        .vuln-critical { border-left-color: var(--critical); }
        .vuln-high { border-left-color: var(--high); }
        .vuln-medium { border-left-color: var(--medium); }
        .vuln-low { border-left-color: var(--low); }
        .vuln-info { border-left-color: var(--info); }
        .vuln-title {
            font-weight: bold;
            font-size: 1.2em;
            margin-bottom: 10px;
            display: flex;
            justify-content: between;
            align-items: center;
        }
        .severity-badge {
            padding: 4px 12px;
            border-radius: 20px;
            color: white;
            font-size: 0.8em;
            margin-left: auto;
        }
        pre {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            font-size: 0.9em;
            border: 1px solid #444;
        }
        .timestamp {
            color: #6c757d;
            font-style: italic;
            text-align: center;
            margin: 20px 0;
        }
        .recommendation {
            background: #e7f3ff;
            border-left: 4px solid var(--info);
            padding: 15px;
            margin: 10px 0;
            border-radius: 4px;
        }
        .scan-metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
            border-top: 4px solid var(--info);
        }
        .progress-bar {
            background: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            height: 20px;
            margin: 10px 0;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--low), var(--high));
            transition: width 0.3s ease;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🛡️ Vulnerability Scan Report</h1>
            <div style="font-size: 1.2em; margin-top: 10px;">
                Target: <strong>$TARGET</strong> | 
                Generated: <strong>$(date)</strong>
            </div>
        </div>
EOF
}

# Add risk summary section
add_risk_summary() {
    local critical=$1 high=$2 medium=$3 low=$4 info=$5
    
    cat >> "$HTML_REPORT" << EOF
        <div class="risk-summary">
            <div class="risk-card risk-critical">
                <div style="font-size: 2em;">$critical</div>
                <div>Critical</div>
            </div>
            <div class="risk-card risk-high">
                <div style="font-size: 2em;">$high</div>
                <div>High</div>
            </div>
            <div class="risk-card risk-medium">
                <div style="font-size: 2em;">$medium</div>
                <div>Medium</div>
            </div>
            <div class="risk-card risk-low">
                <div style="font-size: 2em;">$low</div>
                <div>Low</div>
            </div>
            <div class="risk-card risk-info">
                <div style="font-size: 2em;">$info</div>
                <div>Info</div>
            </div>
        </div>
EOF
}

# Add vulnerability finding
add_vulnerability() {
    local title=$1 description=$2 severity=$3 proof=$4 recommendation=$5
    
    local severity_class="vuln-$severity"
    local severity_color=""
    
    case $severity in
        "critical") severity_color="var(--critical)" ;;
        "high") severity_color="var(--high)" ;;
        "medium") severity_color="var(--medium)" ;;
        "low") severity_color="var(--low)" ;;
        "info") severity_color="var(--info)" ;;
    esac
    
    cat >> "$HTML_REPORT" << EOF
        <div class="vulnerability $severity_class">
            <div class="vuln-title">
                $title
                <span class="severity-badge" style="background: $severity_color;">
                    $(echo $severity | tr '[:lower:]' '[:upper:]')
                </span>
            </div>
            <div class="vuln-description">
                <strong>Description:</strong> $description
            </div>
            <div class="vuln-proof">
                <strong>Proof:</strong><br>
                <pre>$(escape_html "$proof")</pre>
            </div>
            <div class="recommendation">
                <strong>Recommendation:</strong> $recommendation
            </div>
        </div>
EOF
}

# Initialize counters
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0
INFO_COUNT=0

# Initialize HTML report
initialize_html

echo -e "${YELLOW}[1] Checking HTTP Security Headers...${NC}"

# 1. HTTP Security Headers Check
if check_command "curl"; then
    SECURITY_HEADERS=(
        "Content-Security-Policy"
        "X-Frame-Options"
        "X-Content-Type-Options"
        "Strict-Transport-Security"
        "X-XSS-Protection"
        "Referrer-Policy"
        "Permissions-Policy"
    )
    
    missing_headers=()
    headers_output=$(curl -I -s "http://$TARGET" | head -20)
    https_headers_output=$(curl -I -s "https://$TARGET" 2>/dev/null | head -20)
    
    for header in "${SECURITY_HEADERS[@]}"; do
        if ! echo "$headers_output" | grep -qi "$header" && ! echo "$https_headers_output" | grep -qi "$header"; then
            missing_headers+=("$header")
        fi
    done
    
    if [ ${#missing_headers[@]} -gt 0 ]; then
        add_section "🔒 HTTP Security Headers" "<h3>Missing Security Headers</h3>"
        for header in "${missing_headers[@]}"; do
            add_vulnerability \
                "Missing $header header" \
                "The $header security header is not present, which may expose the application to various attacks." \
                "medium" \
                "HTTP response does not contain: $header" \
                "Add the $header header with appropriate values to enhance security."
            ((MEDIUM_COUNT++))
        done
    else
        add_section "🔒 HTTP Security Headers" "<p class='vuln-info'>All major security headers are present ✓</p>"
        ((INFO_COUNT++))
    fi
fi

echo -e "${YELLOW}[2] Testing HTTP Methods...${NC}"

# 2. HTTP Methods Testing
if check_command "curl"; then
    DANGEROUS_METHODS=("TRACE" "PUT" "DELETE" "OPTIONS")
    dangerous_methods_found=()
    
    for method in "${DANGEROUS_METHODS[@]}"; do
        response=$(curl -X "$method" -s -I "http://$TARGET" | head -1)
        if echo "$response" | grep -q "200\|405"; then
            dangerous_methods_found+=("$method")
        fi
    done
    
    if [ ${#dangerous_methods_found[@]} -gt 0 ]; then
        for method in "${dangerous_methods_found[@]}"; do
            if [ "$method" = "TRACE" ]; then
                add_vulnerability \
                    "TRACE method enabled" \
                    "TRACE method can be used in cross-site tracing (XST) attacks and may reveal sensitive information." \
                    "high" \
                    "HTTP TRACE method returns: 200 OK" \
                    "Disable TRACE method in web server configuration."
                ((HIGH_COUNT++))
            else
                add_vulnerability \
                    "$method method enabled" \
                    "The $method method is enabled and could be exploited if not properly secured." \
                    "medium" \
                    "HTTP $method method is allowed" \
                    "Ensure $method method is properly secured or disable if not needed."
                ((MEDIUM_COUNT++))
            fi
        done
    fi
fi

echo -e "${YELLOW}[3] Checking SSL/TLS Configuration...${NC}"

# 3. SSL/TLS Check
if check_command "openssl" && check_command "curl"; then
    ssl_output=$(echo | openssl s_client -connect "$TARGET:443" -servername "$TARGET" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)
    
    if [ -n "$ssl_output" ]; then
        not_after=$(echo "$ssl_output" | grep "notAfter" | cut -d= -f2)
        not_before=$(echo "$ssl_output" | grep "notBefore" | cut -d= -f2)
        
        current_epoch=$(date +%s)
        expire_epoch=$(date -d "$not_after" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$not_after" +%s 2>/dev/null)
        
        if [ -n "$expire_epoch" ] && [ "$current_epoch" -gt "$expire_epoch" ]; then
            add_vulnerability \
                "Expired SSL Certificate" \
                "The SSL certificate has expired, which will cause browser warnings and may indicate poor maintenance." \
                "high" \
                "Certificate expired on: $not_after" \
                "Renew the SSL certificate immediately."
            ((HIGH_COUNT++))
        fi
    else
        add_vulnerability \
            "No SSL Certificate Found" \
            "The target does not appear to have a valid SSL certificate configured for HTTPS." \
            "medium" \
            "Unable to retrieve SSL certificate information" \
            "Install a valid SSL certificate to enable secure HTTPS connections."
        ((MEDIUM_COUNT++))
    fi
fi

echo -e "${YELLOW}[4] Checking for Information Disclosure...${NC}"

# 4. Information Disclosure Checks
if check_command "curl"; then
    # Check robots.txt
    robots_content=$(curl -s "http://$TARGET/robots.txt")
    if [ -n "$robots_content" ] && [ "$robots_content" != "404" ] && [ "$robots_content" != "Not Found" ]; then
        sensitive_paths=$(echo "$robots_content" | grep -i "admin\|login\|config\|backup\|sql\|database" | head -5)
        if [ -n "$sensitive_paths" ]; then
            add_vulnerability \
                "Sensitive Paths in robots.txt" \
                "The robots.txt file reveals sensitive directory paths that could be targeted by attackers." \
                "low" \
                "Robots.txt contains:\n$sensitive_paths" \
                "Review robots.txt and remove references to sensitive directories."
            ((LOW_COUNT++))
        fi
    fi
    
    # Check for directory listing
    test_dir=$(curl -s "http://$TARGET/images/" | grep -i "index of" | head -1)
    if [ -n "$test_dir" ]; then
        add_vulnerability \
            "Directory Listing Enabled" \
            "Directory listing is enabled, exposing file and directory structure to potential attackers." \
            "medium" \
            "Directory listing found at: /images/" \
            "Disable directory listing in web server configuration."
        ((MEDIUM_COUNT++))
    fi
fi

echo -e "${YELLOW}[5] Network Vulnerability Checks...${NC}"

# 5. Network Level Checks
if check_command "nmap"; then
    if [ "$FULL_SCAN" = true ]; then
        echo -e "${BLUE}[-] Running comprehensive port scan...${NC}"
        nmap_result=$(nmap -sS -T4 -A -p- "$TARGET" 2>/dev/null | head -50)
    else
        echo -e "${BLUE}[-] Running quick port scan...${NC}"
        nmap_result=$(nmap -sS -T4 -F "$TARGET" 2>/dev/null | head -30)
    fi
    
    # Check for common vulnerable services
    if echo "$nmap_result" | grep -q "22/tcp.*open.*ssh"; then
        ssh_version=$(echo "$nmap_result" | grep -A2 "22/tcp.*open" | grep "version" | head -1)
        if echo "$ssh_version" | grep -q "7.\|6."; then
            add_vulnerability \
                "Potential SSH Version Vulnerabilities" \
                "The SSH service may be running an older version with known vulnerabilities." \
                "medium" \
                "SSH version: $ssh_version" \
                "Upgrade SSH to the latest version and implement key-based authentication."
            ((MEDIUM_COUNT++))
        fi
    fi
    
    # Check for FTP anonymous access
    if echo "$nmap_result" | grep -q "21/tcp.*open.*ftp"; then
        add_vulnerability \
            "FTP Service Detected" \
            "FTP service is running which may support anonymous access or use weak authentication." \
            "low" \
            "FTP service found on port 21" \
            "Consider using SFTP or FTPS instead of plain FTP, disable anonymous access."
            ((LOW_COUNT++))
    fi
fi

echo -e "${YELLOW}[6] Web Application Vulnerability Checks...${NC}"

# 6. Web Application Checks
if check_command "curl"; then
    # Check for common files
    COMMON_FILES=("admin.php" "config.php" "backup.zip" "test.php" "phpinfo.php")
    for file in "${COMMON_FILES[@]}"; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://$TARGET/$file")
        if [ "$response" = "200" ]; then
            add_vulnerability \
                "Exposed sensitive file: $file" \
                "A potentially sensitive file is publicly accessible." \
                "medium" \
                "File found: http://$TARGET/$file (HTTP $response)" \
                "Remove or restrict access to sensitive files."
            ((MEDIUM_COUNT++))
        fi
    done
    
    # Check for SQL injection patterns (basic)
    sql_test="' OR '1'='1"
    sql_response=$(curl -s "http://$TARGET/?id=$sql_test" | grep -i "error\|sql\|mysql" | head -1)
    if [ -n "$sql_response" ]; then
        add_vulnerability \
            "Potential SQL Injection Vulnerability" \
            "The application may be vulnerable to SQL injection attacks based on error response." \
            "high" \
            "SQL-like error detected: $(echo "$sql_response" | head -1)" \
            "Implement proper input validation and use parameterized queries."
        ((HIGH_COUNT++))
    fi
fi

# Add risk summary
add_risk_summary "$CRITICAL_COUNT" "$HIGH_COUNT" "$MEDIUM_COUNT" "$LOW_COUNT" "$INFO_COUNT"

# Add scan metrics
cat >> "$HTML_REPORT" << EOF
        <div class="section">
            <h2>📊 Scan Metrics</h2>
            <div class="scan-metrics">
                <div class="metric-card">
                    <h3>Total Vulnerabilities</h3>
                    <div style="font-size: 2em; font-weight: bold; color: var(--high);">
                        $((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))
                    </div>
                </div>
                <div class="metric-card">
                    <h3>Risk Score</h3>
                    <div style="font-size: 2em; font-weight: bold; color: var(--medium);">
                        $((CRITICAL_COUNT*10 + HIGH_COUNT*5 + MEDIUM_COUNT*2 + LOW_COUNT))
                    </div>
                </div>
                <div class="metric-card">
                    <h3>Scan Duration</h3>
                    <div style="font-size: 2em; font-weight: bold; color: var(--info);">
                        $(($(date +%s) - START_TIME))s
                    </div>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>🛠️ Remediation Summary</h2>
            <div class="recommendation">
                <h3>Priority Actions:</h3>
                <ul>
EOF

# Add priority recommendations based on findings
[ $CRITICAL_COUNT -gt 0 ] && echo "<li>🔴 Address critical vulnerabilities immediately</li>" >> "$HTML_REPORT"
[ $HIGH_COUNT -gt 0 ] && echo "<li>🟠 Fix high severity issues as soon as possible</li>" >> "$HTML_REPORT"
[ $MEDIUM_COUNT -gt 0 ] && echo "<li>🟡 Schedule medium severity fixes</li>" >> "$HTML_REPORT"
[ $LOW_COUNT -gt 0 ] && echo "<li>🟢 Review low severity findings</li>" >> "$HTML_REPORT"

cat >> "$HTML_REPORT" << EOF
                </ul>
            </div>
        </div>

        <div class="timestamp">
            Scan completed at: $(date)<br>
            Report generated by: Vulnerability Scanner v1.0
        </div>
    </div>
</body>
</html>
EOF

echo -e "${GREEN}"
echo "======================================"
echo "     VULNERABILITY SCAN COMPLETED"
echo "======================================"
echo -e "${NC}"
echo -e "${GREEN}[+] HTML Report generated: $HTML_REPORT${NC}"
echo -e "${GREEN}[+] Vulnerabilities found:${NC}"
echo -e "    ${RED}Critical: $CRITICAL_COUNT${NC}"
echo -e "    ${YELLOW}High: $HIGH_COUNT${NC}"
echo -e "    ${BLUE}Medium: $MEDIUM_COUNT${NC}"
echo -e "    ${GREEN}Low: $LOW_COUNT${NC}"
echo -e "    ${BLUE}Info: $INFO_COUNT${NC}"
echo ""
echo -e "${GREEN}[+] To view the report:${NC}"
echo -e "    ${BLUE}xdg-open \"$HTML_REPORT\"${NC}"

# Open the report automatically if possible
if command -v xdg-open &> /dev/null; then
    xdg-open "$HTML_REPORT" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "$HTML_REPORT" 2>/dev/null &
fi
