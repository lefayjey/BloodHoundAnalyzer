
# BloodHoundAnalyzer

## Overview

BloodHoundAnalyzer is a bash script designed to automate the deployment, data import, and analysis of BloodHound, an Active Directory (AD) security tool. This script facilitates the setup and teardown of a BloodHound instance, import of AD data, and running various analysis tools on the collected data.

## Prerequisites

Before using BloodHoundAnalyzer, ensure you have the following tools installed:

- python3
- Docker and docker-compose (for BloodHoundCE version)
- neo4j (for old BloodHound version)

Run the `install.sh` script to install the following BloodHound automation and analysis tools:
  - **bloodhound-python**: Collects Active Directory data.
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
  Specify the AD domain to analyze (required for BloodHoundCE and for Collection).

- `-u, --username`  
  Username (required for Collection only).

- `-p, -.password`  
  Password - NTLM authentication (required for Collection only).

- `-H, --hash`  
  LM:NT - NTLM authentication (required for Collection only).

- `-K, --kerb`  
  Location to Kerberos ticket './krb5cc_ticket' - Kerberos authentication (required for Collection only).

- `-A, --aes`  
  AES Key - Kerberos authentication (required for Collection only).

- `--dc`  
  IP Address of Target Domain Controller (required for Collection only)."

- `-o, --output OUTPUT_DIR`  
  Specify the directory where analysis results will be saved. Defaults to the current directory.

- `-D, --data DATA_PATH`  
  Specify the path to the BloodHound ZIP file to import.

- `-M, --modules MODULES`  
  Comma separated modules to execute between:  
    - **collect:** Run bloodHound-python to collect Active Directory data.  
    - **list** : List available projects (only for BloodHoundCE).  
    - **start** : Start BloodHoundCE containers or neo4j.  
    - **run** : Run BloodHound GUI or Firefox with BloodHoundCE webpage.  
    - **import** : Import BloodHound data into the neo4j database.  
    - **analyze** : Run analysis tools (AD-miner, GoodHound, Ransomulator, PlumHound) on the imported data.  
    - **stop** : Stop BloodHoundCE containers or neo4j.  
    - **clean** : Stop and delete BloodHoundCE containers (only for BloodHoundCE).  

- `--old`  
  Use the old version of BloodHound.

- `--oldpass`  
  Specify neo4j password for the old version of BloodHound.

- `-h, --help`  
  Display the help message.

## Examples

### Collect Active Directory data

```bash
./BloodHoundAnalyzer.sh -M collect -d example.com -u user -p password
```

### List BloodHoundCE projects

```bash
./BloodHoundAnalyzer.sh -M list
```

### Start BloodHoundCE containers or old BloodHound's neo4j

```bash
./BloodHoundAnalyzer.sh -M start -d example.com
./BloodHoundAnalyzer.sh -M start --old
```

### Run BloodHound GUI or Firefox with BloodHoundCE web page

```bash
./BloodHoundAnalyzer.sh -M run
./BloodHoundAnalyzer.sh -M run --old
```

### Start BloodHound, and Run Analysis on imported data

```bash
./BloodHoundAnalyzer.sh -M analyze -d example.com -o /path/to/output
./BloodHoundAnalyzer.sh -M analyze --old -o /path/to/output
```

### Start BloodHound, Import Data, and Run Analysis

```bash
./BloodHoundAnalyzer.sh -M import,analyze -d example.com --data /path/to/bloodhound/data.zip -o /path/to/output
./BloodHoundAnalyzer.sh -M import,analyze --data /path/to/bloodhound/data.zip --old -o /path/to/output
```

### Stop BloodHound

```bash
./BloodHoundAnalyzer.sh -M stop -d example.com
./BloodHoundAnalyzer.sh -M stop --old
```

### Clean up BloodHoundCE Containers

```bash
./BloodHoundAnalyzer.sh -M clean -d example.com
```

## License

This project is licensed under the terms of the MIT license. 

## Acknowledgments
- https://github.com/dirkjanm/BloodHound.py
- https://github.com/Tanguy-Boisset/bloodhound-automation
- https://github.com/Mazars-Tech/AD_Miner
- https://github.com/PlumHound/PlumHound
- https://github.com/idnahacks/GoodHound
- https://github.com/zeronetworks/BloodHound-Tools/blob/main/Ransomulator
- https://github.com/kaluche/bloodhound-quickwin
