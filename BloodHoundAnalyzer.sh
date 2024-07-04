#!/bin/bash
# Title: BloodHoundAnalyzer
# Author: lefayjey

#Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'


data_dir="/opt/BA_tools/"
neo4j_user="neo4j"
neo4j_pass="neo5j"
bolt_port=10001
neo4j_port=10501
web_port=8001
current_dir=$(pwd)
output_dir="${current_dir}"
clean_bool=false
analyze_bool=false

args=()
while test $# -gt 0; do
    case $1 in
    -d | --domain)
        domain="${2}"
        shift
        ;;
    -o)
        output_dir="$(realpath "${2}")"
        shift
        ;;
    --injest)
        bhd_data="$(realpath "${2}")"
        shift
        ;;
    --clean)
        clean_bool=true
        args+=("$1")
        ;;
    --analyze)
        analyze_bool=true
        args+=("$1")
        ;;
    -h | --help)
        exit
        ;;
    *)
        echo -e "${RED}[BloodHoundAnalyzer ANALYZE] Unknown option:${NC} ${1}"
        echo -e "Use -h for help"
        exit 1
        ;;
    esac
    shift
done
set -- "${args[@]}"

if [ -z "${domain}" ]; then
    echo -e "${RED}[BloodHoundAnalyzer] Domain not specified${NC}"
    exit 1
fi

cd "${data_dir}"/bloodhound-automation/ || exit
if [ "${clean_bool}" == false ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer START] Deploying BloodHound${NC}"
    sudo python3 bloodhound-automation.py start -bp "${bolt_port}" -np "${neo4j_port}" -wp "${web_port}" "${domain}" 2>/dev/null
fi

if [ -n "${bhd_data}" ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer INJEST] Injesting data${NC}"
    sudo python3 bloodhound-automation.py data -z "${bhd_data}" "${domain}"
    echo -e "${GREEN}[BloodHoundAnalyzer INJEST] Running Firefox${NC}"
    firefox-esr http://127.0.0.1:"${web_port}" &
fi
cd "${current_dir}" || exit

if [ "${analyze_bool}" == true ]; then

    mkdir -p "${output_dir}/PlumHound_${domain}"
    mkdir -p "${output_dir}/GoodHound_${domain}"

    cd "${output_dir}" || exit
    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE] Running AD-miner${NC}"
    AD-miner -cf ADMinerReport"_${domain}" -b bolt://127.0.0.1:"${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" --cluster 127.0.0.1:"${bolt_port}":32
    rm -rf "${output_dir}"/cache_neo4j 2>/dev/null
    mv render_ADMinerReport"_${domain}" ADMinerReport"_${domain}"
    echo -e ""

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE] Running GoodHound${NC}"
    GoodHound -s bolt://127.0.0.1:"${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" -d "${output_dir}/GoodHound_${domain}" --patch41
    rm -rf "${output_dir}"/goodhound.db 2>/dev/null
    echo -e ""

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE] Running Ransomulator${NC}"
    python3 "${data_dir}/ransomulator.py" -o "ransomulator_${domain}" -l bolt://127.0.0.1:"${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" -w 12 
    echo -e ""

    cd "${data_dir}"/PlumHound/ || exit
    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE] Running PlumHound${NC}"
    python3 PlumHound.py -x tasks/default.tasks -s "bolt://127.0.0.1:${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" -v 0 --op "${output_dir}/PlumHound_${domain}"
    python3 PlumHound.py -bp short 5 -s "bolt://127.0.0.1:${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" --op "${output_dir}/PlumHound_${domain}"
    python3 PlumHound.py -bp all 5 -s "bolt://127.0.0.1:${bolt_port}" -u  "${neo4j_user}" -p "${neo4j_pass}" --op "${output_dir}/PlumHound_${domain}"
    echo -e ""

    cd "${current_dir}" || exit
fi

if [ "${clean_bool}" == true ]; then
    cd "${data_dir}"/bloodhound-automation/ || exit
    echo -e "${GREEN}[BloodHoundAnalyzer CLEAN] Stopping and deleting containers${NC}"
    container_name="${domain/\./}"
    sudo docker container stop "${container_name}"_graph-db_1 2>/dev/null
    sudo docker container stop "${container_name}"_app-db_1 2>/dev/null
    sudo docker container stop "${container_name}"_bloodhound_1 2>/dev/null
    sudo python3 bloodhound-automation.py delete "${domain}" 2>/dev/null
    cd "${current_dir}" || exit
fi