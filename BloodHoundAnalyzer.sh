#!/bin/bash
# Title: BloodHoundAnalyzer
# Author: lefayjey

#Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
NC='\033[0m'

#Default variables
tools_dir="/opt/BA_tools"
neo4j_user="neo4j"
neo4j_pass="neo5j"
bolt_port=7687
neo4j_port=7474
web_port=7080
current_dir=$(pwd)
output_dir="${current_dir}"
list_bool=false
start_bool=false
run_bool=false
import_bool=false
analyze_bool=false
stop_bool=false
clean_bool=false
bhdce_bool=true

print_banner() {
    echo -e "
         ___ _                 _                             _   _               _                    
        / __\ | ___   ___   __| | /\  /\___  _   _ _ __   __| | /_\  _ __   __ _| |_   _ _______ _ __ 
       /__\// |/ _ \ / _ \ / _' |/ /_/ / _ \| | | | '_ \ / _' |//_\\| '_ \ / _' | | | | |_  / _ \ '__|
      / \/  \ | (_) | (_) | (_| / __  / (_) | |_| | | | | (_| /  _  \ | | | (_| | | |_| |/ /  __/ |   
      \_____/_|\___/ \___/ \__,_\/ /_/ \___/ \__,_|_| |_|\__,_\_/ \_/_| |_|\__,_|_|\__, /___\___|_|   
                                                                                   |___/              
      ${BLUE}BloodHoundAnalyzer: ${CYAN}version 0.1 ${NC}
      https://github.com/lefayjey/BloodHoundAnalyzer
      ${BLUE}Author: ${CYAN}lefayjey${NC}
"
}

print_help() {
    print_banner
    echo -e "${YELLOW}Parameters${NC}"
    echo -e "-d/--domain DOMAIN          Specify the AD domain to analyze (required for BloodHoundCE)."
    echo -e "-o/--output OUTPUT_DIR      Specify the directory where analysis results will be saved. Defaults to the current directory."
    echo -e "--all                       Run all steps (List, Start, Run, Import, Analyze, Stop and Clean)."
    echo -e "--list                      List available projects (only for BloodHoundCE)."
    echo -e "--start                     Start BloodHoundCE containers or neo4j."
    echo -e "--run                       Run BloodHound GUI or Firefox with BloodHoundCE webpage."
    echo -e "-D/--data DATA_PATH         Specify the path to the BloodHound ZIP file to import"
    echo -e "--import                    Import BloodHound data into the neo4j database."
    echo -e "--analyze                   Run analysis tools (AD-miner, GoodHound, Ransomulator, PlumHound) on the imported data."
    echo -e "--stop                      Stop BloodHoundCE containers or neo4j."
    echo -e "--clean                     Stop and delete BloodHoundCE containers (only for BloodHoundCE)."
    echo -e "--old                       Use the old version of BloodHound."
    echo -e "--oldpass                   Specify neo4j password for the old version of BloodHound."
    echo -e "-h/--help                   Display the help message."
    echo -e ""
}

args=()
while test $# -gt 0; do
    case $1 in
    -d | --domain)
        domain="${2}"
        shift
        ;;
    -o | --output)
        output_dir="$(realpath "${2}")"
        shift
        ;;
    --all)
        list_bool=true
        start_bool=true
        run_bool=true
        import_bool=true
        analyze_bool=true
        stop_bool=true
        clean_bool=true
        args+=("$1")
        ;;
    --list)
        list_bool=true
        args+=("$1")
        ;;
    --start)
        start_bool=true
        args+=("$1")
        ;;
    --run)
        start_bool=true
        run_bool=true
        args+=("$1")
        ;;
    -D | --data)
        bhd_data="$(realpath "${2}")"
        shift
        ;;
    --import)
        import_bool=true
        start_bool=true
        args+=("$1")
        ;;
    --analyze)
        analyze_bool=true
        start_bool=true
        args+=("$1")
        ;;
    --stop)
        stop_bool=true
        args+=("$1")
        ;;
    --clean)
        clean_bool=true
        stop_bool=true
        args+=("$1")
        ;;
    --old)
        bhdce_bool=false
        args+=("$1")
        ;;
    --oldpass)
        neo4j_pass="${2}"
        shift
        ;;
    -h | --help)
        print_help
        exit
        ;;
    *)
        echo -e "${RED}[BloodHoundAnalyzer]${NC} Unknown option:${NC} ${1}"
        echo -e "Use -h for help"
        exit 1
        ;;
    esac
    shift
done
set -- "${args[@]}"

if [ -z "${domain}" ] && [ "${bhdce_bool}" == true ] && { [ "${start_bool}" == true ] || [ "${import_bool}" == true ] || [ "${analyze_bool}" == true ] || [ "${stop_bool}" == true ] || [ "${clean_bool}" == true ]; }; then
    echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain not specified"
    exit 1
fi

if [ -z "${bhd_data}" ] && [ "${import_bool}" == true ]; then
    echo -e "${RED}[BloodHoundAnalyzer]${NC} BloodHound zip file not specified"
    exit 1
fi

if [ "${list_bool}" == false ] && [ "${start_bool}" == false ] && [ "${import_bool}" == false ] && [ "${analyze_bool}" == false ] && [ "${stop_bool}" == false ] && [ "${clean_bool}" == false ]; then
    echo -e "${RED}[BloodHoundAnalyzer]${NC} Please specify one or more of the following: --list, --start, --inject BloodHound_ZIP, --analyze, --stop, --clean"
    exit 1
fi

if [ "${list_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        echo -e "${PURPLE}[BloodHoundAnalyzer LIST]${NC} Only available for BloodHoundCE"
    else
        cd "${tools_dir}"/bloodhound-automation/ || exit
        echo -e "${GREEN}[BloodHoundAnalyzer LIST]${NC} Listing deployed projects"
        sudo python3 bloodhound-automation.py list
        cd "${current_dir}" || exit
    fi
    echo -e ""
fi

if [ "${start_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        echo -e "${GREEN}[BloodHoundAnalyzer START]${NC} Starting neo4j"
        sudo neo4j start 2>&1 &
    else
        cd "${tools_dir}"/bloodhound-automation/ || exit
        echo -e "${GREEN}[BloodHoundAnalyzer START]${NC} Deploying BloodHound containers"
        sudo python3 bloodhound-automation.py start -bp "${bolt_port}" -np "${neo4j_port}" -wp "${web_port}" "${domain}"
        cd "${current_dir}" || exit
    fi
    echo -e ""
fi

if [ "${run_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        sleep 10
        echo -e "${GREEN}[BloodHoundAnalyzer RUN]${NC} Running BloodHound"
        bloodhound --no-sandbox >/dev/null 2>&1 &
    else
        sleep 5
        echo -e "${GREEN}[BloodHoundAnalyzer START]${NC} Running Firefox"
        firefox-esr http://127.0.0.1:"${web_port}" >/dev/null 2>&1 &
    fi
    echo -e ""
fi

if [ "${import_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        echo -e "${GREEN}[BloodHoundAnalyzer IMPORT]${NC} Importing data"
        while [ "${neo4j_pass}" == "" ]; do
            echo -e "${YELLOW}[BloodHoundAnalyzer IMPORT]${NC} Please specify password of neo4j:"
            echo -e "${RED}Invalid password.${NC} Please specify password of neo4j:"
            read -rp ">> " neo4j_pass </dev/tty
        done
        bloodhound-import -du "${neo4j_user}" -dp "${neo4j_pass}" "${bhd_data}"
    else
        if [ -n "${bhd_data}" ]; then
            cd "${tools_dir}"/bloodhound-automation/ || exit
            echo -e "${GREEN}[BloodHoundAnalyzer IMPORT]${NC} Importing data"
            sudo python3 bloodhound-automation.py data -z "${bhd_data}" "${domain}"
            cd "${current_dir}" || exit
        else
            echo -e "${RED}[BloodHoundAnalyzer IMPORT]${NC} BloodHound ZIP file not found"
            exit 1
        fi
    fi
    echo -e ""
fi

if [ "${analyze_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        while [ "${neo4j_pass}" == "" ]; do
            echo -e "${YELLOW}[BloodHoundAnalyzer ANALYZE]${NC} Please specify password of neo4j:"
            read -rp ">> " neo4j_pass </dev/tty
        done
        while [ "${domain}" == "" ]; do
            echo -e "${YELLOW}[BloodHoundAnalyzer ANALYZE]${NC} Please specify domain:"
            read -rp ">> " domain </dev/tty
        done
    fi

    mkdir -p "${output_dir}/PlumHound_${domain}"
    mkdir -p "${output_dir}/GoodHound_${domain}"
    cd "${output_dir}" || exit

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running AD-miner"
    AD-miner -cf ADMinerReport"_${domain}" -b bolt://127.0.0.1:"${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" --cluster 127.0.0.1:"${bolt_port}":32
    rm -rf "${output_dir}"/cache_neo4j 2>/dev/null
    mv render_ADMinerReport"_${domain}" ADMinerReport"_${domain}"
    echo -e ""

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running GoodHound"
    GoodHound -s bolt://127.0.0.1:"${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" -d "${output_dir}/GoodHound_${domain}" --patch41
    rm -rf "${output_dir}"/goodhound.db 2>/dev/null
    echo -e ""

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running BloodHoundQuickWin"
    python3 "${tools_dir}/bhqc.py" -u "${neo4j_user}" -p "${neo4j_pass}" -d "${domain}" --heavy -b bolt://127.0.0.1:"${bolt_port}" | tee "${output_dir}/bhqc_${domain}.txt"
    echo -e ""

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running Ransomulator"
    python3 "${tools_dir}/ransomulator.py" -o "ransomulator_${domain}" -l bolt://127.0.0.1:"${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" -w 12
    echo -e ""

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running PlumHound"
    cd "${tools_dir}"/PlumHound/ || exit
    python3 PlumHound.py -x tasks/default.tasks -s "bolt://127.0.0.1:${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" -v 0 --op "${output_dir}/PlumHound_${domain}"
    python3 PlumHound.py -bp short 5 -s "bolt://127.0.0.1:${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" --op "${output_dir}/PlumHound_${domain}"
    python3 PlumHound.py -bp all 5 -s "bolt://127.0.0.1:${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" --op "${output_dir}/PlumHound_${domain}"
    echo -e ""

    cd "${current_dir}" || exit
fi

if [ "${stop_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        echo -e "${GREEN}[BloodHoundAnalyzer STOP]${NC} Stopping neo4j"
        sudo neo4j stop 2>&1
    else
        echo -e "${GREEN}[BloodHoundAnalyzer STOP]${NC} Stopping Docker containers"
        container_name="${domain/\./}"
        sudo docker container stop "${container_name}"_graph-db_1 2>/dev/null
        sudo docker container stop "${container_name}"_app-db_1 2>/dev/null
        sudo docker container stop "${container_name}"_bloodhound_1 2>/dev/null
    fi
    echo -e ""
fi

if [ "${clean_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        echo -e "${PURPLE}[BloodHoundAnalyzer CLEAN]${NC} Only available for BloodHoundCE"
    else
        cd "${tools_dir}"/bloodhound-automation/ || exit
        echo -e "${GREEN}[BloodHoundAnalyzer CLEAN]${NC} Deleting Docker containers and project file"
        sudo python3 bloodhound-automation.py delete "${domain}" 2>/dev/null
        cd "${current_dir}" || exit
    fi
    echo -e ""
fi
