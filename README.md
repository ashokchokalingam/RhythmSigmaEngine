
High-Level README: Log Ingestion, Rotation, and Threat Detection Setup
Overview
This setup script automates the process of configuring a system for log ingestion, rotation, and threat detection using Logstash, Zircolite, and rsyslog. It processes syslog data, detects security threats using selected detection rules, and forwards the results to a SIEM system.

Features
Rule-Based Threat Detection: Allows selection of up to three detection rule files from a predefined list.
Logstash Configuration: Collects syslog data via TCP/UDP, processes multiline logs, and formats them for downstream analysis.
Log Rotation: Automatically rotates logs when they reach a specified size, defaulting to 500 KB (scalable up to 500 MB).
Zircolite Integration: Analyzes rotated logs for threats using selected rules and outputs results in JSON format.
Log Forwarding: Uses rsyslog to forward processed threat detection logs to a SIEM system.
Systemd Service: Ensures continuous operation of the log rotation and Zircolite processing system.
Prerequisites
Operating System: Ubuntu or other Debian-based Linux distributions.
Minimum Resources:
CPU: 8 cores
Memory: 16 GB RAM (increase for higher data volumes)
Privileges: Root or sudo access.
Network: Internet connection for package downloads and SIEM forwarding.
Dependencies: Python 3, pip, Git, and GNU Parallel.
Installation and Setup
Run the Script:

bash
Copy code
chmod +x setup_script.sh
sudo ./setup_script.sh
This installs and configures Logstash, Zircolite, and rsyslog, and sets up the system for log processing.

Select Detection Rules: During execution, you will be prompted to select up to three rule files for Zircolite. The selected rules are saved to /usr/local/bin/rules_selection.conf.

Provide SIEM IP: Enter the IP address of your SIEM system when prompted for rsyslog configuration.

Key Directories and Files
Logstash Configuration: /etc/logstash/conf.d/logstash.conf
Processed Logs: /var/log/logstash/processed_syslog.xml
Log Rotation Archives: /var/log/logstash/log_rotation_archive
Threat Detection Output: /var/log/logstash/detected_zircolite/
Empty Threat Output: /var/log/logstash/no_threats_detected/
Zircolite Installation: /root/Zircolite
Customization
Adjust Log File Size
To increase the log file size threshold:

Edit /usr/local/bin/log_rotation.sh.
Modify the MAX_SIZE variable:
bash
Copy code
MAX_SIZE=$((500 * 1024 * 1024))  # 500 MB in bytes
Add/Change Zircolite Rules
Update /usr/local/bin/rules_selection.conf to specify different detection rules.

Modify rsyslog Configuration
Edit /etc/rsyslog.d/zircolite.conf to customize log forwarding behavior.

Monitoring and Troubleshooting
Check Systemd Service
Restart the service:
bash
Copy code
sudo systemctl restart log_rotation.service
Check service status:
bash
Copy code
sudo systemctl status log_rotation.service
Debugging
View Logstash logs:
bash
Copy code
sudo journalctl -u logstash
Check rsyslog configuration:
bash
Copy code
sudo cat /etc/rsyslog.d/zircolite.conf
Scaling and Performance
Higher Data Volumes: Increase memory and disk I/O performance for smoother operation.
Parallel Processing: Utilizes GNU Parallel to maximize CPU usage during log processing.
Retention Policy: Keeps only processed threat detection files from the last 24 hours to conserve disk space.
Contact
For questions or issues, please contact the maintainer or open an issue in the project repository.
