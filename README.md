# Logstash and Zircolite Integration Script

This repository contains a Bash script designed to streamline the setup and configuration of **Logstash** and **Zircolite** for processing and analyzing log files with selected Sigma rules. This guide walks you through the functionalities and usage of the script.

----------

## Features

-   **Rule File Selection**: Select up to three Sigma rule files for processing.
-   **Logstash Setup**: Automates the installation and configuration of Logstash to receive syslog input.
-   **Zircolite Integration**: Downloads and configures Zircolite to process rotated log files.
-   **Log Rotation**: Automatically rotates large log files and processes them in parallel.
-   **Rsyslog Forwarding**: Configures rsyslog to send processed logs to a SIEM.
-   **Systemd Service**: Ensures the log rotation and processing service runs continuously.

----------

## Prerequisites

Ensure the following requirements are met before running the script:

-   A Linux-based OS (e.g., Ubuntu 20.04+)
-   Internet connection
-   Root privileges

----------

## Installation Steps

### Step 1: Clone the Repository

bash

Copy code

`git clone <repository-url>
cd <repository-directory>` 

### Step 2: Run the Script

bash

Copy code

`sudo bash setup_script.sh` 

The script will guide you through all configurations.

----------

## Components

### Rule File Selection

-   The script provides a list of available Sigma rule files.
-   You can select up to **three rule files** by their corresponding numbers.
-   Selected rule files are saved in the file:  
    `/usr/local/bin/rules_selection.conf`.

----------

### Logstash Configuration

-   **Installation**: Installs Logstash and all necessary dependencies.
-   **Configuration**: Configures Logstash to receive syslog data from UDP and TCP on port `5514`.
-   **Output**: Processed logs are saved to:  
    `/var/log/logstash/processed_syslog.xml`.

----------

### Zircolite Setup

-   **Repository Clone**: Clones the Zircolite repository from GitHub.
-   **Dependency Installation**: Installs Python dependencies listed in `requirements.full.txt`.
-   **Processing**: Processes rotated log files using the selected Sigma rules.

----------

### Log Rotation

-   **Trigger**: Rotates log files when they exceed **500 KB**.
-   **Split Files**: Splits large logs into smaller chunks for parallel processing.
-   **Detection Results**:
    -   Detected threats are saved in:  
        `/var/log/logstash/detected_zircolite/`.
    -   Empty detections are saved in:  
        `/var/log/logstash/no_threats_detected/`.

----------

### Rsyslog Integration

-   **Configuration File**: Adds an rsyslog configuration file to forward processed logs to a configured SIEM.
-   **Customizable Destination**: Prompts for the SIEM IP address during setup.

----------

### Systemd Service

-   **Service Creation**: Creates a `systemd` service to run the log rotation and processing script continuously.
-   **Automatic Restart**: The service automatically restarts in case of failure.

----------

## Usage

### Start the Service

bash

Copy code

`sudo systemctl start log_rotation.service` 

### Stop the Service

bash

Copy code

`sudo systemctl stop log_rotation.service` 

### Check Service Status

bash

Copy code

`sudo systemctl status log_rotation.service` 

----------

## File Structure

### Configuration Files

-   **Logstash Configuration**:  
    `/etc/logstash/conf.d/logstash.conf`
-   **Selected Rules File**:  
    `/usr/local/bin/rules_selection.conf`
-   **Rsyslog Configuration**:  
    `/etc/rsyslog.d/zircolite.conf`

----------

### Log Files

-   **Processed Logs**:  
    `/var/log/logstash/processed_syslog.xml`
-   **Detected Threats**:  
    `/var/log/logstash/detected_zircolite/`
-   **No Threats Detected**:  
    `/var/log/logstash/no_threats_detected/`

----------

### Scripts

-   **Log Rotation and Zircolite Processing**:  
    `/usr/local/bin/log_rotation.sh`

----------

## Troubleshooting

### Error: No Rules Specified

-   Ensure the rule selection script has been executed.
-   Rerun the script to select Sigma rule files.

### Service Not Running

-   Check the service logs:
    
    bash
    
    Copy code
    
    `journalctl -u log_rotation.service` 
    

### Missing Dependencies

-   Verify prerequisites are installed.
-   Rerun the script to complete dependency installation.

----------

## Contribution

Contributions are welcome! Feel free to:

-   Submit pull requests.
-   Report issues or bugs.

----------

## License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.
