# Log Ingestion, Rotation, and Threat Detection Setup

## Overview
This script automates **log ingestion**, **rotation**, and **threat detection** using **Logstash**, **Zircolite**, and **rsyslog**. It processes syslog data, detects threats, and forwards results to a SIEM system.

## Features
- **Rule-Based Threat Detection**: Select up to 3 detection rules.
- **Logstash Configuration**: Collects and processes syslog data.
- **Log Rotation**: Rotates logs at a configurable size (default 500 KB, scalable to 500 MB).
- **Zircolite Integration**: Detects threats using rules and outputs results in JSON.
- **Systemd Service**: Ensures continuous operation.

## Prerequisites
- **OS**: Ubuntu/Debian.
- **Resources**: 8-core CPU, 16 GB RAM (increase for higher data volumes).
- **Tools**: Python 3, pip, Git, GNU Parallel.

## Installation
1. **Run Script**:
   ```bash
   chmod +x setup_script.sh
   sudo ./setup_script.sh
Select Rules: Choose up to 3 rule files.
Configure rsyslog: Provide SIEM IP for log forwarding.
Key Directories
Logstash Config: /etc/logstash/conf.d/logstash.conf
Processed Logs: /var/log/logstash/processed_syslog.xml
Zircolite Install: /root/Zircolite
Scaling and Performance
Increase Memory: Allocate more RAM for higher volumes.
Parallel Processing: Adjust -j in parallel to match CPU cores.
Log Size Threshold: Edit MAX_SIZE in /usr/local/bin/log_rotation.sh:
bash
Copy code
MAX_SIZE=$((500 * 1024 * 1024))  # Set to 500 MB
Retention Policy: Retain logs for 24 hours:
bash
Copy code
find /var/log/logstash/detected_zircolite/ -type f -mmin +1440 -exec rm -f {} \;
Systemd Service
Start:
bash
Copy code
sudo systemctl start log_rotation.service
Restart:
bash
Copy code
sudo systemctl restart log_rotation.service
Status:
bash
Copy code
sudo systemctl status log_rotation.service
Troubleshooting
Logstash Logs:
bash
Copy code
sudo journalctl -u logstash
Check rsyslog:
bash
Copy code
sudo cat /etc/rsyslog.d/zircolite.conf
Contact
For issues, contact the maintainer or open a GitHub issue.
