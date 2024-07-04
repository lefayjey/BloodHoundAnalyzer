
# BloodHoundAnalyzer

## Overview

BloodHoundAnalyzer is a bash script designed to automate the deployment, data ingestion, and analysis of BloodHound, an Active Directory (AD) security tool. This script facilitates the setup and teardown of a BloodHound instance, ingestion of AD data, and running various analysis tools on the collected data.

## Prerequisites

Before using BloodHoundAnalyzer, ensure you have the following tools installed before running the `install.sh` script.

- python3
- Docker
- Firefox ESR

## Usage

Run the script with the appropriate options as detailed below. Make sure to have the necessary permissions to execute Docker and other commands with `sudo`.

```bash
./BloodHoundAnalyzer.sh [OPTIONS]
```

### Examples

- `-d, --domain DOMAIN`  
  **Required.** Specify the AD domain to analyze.

- `-o OUTPUT_DIR`  
  Specify the directory where analysis results will be saved. Defaults to the current directory.

- `--injest DATA_PATH`  
  Specify the path to the BloodHound data to ingest.

- `--clean`  
  Stop and delete BloodHound containers after analysis.

- `--analyze`  
  Run analysis tools (AD-miner, GoodHound, Ransomulator, PlumHound) on the ingested data.

- `-h, --help`  
  Display the help message.

## Examples

### Deploy BloodHound and Ingest Data

```bash
./BloodHoundAnalyzer.sh --domain example.com --injest /path/to/bloodhound/data.zip
```

### Deploy BloodHound, Ingest Data, and Run Analysis

```bash
./BloodHoundAnalyzer.sh --domain example.com --injest /path/to/bloodhound/data.zip --analyze
```

### Clean Up bloodHound Containers

```bash
./BloodHoundAnalyzer.sh --domain example.com --clean
```

## Steps

1. **Ingest Data**: If the `--injest` option is provided, the script ingests BloodHound data from the specified path and launches Firefox to view the data.

2. **Run Analysis**: If the `--analyze` option is set, the script runs several analysis tools:
   - **AD-miner**: Generates an AD miner report.
   - **GoodHound**: Runs GoodHound analysis.
   - **Ransomulator**: Runs the ransomulator script.
    - **PlumHound**: Runs PlumHound tasks and short path analyses.

3. **Clean Up**: If the `--clean` option is set, the script stops and deletes the Docker containers associated with the BloodHound instance.

## License

This project is licensed under the terms of the MIT license. 

## Acknowledgments
- https://github.com/Tanguy-Boisset/bloodhound-automation/tree/master
- https://github.com/Mazars-Tech/AD_Miner
- https://github.com/PlumHound/PlumHound
- https://github.com/idnahacks/GoodHound
-https://github.com/zeronetworks/BloodHound-Tools/blob/main/Ransomulator/ransomulator.py
