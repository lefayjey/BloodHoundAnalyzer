
# BloodHoundAnalyzer

## Overview

BloodHoundAnalyzer is a bash script designed to automate the deployment, data import, and analysis of BloodHound, an Active Directory (AD) security tool. This script facilitates the setup and teardown of a BloodHound instance, import of AD data, and running various analysis tools on the collected data.

## Prerequisites

Before using BloodHoundAnalyzer, ensure you have the following tools installed:

- python3
- Docker and docker-compose (for BloodHoundCE version)
- neo4j (for old BloodHound version)

Run the `install.sh` script to install the following BloodHound automation and analysis tools 
  - **bloodhound-automation**: Automates deployment of BloodHoundCE.
  - **AD-miner**: Generates an AD miner report.
  - **GoodHound**: Runs GoodHound analysis.
  - **Ransomulator**: Runs the ransomulator script.
  - **BloodHound QuickWin**: Runs the BloodHoundQuickWin script.
  - **PlumHound**: Runs PlumHound tasks and short path analyses.

```bash
chmod +x ./install.sh
./install.sh
```
## Usage

Run the script with one or more of the options as detailed below. Make sure to have the necessary permissions to execute Docker or run neo4j.

```bash
chmod +x ./BloodHoundAnalyzer.sh
./BloodHoundAnalyzer.sh [OPTIONS]
```

### Options

- `-d, --domain DOMAIN`  
  Specify the AD domain to analyze (required for BloodHoundCE).

- `-o, --output OUTPUT_DIR`  
  Specify the directory where analysis results will be saved. Defaults to the current directory.

- `--all`  
  Run all steps (List, Start, Run, Import, Analyze, Stop and Clean).

- `--list`  
  List available projects (only for BloodHoundCE).

- `--start`  
  Start BloodHoundCE containers or neo4j.

- `--run`  
  Run BloodHound GUI or Firefox with BloodHoundCE webpage.

- `--data DATA_PATH`  
  Specify the path to the BloodHound ZIP file to import.

- `--import`  
  Import BloodHound data into the neo4j database.

- `--analyze`  
  Run analysis tools (AD-miner, GoodHound, Ransomulator, PlumHound) on the imported data.

- `--stop`  
  Stop BloodHoundCE containers or neo4j.

- `--clean`  
  Stop and delete BloodHoundCE containers (only for BloodHoundCE).

- `--old`  
  Use the old version of BloodHound.

- `--oldpass`  
  Specify neo4j password for the old version of BloodHound.

- `-h, --help`  
  Display the help message.

## Examples

### List BloodHoundCE projects

```bash
./BloodHoundAnalyzer.sh --start -d example.com
./BloodHoundAnalyzer.sh --start --old
```

### Start BloodHoundCE or old BloodHound

```bash
./BloodHoundAnalyzer.sh --start -d example.com
./BloodHoundAnalyzer.sh --start --old
```

### Start BloodHoundCE, Import Data, and Run Analysis

```bash
./BloodHoundAnalyzer.sh -d example.com --import /path/to/bloodhound/data.zip --analyze -o /path/to/output
```

### Start old BloodHound and Run Analysis

```bash
./BloodHoundAnalyzer.sh --import /path/to/bloodhound/data.zip --old -o /path/to/output
```

### Stop BloodHoundCE or old BloodHound

```bash
./BloodHoundAnalyzer.sh --stop -d example.com
./BloodHoundAnalyzer.sh --stop --old
```

### Clean up BloodHoundCE Containers

```bash
./BloodHoundAnalyzer.sh -d example.com --clean
```

## License

This project is licensed under the terms of the MIT license. 

## Acknowledgments
- https://github.com/Tanguy-Boisset/bloodhound-automation
- https://github.com/Mazars-Tech/AD_Miner
- https://github.com/PlumHound/PlumHound
- https://github.com/idnahacks/GoodHound
- https://github.com/zeronetworks/BloodHound-Tools/blob/main/Ransomulator
- https://github.com/kaluche/bloodhound-quickwin
