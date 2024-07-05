#!/bin/bash

tools_dir="/opt/BA_tools"
sudo mkdir "${tools_dir}" 2>/dev/null
sudo chown -R "$(whoami)":"$(whoami)" "${tools_dir}"

pip3 install py2neo pandas prettytable neo4j tabulate argcomplete alive-progress
pipx install git+https://github.com/dirkjanm/bloodhound.py --force
pipx install "git+https://github.com/dirkjanm/BloodHound.py@bloodhound-ce" --force --suffix '_ce'
git clone https://github.com/Tanguy-Boisset/bloodhound-automation "${tools_dir}"/bloodhound-automation
pipx install git+https://github.com/fox-it/bloodhound-import --force
pipx install git+https://github.com/Mazars-Tech/AD_Miner --force
git clone https://github.com/PlumHound/PlumHound "${tools_dir}"/PlumHound
wget https://raw.githubusercontent.com/zeronetworks/BloodHound-Tools/main/Ransomulator/ransomulator.py -O "${tools_dir}"/ransomulator.py
wget https://raw.githubusercontent.com/kaluche/bloodhound-quickwin/main/bhqc.py -O "${tools_dir}"/bhqc.py
pipx install git+https://github.com/lefayjey/GoodHound --force