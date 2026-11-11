#!/usr/bin/env bash
# Generates an HTML server status report for Week 3.

OUT_DIR="/var/www/html/viikko3"
GITHUB_URL="https://github.com/Jebachu/viikko3-status-report"

# Returns OK below 80% and WARNING at 80% or above
get_disk_status() {
    local percent="$1"
    if [ "$percent" -ge 80 ]; then
        echo "WARNING"
    else
        echo "OK"
    fi
}

GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S %Z (UTC%z)')
UPTIME_TEXT=$(uptime -p | sed 's/^up //')
# TEST_PERCENT can override the value when testing the status logic
DISK_PERCENT="${TEST_PERCENT:-$(df -P / | awk 'NR == 2 {print $5}' | tr -d '%')}"
DISK_USAGE="${DISK_PERCENT}%"
DISK_STATUS=$(get_disk_status "$DISK_PERCENT")
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_AVAILABLE=$(free -m | awk '/^Mem:/ {print $7}')

TEMP_FILE=$(mktemp "$OUT_DIR/.index.XXXXXX")

cat > "$TEMP_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Week 3 – Server Status Report</title>
    <style>
        body {
            font-family: system-ui, sans-serif;
            max-width: 900px;
            margin: 40px auto;
            padding: 0 20px;
            line-height: 1.6;
            background: #121820;
            color: #d8e2ec;
        }
        h1, h2, h3 { color: #4fc3f7; }
        section {
            margin: 24px 0;
            padding: 24px;
            background: #1c2733;
            border-radius: 12px;
        }
        .table-container { overflow-x: auto; }
        table { border-collapse: collapse; width: 100%; }
        th, td {
            border: 1px solid #3a4b5e;
            padding: 12px;
            text-align: left;
        }
        th { background: #24364a; }
        code {
            background: #121820;
            padding: 2px 5px;
            border-radius: 4px;
            overflow-wrap: anywhere;
        }
        a { color: #4fc3f7; }
        .note { color: #9fb2c4; }
    </style>
</head>
<body>
    <header>
        <h1>Server Status Report</h1>
        <p>Week 3: Linux command line and Bash scripting</p>
        <p>This page shows the status of my Linux server in CSC cPouta.
           A Bash script updates it every minute.</p>
        <p><a href="/">Week 1</a> | <a href="/viikko2">Week 2</a></p>
    </header>

    <section>
        <h2>Current server status</h2>

        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th scope="col">Information</th>
                        <th scope="col">Value</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <th scope="row">Report generated</th>
                        <td>$GENERATED_AT</td>
                    </tr>
                    <tr>
                        <th scope="row">Server uptime</th>
                        <td>$UPTIME_TEXT</td>
                    </tr>
                    <tr>
                        <th scope="row">Root filesystem disk usage</th>
                        <td>$DISK_USAGE</td>
                    </tr>
                    <tr>
                        <th scope="row">Disk space status</th>
                        <td>$DISK_STATUS</td>
                    </tr>
                    <tr>
                        <th scope="row">Total RAM</th>
                        <td>$MEM_TOTAL MiB</td>
                    </tr>
                    <tr>
                        <th scope="row">Available RAM</th>
                        <td>$MEM_AVAILABLE MiB</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <p>
            Disk space status is <strong>OK</strong> below 80% usage
            and <strong>WARNING</strong> at 80% or above.
        </p>

        <p class="note">
            Bash generates this report once per minute.
            Wait approximately 1–2 minutes and reload the page
            to see a new generation time.
        </p>
    </section>

    <section>
        <h2>Documentation</h2>
        <p>TODO: documentation is added in a later step.</p>
    </section>

    <footer>
        <p><a href="$GITHUB_URL">View the source code on GitHub</a></p>
    </footer>
</body>
</html>
EOF

chmod 644 "$TEMP_FILE"
mv "$TEMP_FILE" "$OUT_DIR/index.html"
