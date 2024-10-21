#!/bin/bash

tools_dir="/opt/BA_tools"
sudo mkdir "${tools_dir}" 2>/dev/null
sudo chown -R "$(whoami)":"$(whoami)" "${tools_dir}"
sudo apt install docker.io

python3 -m venv "${tools_dir}/.venv"
source "${tools_dir}/.venv/bin/activate"
pip3 install py2neo pandas prettytable neo4j tabulate argcomplete alive-progress "numpy<1.29.0" colorama requests --upgrade
deactivate
pipx install git+https://github.com/dirkjanm/bloodhound.py --force
pipx install "git+https://github.com/dirkjanm/BloodHound.py@bloodhound-ce" --force --suffix '_ce'
git clone https://github.com/Tanguy-Boisset/bloodhound-automation "${tools_dir}"/bloodhound-automation
pipx install git+https://github.com/fox-it/bloodhound-import --force
pipx install git+https://github.com/Mazars-Tech/AD_Miner --force
wget https://github.com/PlumHound/PlumHound/archive/refs/heads/master.zip -O "${tools_dir}"/PlumHound.zip
unzip -o "${tools_dir}"/PlumHound.zip -d "${tools_dir}"
wget https://raw.githubusercontent.com/zeronetworks/BloodHound-Tools/main/Ransomulator/ransomulator.py -O "${tools_dir}"/ransomulator.py
wget https://raw.githubusercontent.com/kaluche/bloodhound-quickwin/main/bhqc.py -O "${tools_dir}"/bhqc.py
pipx install git+https://github.com/idnahacks/GoodHound --force