
# BloodHoundAnalyzer

## Overview

BloodHoundAnalyzer is a bash script designed to automate the deployment, data import, and analysis of BloodHound CE (Community Edition), an Active Directory (AD) security tool. This script facilitates the setup and management of BloodHound CE containers, import of data, and running various analysis tools on the collected data.

## Features

- **Data Collection**: Includes bloodhound-ce-python for AD data collection
- **Multi-Domain Support**: Deploy separate BloodHound CE instances for different domains
- **Automated Container Management**: Start, stop, and clean BloodHound CE containers with custom naming
- **Custom Port Configuration**: Configure custom ports for Neo4j and BloodHound web interface
- **Automatic Password Management**: Automatically reset admin password to a standard password
- **Multiple Data Import Formats**: Import .zip files, .json files, or folders containing JSON files
- **Integrated Analysis Tools**: Run AD-miner, GoodHound, Ransomulator, PlumHound, ad-recon, and BloodHound QuickWin
- **Project Listing**: View all deployed BloodHound projects and their status

## Prerequisites

Before using BloodHoundAnalyzer, ensure you have the following installed:

- **Python 3** with venv support
- **Linux environment** (tested on Ubuntu/Debian) or WSL2 on Windows

Run the `install.sh` script to install the required tools:
  - **bloodhound-ce-python**: Python-based AD data collector for BloodHound CE
  - **bloodhound-cli**: BloodHound CE command-line interface
  - **AD-miner**: Generates comprehensive AD security reports
  - **GoodHound**: Identifies high-value attack paths
  - **Ransomulator**: Simulates ransomware attack paths
  - **BloodHound QuickWin**: Quick analysis script
  - **PlumHound**: Task-based analysis tool
  - **ad-recon**: AD pathing and transitive rights analysis

```bash
# Install BloodHoundAnalyzer
git clone https://github.com/lefayjey/BloodHoundAnalyzer
cd BloodHoundAnalyzer
chmod +x ./install.sh
./install.sh
```

## Usage

Run the script with one or more modules as detailed below:

```bash
chmod +x ./BloodHoundAnalyzer.sh
./BloodHoundAnalyzer.sh [OPTIONS]
```

### Options

- `-d, --domain DOMAIN`  
  Specify the AD domain to analyze (required for most operations).  
  Containers will be named: `<domain>-graph-db-1`, `<domain>-app-db-1`, `<domain>-bloodhound-1`

- `-o, --output OUTPUT_DIR`  
  Specify the directory where analysis results will be saved.  
  Default: `/opt/BA_output`

- `-D, --data DATA_PATH`  
  Specify the path to BloodHound data:
  - `.zip` file (SharpHound collection)
  - `.json` file (single collection file)
  - Folder containing `.json` files

- `-M, --modules MODULES`  
  Comma-separated modules to execute:
  - **list**: List all deployed BloodHound projects and their status
  - **start**: Start BloodHound CE containers for the specified domain
  - **import**: Import BloodHound data (automatically starts containers if needed)
  - **analyze**: Run analysis tools (AD-miner, GoodHound, Ransomulator, BloodHound QuickWin)
  - **stop**: Stop BloodHound CE containers (preserves data volumes)
  - **clean**: Remove BloodHound CE containers, volumes, and project data

- `--bolt-port PORT`  
  Specify Neo4j Bolt port (default: 7687)

- `--neo4j-port PORT`  
  Specify Neo4j HTTP port (default: 7474)

- `--web-port PORT`  
  Specify BloodHound web interface port (default: 7080)

- `-h, --help`  
  Display the help message

## Examples

### List All Deployed Projects

```bash
./BloodHoundAnalyzer.sh -M list
```

### Deploy BloodHound CE for a Domain

```bash
./BloodHoundAnalyzer.sh -M start -d contoso.local
```

Access at: `http://127.0.0.1:7080/ui/login`
- Username: `admin`
- Password: `BloodHound2025!@` (automatically set)

### Deploy with Custom Ports

```bash
./BloodHoundAnalyzer.sh -M start -d contoso.local --bolt-port 7688 --neo4j-port 7475 --web-port 7081
```

### Import BloodHound Data

Import a ZIP file:
```bash
./BloodHoundAnalyzer.sh -M import -d contoso.local -D /path/to/bloodhound_data.zip
```

Import JSON files from a folder:
```bash
./BloodHoundAnalyzer.sh -M import -d contoso.local -D /path/to/json_folder/
```

### Run Analysis Tools

```bash
./BloodHoundAnalyzer.sh -M analyze -d contoso.local -o /opt/reports
```

This will generate:
- AD-miner HTML report in `ADMinerReport_contoso.local/`
- GoodHound analysis in `GoodHound_contoso.local/`
- BloodHound QuickWin output in `bhqc_contoso.local.txt`
- Ransomulator results in `ransomulator_contoso.local.txt`
- PlumHound reports in `PlumHound_contoso.local/`
- ad-recon analysis in `ad-recon_contoso.local/`

### Complete Workflow (Import + Analyze)

```bash
./BloodHoundAnalyzer.sh -M import,analyze -d contoso.local -D /path/to/data.zip -o /opt/reports
```

### Stop BloodHound CE Containers

```bash
./BloodHoundAnalyzer.sh -M stop -d contoso.local
```

Note: Volumes are preserved for restart

### Clean Up Deployment

```bash
./BloodHoundAnalyzer.sh -M clean -d contoso.local
```

Warning: This removes containers, volumes, and project data permanently!

### Multiple Domains (Isolated Instances)

Deploy and manage multiple domains simultaneously:

```bash
# Deploy first domain
./BloodHoundAnalyzer.sh -M start -d corp.local --web-port 7080

# Deploy second domain with different ports
./BloodHoundAnalyzer.sh -M start -d dev.local --web-port 7081 --bolt-port 7688 --neo4j-port 7475

# List all projects
./BloodHoundAnalyzer.sh -M list
```

## Directory Structure

```
/opt/BA_tools/
├── bloodhound-cli           # BloodHound CE CLI
├── .venv/                   # Python virtual environment
├── bhqc.py                  # BloodHound QuickWin script
├── ransomulator.py          # Ransomulator script
└── projects/
    ├── contoso.local/       # Project directory per domain
    │   ├── docker-compose.yml
    │   └── .env
    └── corp.local/
        ├── docker-compose.yml
        └── .env

/opt/BA_output/              # Analysis output directory
├── contoso.local/
│   ├── ADMinerReport_contoso.local/
│   ├── ad-recon_contoso.local/
│   ├── GoodHound_contoso.local/
│   ├── PlumHound_contoso.local/
│   ├── bhqc_contoso.local.txt
│   └── ransomulator_contoso.local.csv
└── corp.local/
    └── ...
```

## Default Credentials

- **BloodHound CE Web Interface**:
  - URL: `http://127.0.0.1:7080/ui/login`
  - Username: `admin`
  - Password: `BloodHound2025!@` (automatically configured)

- **Neo4j Database** (for analysis tools):
  - Bolt: `bolt://127.0.0.1:7687`
  - Username: `neo4j`
  - Password: `bloodhoundcommunityedition`


### Containers Won't Start

```bash
# Check Docker is running
docker ps

# Check container logs
docker logs <domain>-bloodhound-1

# Clean and restart
./BloodHoundAnalyzer.sh -M clean -d domain.local
./BloodHoundAnalyzer.sh -M start -d domain.local
```

### Import Fails

```bash
# Check API accessibility
curl http://127.0.0.1:7080/api/version

# Check container logs
docker logs <domain>-bloodhound-1

# Verify data file format (should be .zip or .json)
```

## License

This project is licensed under the terms of the MIT license.

## Acknowledgments

BloodHoundAnalyzer uses the following tools:
- [BloodHound CE](https://github.com/SpecterOps/BloodHound) - Active Directory security tool
- [AD_Miner](https://github.com/Mazars-Tech/AD_Miner) - AD security analysis and reporting
- [GoodHound](https://github.com/idnahacks/GoodHound) - Attack path analysis
- [Ransomulator](https://github.com/zeronetworks/BloodHound-Tools/tree/main/Ransomulator) - Ransomware simulation
- [BloodHound QuickWin](https://github.com/kaluche/bloodhound-quickwin) - Quick analysis script
- [PlumHound](https://github.com/PlumHound/PlumHound) - Task-based reporting
- [ad-recon](https://github.com/tid35/ad-recon) - AD pathing and transitive rights analysis

## Author

**lefayjey** - [GitHub](https://github.com/lefayjey/BloodHoundAnalyzer)
