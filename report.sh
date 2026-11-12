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
        <h2>Commands used</h2>
        <ul>
            <li><code>date '+%Y-%m-%d %H:%M:%S %Z (UTC%z)'</code>:
                prints the current date, time and time zone.</li>
            <li><code>uptime -p</code>:
                shows how long the server has been running.</li>
            <li><code>df -P / | awk 'NR == 2 {print &#36;5}' | tr -d '%'</code>:
                a pipe. <code>df</code> lists disk usage, <code>awk</code>
                picks the usage column from row 2, and <code>tr</code>
                removes the % sign so the number can be compared.</li>
            <li><code>free -m | awk '/^Mem:/ {print &#36;2}'</code>:
                shows memory in MiB, and <code>awk</code> picks total RAM
                (column 7 gives available RAM).</li>
        </ul>
    </section>

    <section>
        <h2>How it works</h2>
        <p>The Bash script <code>report.sh</code> runs the commands above and
           stores each result in a variable using command substitution,
           for example <code>UPTIME_TEXT=&#36;(uptime -p)</code>.
           It then writes the HTML page to a temporary file and moves it to
           <code>/var/www/html/viikko3/index.html</code>, so Nginx never
           serves a half-written page.</p>
        <p>The function <code>get_disk_status</code> takes the usage percent
           and uses an if statement: at 80 or above it returns WARNING,
           otherwise OK.</p>
        <p>The schedule uses <strong>cron</strong>. The line
           <code>* * * * * /home/ubuntu/viikko3-app/report.sh</code>
           runs the script every minute. The cron service is enabled with
           systemd, so it starts again after a reboot.</p>
    </section>

    <section>
        <h2>Test results</h2>
        <p>Syntax check <code>bash -n report.sh</code>: passed, no errors.
           The script was also run manually and the report opened in a browser.</p>
        <div class="table-container">
            <table>
                <thead>
                    <tr><th scope="col">Test input</th>
                        <th scope="col">Expected</th>
                        <th scope="col">Actual</th></tr>
                </thead>
                <tbody>
                    <tr><td>50%</td><td>OK</td><td>OK</td></tr>
                    <tr><td>80%</td><td>WARNING</td><td>WARNING</td></tr>
                    <tr><td>90%</td><td>WARNING</td><td>WARNING</td></tr>
                </tbody>
            </table>
        </div>
        <p>Test values were given with <code>TEST_PERCENT=90 ./report.sh</code>.
           Afterwards the script was run normally and the real usage returned.</p>
        <p>Automatic updates: cron generated reports at 12:22:01 and
           12:23:01 UTC, exactly one minute apart.</p>
        <p>Reboot test: REBOOT_PLACEHOLDER</p>
    </section>

    <section>
        <h2>A problem I solved</h2>
        <p>While testing I mistyped the variable name as
           <code>EST_PERCENT=90</code>. The script ignored it and showed the
           real disk usage (5%, OK) instead of the 90% test. I noticed the
           output was wrong, fixed the typo and repeated the test.
           I learned to always check that test output matches the input.</p>
    </section>

    <footer>
        <p><a href="$GITHUB_URL">View the source code on GitHub</a></p>
    </footer>
</body>
</html>
EOF

chmod 644 "$TEMP_FILE"
mv "$TEMP_FILE" "$OUT_DIR/index.html"
