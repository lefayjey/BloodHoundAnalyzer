#!/bin/bash

data_dir="/opt/BA_tools/"
sudo mkdir "${data_dir}" 2>/dev/null
sudo chown -R "$(whoami)":"$(whoami)" "${data_dir}"

git clone https://github.com/Tanguy-Boisset/bloodhound-automation "${data_dir}"/bloodhound-automation

pipx install git+https://github.com/Mazars-Tech/AD_Miner --force

git clone https://github.com/PlumHound/PlumHound "${data_dir}"/PlumHound
pip3 install -r "${data_dir}"/PlumHound/requirements.txt

wget https://raw.githubusercontent.com/zeronetworks/BloodHound-Tools/main/Ransomulator/ransomulator.py -O "${data_dir}"/ransomulator.py

pipx install git+https://github.com/lefayjey/GoodHound --force