#!/bin/bash

tools_dir="/opt/BA_tools"

sudo mkdir "${tools_dir}" 2>/dev/null
sudo chown -R "$(whoami)":"$(whoami)" "${tools_dir}"

pipx_install_or_upgrade() {
    local url="$1"
    local package_name="$2"
    [[ $(pipx list) =~ $package_name ]] && pipx upgrade "$package_name" || pipx install "$url"
}

sudo apt-get update
sudo apt-get install pipx docker.io docker-compose -y

python3 -m venv "${tools_dir}/.venv"
source "${tools_dir}/.venv/bin/activate"
pip3 install py2neo pandas prettytable neo4j tabulate argcomplete alive-progress "numpy<1.29.0" colorama requests termcolor toml --upgrade
deactivate

wget https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz -O "${tools_dir}"/bloodhound-cli-linux-amd64.tar.gz

tar -xvzf "${tools_dir}"/bloodhound-cli-linux-amd64.tar.gz -C "${tools_dir}"
chmod +x "${tools_dir}"/bloodhound-cli

pipx_install_or_upgrade "git+https://github.com/dirkjanm/BloodHound.py@bloodhound-ce" bloodhound-ce
pipx_install_or_upgrade git+https://github.com/Mazars-Tech/AD_Miner AD_Miner
wget https://github.com/PlumHound/PlumHound/archive/refs/heads/master.zip -O "${tools_dir}"/PlumHound.zip
unzip -o "${tools_dir}"/PlumHound.zip -d "${tools_dir}"
wget https://raw.githubusercontent.com/zeronetworks/BloodHound-Tools/main/Ransomulator/ransomulator.py -O "${tools_dir}"/ransomulator.py
wget https://raw.githubusercontent.com/kaluche/bloodhound-quickwin/main/bhqc.py -O "${tools_dir}"/bhqc.py
pipx_install_or_upgrade git+https://github.com/idnahacks/GoodHound GoodHound
wget -q "https://github.com/tid35/ad-recon/archive/refs/heads/main.zip" -O "${tools_dir}"/ad-recon.zip
unzip -o "${tools_dir}"/ad-recon.zip -d "${tools_dir}"