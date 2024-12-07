Logstash and Zircolite Integration Script
This repository contains a Bash script designed to streamline the setup and configuration of Logstash and Zircolite for processing and analyzing log files with selected Sigma rules. This guide walks you through the functionalities and usage of the script.

Features
Rule File Selection: Select up to three Sigma rule files for processing.
Logstash Setup: Automates the installation and configuration of Logstash to receive syslog input.
Zircolite Integration: Downloads and configures Zircolite to process rotated log files.
Log Rotation: Automatically rotates large log files and processes them in parallel.
Rsyslog Forwarding: Configures rsyslog to send processed logs to a SIEM.
Systemd Service: Ensures the log rotation and processing service runs continuously.
Prerequisites
Before running the script, ensure the following are installed:

A Linux-based OS (e.g., Ubuntu 20.04+)
Internet connection
Root privileges
Installation Steps
1. Clone the Repository
bash
Copy code
git clone <repository-url>
cd <repository-directory>
2. Run the Script
bash
Copy code
sudo bash setup_script.sh
The script will guide you through various configurations.

Components
Rule File Selection
The script provides a list of available Sigma rule files.
Select up to three rule files by their corresponding numbers.
Selected files are stored in /usr/local/bin/rules_selection.conf.
Example:

bash
Copy code
1. rules_linux.json
2. rules_windows_generic.json
3. rules_windows_sysmon.json
Logstash Configuration
Installation: Installs Logstash and its dependencies.
Configuration: Creates an input pipeline to receive syslog data (ports 5514 for UDP/TCP).
Output: Writes processed syslog data to /var/log/logstash/processed_syslog.xml.
Zircolite Setup
Clones the Zircolite repository from GitHub.
Installs dependencies using pip3 and requirements.full.txt.
Processes log files using the selected rule files.
Log Rotation
Rotates log files exceeding 500 KB.
Splits large log files into smaller chunks for parallel processing.
Detected events are saved to /var/log/logstash/detected_zircolite/.
Rsyslog Integration
Forwards processed JSON logs to the configured SIEM IP address.
Systemd Service
Automates log rotation and processing with a background service.
Automatically restarts in case of failure.
Usage
Start the Service
bash
Copy code
sudo systemctl start log_rotation.service
Stop the Service
bash
Copy code
sudo systemctl stop log_rotation.service
Check Service Status
bash
Copy code
sudo systemctl status log_rotation.service
File Structure
Configuration Files:

/etc/logstash/conf.d/logstash.conf – Logstash configuration.
/usr/local/bin/rules_selection.conf – Selected rule files.
/etc/rsyslog.d/zircolite.conf – Rsyslog configuration.
Log Files:

/var/log/logstash/processed_syslog.xml – Input logs.
/var/log/logstash/detected_zircolite/ – Detected threats.
/var/log/logstash/no_threats_detected/ – Empty detections.
Scripts:

/usr/local/bin/log_rotation.sh – Log rotation and Zircolite processing.
Troubleshooting
Error: No Rules Specified
Run the script again and select rule files.

Service Not Running
Check logs using:

bash
Copy code
journalctl -u log_rotation.service
Dependencies Missing
Ensure all prerequisites are installed and rerun the script.

Contribution
Feel free to contribute by submitting pull requests or raising issues.

License
This project is licensed under the MIT License. See the LICENSE file for details.
