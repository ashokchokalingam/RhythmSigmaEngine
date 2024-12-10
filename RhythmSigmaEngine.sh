#!/bin/bash

# Enable error handling to stop execution on any command failure
set -e

# Trap errors and output the line number where the error occurred
trap 'echo "Error occurred at line $LINENO. Exiting."; exit 1;' ERR

# Configuration file to store the selected rule file
RULES_CONF="/usr/local/bin/rules_selection.conf"

# Hardcoded list of rule files
RULES=(
    "rules_linux.json"
    "rules_windows_generic.json"
    "rules_windows_generic_full.json"
    "rules_windows_generic_high.json"
    "rules_windows_generic_medium.json"
    "rules_windows_generic_pysigma.json"
    "rules_windows_sysmon.json"
    "rules_windows_sysmon_full.json"
    "rules_windows_sysmon_high.json"
    "rules_windows_sysmon_medium.json"
    "rules_windows_sysmon_pysigma.json"
)

# Function to prompt user to select up to three rule files
select_rule_files() {
    echo "Available rule files:"
    for i in "${!RULES[@]}"; do
        echo "$((i + 1)). ${RULES[i]}"
    done

    echo "You can select up to three rule files. Enter the numbers separated by spaces (e.g., 1 2 3):"
    read -r SELECTIONS

    # Split the selections into an array
    read -ra SELECTED_RULES <<< "$SELECTIONS"

    # Validate the selections
    if [[ "${#SELECTED_RULES[@]}" -gt 3 ]]; then
        echo "Error: You can select a maximum of three rules. Exiting."
        exit 1
    fi

    for SELECTION in "${SELECTED_RULES[@]}"; do
        if [[ "$SELECTION" -lt 1 || "$SELECTION" -gt "${#RULES[@]}" ]]; then
            echo "Error: Invalid selection '$SELECTION'. Exiting."
            exit 1
        fi
    done

    # Save the selected rules to the config file
    echo "Saving the selected rule files to $RULES_CONF..."
    > "$RULES_CONF"  # Clear the file
    for SELECTION in "${SELECTED_RULES[@]}"; do
        echo "${RULES[$((SELECTION - 1))]}" >> "$RULES_CONF"
    done
    echo "Selected rules saved to $RULES_CONF:"
    cat "$RULES_CONF"
}

# Execute rule selection
select_rule_files

### Section 1: Logstash Installation and Configuration ###

# Logstash configuration variables
LOGSTASH_CONF="/etc/logstash/conf.d/logstash.conf"
LOGSTASH_OUTPUT="/var/log/logstash/processed_syslog.xml"

install_logstash() {
    echo "Installing Logstash..."
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
    sudo apt update
    sudo apt install -y logstash
}

configure_logstash() {
    echo "Configuring Logstash..."
    sudo tee "$LOGSTASH_CONF" >/dev/null <<EOL
input {
  udp {
    port => 5514
    type => "syslog"
    codec => multiline {
      pattern => "^<Event"
      negate => "true"
      what => "previous"
    }
  }
  tcp {
    port => 5514
    type => "syslog"
    codec => multiline {
      pattern => "^<Event"
      negate => "true"
      what => "previous"
    }
  }
}

filter {
  if [type] == "syslog" {
    ruby {
      code => '
        message = event.get("message")
        message = message.gsub(/<\/Event>/, "")
        message += "</Event>"
        message = message.gsub(/\r?\n/, " ")
        event.set("message", message)
      '
    }
  }
}

output {
  file {
    path => "$LOGSTASH_OUTPUT"
    codec => line { format => "%{message}" }
  }
}
EOL
}

start_logstash() {
    echo "Starting Logstash..."
    sudo systemctl enable logstash
    sudo systemctl restart logstash
}

### Section 2: Dependency and Zircolite Installation ###

ZIRCOLITE_DIR="/root/Zircolite"

install_dependencies() {
    echo "Installing required dependencies..."
    sudo apt update
    if ! command -v pip3 &>/dev/null; then
        echo "Installing pip3..."
        sudo apt install -y python3-pip
    fi
    pip3 install --upgrade pyyaml==6.0
    if ! command -v parallel &>/dev/null; then
        echo "Installing GNU Parallel..."
        sudo apt install -y parallel
    fi
}

install_zircolite() {
    echo "Installing Zircolite..."
    if [ ! -d "$ZIRCOLITE_DIR" ]; then
        git clone https://github.com/wagga40/Zircolite.git "$ZIRCOLITE_DIR"
    fi
    cd "$ZIRCOLITE_DIR"
    pip3 install -r requirements.full.txt
}

### Section 3: Adding Log Rotation Script ###

add_log_rotation_script() {
    echo "Adding Log Rotation Script..."
    LOG_ROTATION_SCRIPT="/usr/local/bin/log_rotation.sh"
    sudo tee "$LOG_ROTATION_SCRIPT" >/dev/null <<'EOF'
#!/bin/bash

# Load the selected rules from rules_selection.conf
RULES_CONF="/usr/local/bin/rules_selection.conf"

if [[ -f "$RULES_CONF" ]]; then
    readarray -t SELECTED_RULES < "$RULES_CONF"  # Read all lines into an array
    if [[ "${#SELECTED_RULES[@]}" -eq 0 ]]; then
        echo "Error: No rules specified in $RULES_CONF."
        exit 1
    fi
    echo "Using rule files: ${SELECTED_RULES[*]}"
else
    echo "Configuration file $RULES_CONF not found. Please run the selection script first."
    exit 1
fi

# Configuration variables
LOG_FILE="/var/log/logstash/processed_syslog.xml"
ARCHIVE_DIR="/var/log/logstash/log_rotation_archive"
OUTPUT_DIR="/var/log/logstash/detected_zircolite"
EMPTY_OUTPUT_DIR="/var/log/logstash/no_threats_detected"
PARALLELS_DIR="/var/log/logstash/parallels"
ZIRCOLITE_DIR="/root/Zircolite"
SPLIT_PREFIX="split_"
SPLIT_SUFFIX=".xml"
MAX_SIZE=$((500 * 1024))  # Maximum size of the log file before rotation (500 KB in bytes)

mkdir -p "$ARCHIVE_DIR" "$OUTPUT_DIR" "$EMPTY_OUTPUT_DIR" "$PARALLELS_DIR"

rotate_and_process_log() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    ROTATED_FILE="$ARCHIVE_DIR/processed_syslog_$TIMESTAMP.xml"
    DETECTED_FILE="$OUTPUT_DIR/detected_events_$TIMESTAMP.json"
    EMPTY_DETECTED_FILE="$EMPTY_OUTPUT_DIR/no_threats_detected_$TIMESTAMP.json"

    cp "$LOG_FILE" "$ROTATED_FILE" && : > "$LOG_FILE"
    chown logstash:logstash "$LOG_FILE"
    sleep 3

    cd "$PARALLELS_DIR" || exit
    split -n 10 --additional-suffix="$SPLIT_SUFFIX" "$ROTATED_FILE" "$SPLIT_PREFIX"

    cd "$ZIRCOLITE_DIR" || exit

    # Build the -r arguments dynamically based on selected rules
    RULE_ARGS=()
    for RULE in "${SELECTED_RULES[@]}"; do
        RULE_ARGS+=("-r rules/$RULE")
    done

    # Execute the command
    parallel -j 8 python3 zircolite.py -e {} "${RULE_ARGS[@]}" \
    --xml --template templates/exportForSplunk.tmpl \
    --templateOutput "/tmp/output_{/.}.json" ::: "$PARALLELS_DIR/$SPLIT_PREFIX"*.xml

    find /tmp -name "output_*.json" -exec cat {} \; > "$DETECTED_FILE"
    if [ ! -s "$DETECTED_FILE" ]; then
        echo '{"message": "No threats detected."}' > "$EMPTY_DETECTED_FILE"
        rm -f "$DETECTED_FILE"
    fi

    rm -f /tmp/output_*.json "$PARALLELS_DIR/$SPLIT_PREFIX"*.xml

    # Retain only the last 7 files in $OUTPUT_DIR
    ls -tp "$OUTPUT_DIR" | grep -v '/$' | tail -n +8 | xargs -I {} rm -f "$OUTPUT_DIR/{}"

    # Retain only the last 7 files in $ARCHIVE_DIR
    ls -tp "$ARCHIVE_DIR" | grep -v '/$' | tail -n +8 | xargs -I {} rm -f "$ARCHIVE_DIR/{}"

    # Retain only the last 7 files in $EMPTY_OUTPUT_DIR
    ls -tp "$EMPTY_OUTPUT_DIR" | grep -v '/$' | tail -n +8 | xargs -I {} rm -f "$EMPTY_OUTPUT_DIR/{}"
}

while true; do
    if [ -f "$LOG_FILE" ]; then
        FILE_SIZE=$(stat -c%s "$LOG_FILE")
        if [ "$FILE_SIZE" -ge "$MAX_SIZE" ]; then
            rotate_and_process_log
        fi
    fi
    sleep 10
done
EOF

    sudo chmod +x "$LOG_ROTATION_SCRIPT"
}

### Section 4: Adding rsyslog Configuration ###

add_rsyslog_config() {
    echo "Configuring rsyslog..."
    RSYSLOG_CONF="/etc/rsyslog.d/zircolite.conf"

    read -p "Enter the IP address of the LogRhythm System Monitor Agent: " SIEM_IP

    if ! command -v rsyslogd &>/dev/null; then
        echo "Installing rsyslog..."
        sudo apt install -y rsyslog
    fi

    sudo tee "$RSYSLOG_CONF" >/dev/null <<EOL
###########################
#### MODULES ####
###########################
\$MaxMessageSize 64k

module(load="imfile")

template(name="SingleLineJSONFormat" type="string" string="%msg%\n")

###########################
#### INPUTS ####
###########################

input(type="imfile"
      File="/var/log/logstash/detected_zircolite/*.json"
      Tag="sigma"
      Severity="info"
      Facility="local6"
      readMode="0"
      escapeLF="off"
)

###########################
#### OUTPUTS ####
###########################

if \$syslogtag == 'sigma' then @@$SIEM_IP:514;SingleLineJSONFormat
EOL

    sudo systemctl restart rsyslog
}

### Section 5: Creating a Systemd Service ###

create_service() {
    echo "Creating systemd service for log rotation..."
    SERVICE_FILE="/etc/systemd/system/log_rotation.service"
    sudo tee "$SERVICE_FILE" >/dev/null <<EOL
[Unit]
Description=Log Rotation and Zircolite Processing Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/log_rotation.sh
Restart=always
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=log_rotation_service

[Install]
WantedBy=multi-user.target
EOL

    sudo systemctl daemon-reload
    sudo systemctl enable log_rotation.service
    sudo systemctl start log_rotation.service
}

### Main Execution ###

install_logstash           # Step 1: Install Logstash
configure_logstash         # Step 2: Configure Logstash
start_logstash             # Step 3: Start Logstash service
install_dependencies       # Step 4: Install necessary dependencies
install_zircolite          # Step 5: Install Zircolite
add_log_rotation_script    # Step 6: Add the log rotation script
add_rsyslog_config         # Step 7: Configure rsyslog
create_service             # Step 8: Create and start the systemd service

echo "Setup completed successfully!"
