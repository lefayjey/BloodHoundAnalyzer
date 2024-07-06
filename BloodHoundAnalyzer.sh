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
modules=""
list_bool=false
start_bool=false
run_bool=false
collect_bool=false
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
      ${BLUE}BloodHoundAnalyzer: ${CYAN}version 0.2 ${NC}
      https://github.com/lefayjey/BloodHoundAnalyzer
      ${BLUE}Author: ${CYAN}lefayjey${NC}
"
}

print_help() {
    print_banner
    echo -e "${YELLOW}Parameters${NC}"
    echo -e "-d/--domain DOMAIN          Specify the AD domain to analyze (required for BloodHoundCE and for Collection)."
    echo -e "-u/--username               Username (required for Collection only)."
    echo -e "-p/--password               Password - NTLM authentication (required for Collection only)."
    echo -e "-H/--hash                   LM:NT - NTLM authentication (required for Collection only)."
    echo -e "-K/--kerb                   Location to Kerberos ticket './krb5cc_ticket' - Kerberos authentication (required for Collection only)."
    echo -e "-A/--aes                    AES Key - Kerberos authentication (required for Collection only)."
    echo -e "--dc                        IP Address of Target Domain Controller (required for Collection only)."
    echo -e "-o/--output OUTPUT_DIR      Specify the directory where analysis results will be saved. Defaults to the current directory."
    echo -e "-D/--data DATA_PATH         Specify the path to the BloodHound ZIP file to import"
    echo -e "-M/--module MODULES         Comma separated modules to execute between: collect, list, start, run, import, analyze, stop, clean"
    echo -e "                                 ${YELLOW}collect${NC}: Run bloodHound-python to collect Active Directory data."
    echo -e "                                 ${YELLOW}list${NC}: List available projects (only for BloodHoundCE)."
    echo -e "                                 ${YELLOW}start${NC}: Start BloodHoundCE containers or neo4j."
    echo -e "                                 ${YELLOW}run${NC}: Run BloodHound GUI or Firefox with BloodHoundCE webpage."
    echo -e "                                 ${YELLOW}import${NC}: Import BloodHound data into the neo4j database."
    echo -e "                                 ${YELLOW}analyze${NC}: Run analysis tools (AD-miner, GoodHound, Ransomulator, PlumHound) on the imported data."
    echo -e "                                 ${YELLOW}stop${NC}: Stop BloodHoundCE containers or neo4j."
    echo -e "                                 ${YELLOW}clean${NC}: Stop and delete BloodHoundCE containers (only for BloodHoundCE)."
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
    -u | --username)
        username="${2}"
        shift
        ;;
    -p | --password)
        creds="-p '${2}' --auth-method ntlm"
        shift
        ;;
    -H | --hash)
        creds="--hashes '${2}' --auth-method ntlm"
        shift
        ;;
    -K | --kerb)
        export KRB5CCNAME="${2}"
        creds="-k -no-pass -p '' --auth-method kerberos"
        shift
        ;;
    -A | --aes)
        creds="-aesKey ${2} --auth-method kerberos"
        shift
        ;;
    --dc)
        dc="${2}"
        shift
        ;;
    -o | --output)
        output_dir="$(realpath "${2}")"
        shift
        ;;
    -M | --modules)
        modules="${2}"
        shift
        ;;
    -D | --data)
        bhd_data="$(realpath "${2}")"
        shift
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

if [ -z "${modules}" ]; then
    echo -e "${RED}[BloodHoundAnalyzer]${NC} Please specify one or more of the following modules: collect, list, start, run, import, analyze, stop, clean"
    exit 1
fi

for m in ${modules//,/ }; do
    case $m in
    collect)
        if [ -z "${domain}" ] || [ -z "${username}" ] || [ -z "${creds}" ] || [ -z "${dc}" ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain, DC IP, username or credentials not specified"
            exit 1
        fi
        collect_bool=true
        ;;
    list)
        list_bool=true
        ;;
    start)
        if [ -z "${domain}" ] && [ "${bhdce_bool}" == true ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain not specified"
            exit 1
        fi
        start_bool=true
        ;;
    run)
        start_bool=true
        run_bool=true
        ;;
    import)
        if [ -z "${domain}" ] && [ "${bhdce_bool}" == true ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain not specified"
            exit 1
        fi
        if [ -z "${bhd_data}" ] && [ "${collect_bool}" == false ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} BloodHound zip file not specified"
            exit 1
        fi
        if [ -z "${neo4j_pass}" ] && [ "${bhdce_bool}" == false ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Neo4j password not specified"
            exit 1
        fi
        import_bool=true
        start_bool=true
        ;;
    analyze)
        if [ -z "${domain}" ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain not specified"
            exit 1
        fi
        if [ -z "${neo4j_pass}" ] && [ "${bhdce_bool}" == false ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Neo4j password not specified"
            exit 1
        fi
        analyze_bool=true
        start_bool=true
        ;;
    stop)
        if [ -z "${domain}" ] && [ "${bhdce_bool}" == true ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain not specified"
            exit 1
        fi
        stop_bool=true
        ;;
    clean)
        if [ -z "${domain}" ] && [ "${bhdce_bool}" == true ]; then
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain not specified"
            exit 1
        fi
        clean_bool=true
        stop_bool=true
        ;;
    *)
        echo -e "${RED}[-] Unknown module $m... ${NC}"
        exit 1
        ;;
    esac
done

mkdir -p "${output_dir}"

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
    bolt_port_open=$(
        nc -z 127.0.0.1 7687
        echo $?
    )
    neo4j_port_open=$(
        nc -z 127.0.0.1 7474
        echo $?
    )
    web_port_open=$(
        nc -z 127.0.0.1 7080
        echo $?
    )
    if [ "${bolt_port_open}" == "0" ] || [ "${neo4j_port_open}" == "0" ] || [ "${web_port_open}" == "0" ]; then
        echo -e "${YELLOW}[BloodHoundAnalyzer START]${NC} Warning! neo4j already running. Press Enter to continue..."
        read -rp "" </dev/tty
    fi
    if [ "${bhdce_bool}" == false ]; then
        echo -e "${GREEN}[BloodHoundAnalyzer START]${NC} Starting neo4j"
        sudo neo4j start 2>&1 &
        sleep 2
    else
        cd "${tools_dir}"/bloodhound-automation/ || exit
        echo -e "${GREEN}[BloodHoundAnalyzer START]${NC} Deploying BloodHound containers"
        sudo python3 bloodhound-automation.py start -bp "${bolt_port}" -np "${neo4j_port}" -wp "${web_port}" "${domain}" 2>/dev/null
        cd "${current_dir}" || exit
    fi
    echo -e ""
fi

if [ "${run_bool}" == true ]; then
    if [ "${bhdce_bool}" == false ]; then
        echo -e "${GREEN}[BloodHoundAnalyzer RUN]${NC} Running BloodHound"
        bloodhound --no-sandbox >/dev/null 2>&1 &
    else
        sleep 3
        echo -e "${GREEN}[BloodHoundAnalyzer RUN]${NC} Running Firefox"
        firefox-esr http://127.0.0.1:"${web_port}" >/dev/null 2>&1 &
    fi
    echo -e ""
fi

if [ "${collect_bool}" == true ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer COLLECT]${NC} Running BloodHound Collection"
    cd "${output_dir}" || exit
    if [ "${bhdce_bool}" == false ]; then
        eval bloodhound-python -d "${domain}" -u "${username}\\@${domain}" "${creds}" -c all,LoggedOn -ns "${dc}" --dns-timeout 5 --dns-tcp --zip | tee "${output_dir}/bloodhound_output_${domain}.txt"
    else
        eval bloodhound-python_ce -d "${domain}" "-u ${username}\\@${domain}" "${creds}" -c all,LoggedOn -ns "${dc}" --dns-timeout 5 --dns-tcp --zip | tee "${output_dir}/bloodhoundce_output_${domain}.txt"
    fi
    bhd_data_new="$(find "${output_dir}" -type f -name '*_bloodhound.zip' -print -quit)"
    if [ -n "${bhd_data_new}" ]; then
        if [ "${import_bool}" == true ]; then
            echo -e "${GREEN}[BloodHoundAnalyzer COLLECT]${NC} Choosing collected BloodHound Data"
            bhd_data="${bhd_data_new}"
        else
            echo -e "${GREEN}[BloodHoundAnalyzer COLLECT]${NC} BloodHound Data collected successfully"
        fi
    else
        echo -e "${GREEN}[BloodHoundAnalyzer COLLECT]${NC} Error collecting BloodHound Data"
    fi
    cd "${current_dir}" || exit
    echo -e ""
fi

if [ "${import_bool}" == true ]; then
    if [ -n "${bhd_data}" ]; then
        if [ "${bhdce_bool}" == false ]; then
            echo -e "${GREEN}[BloodHoundAnalyzer IMPORT]${NC} Importing data"
            bloodhound-import -du "${neo4j_user}" -dp "${neo4j_pass}" "${bhd_data}"
        else
            cd "${tools_dir}"/bloodhound-automation/ || exit
            echo -e "${GREEN}[BloodHoundAnalyzer IMPORT]${NC} Importing data"
            sudo python3 bloodhound-automation.py data -z "${bhd_data}" "${domain}"
            cd "${current_dir}" || exit
        fi
    else
        echo -e "${RED}[BloodHoundAnalyzer IMPORT]${NC} BloodHound ZIP file not found"
        exit 1
    fi
    echo -e ""
fi

if [ "${analyze_bool}" == true ]; then

    cd "${output_dir}" || exit

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running AD-miner"
    AD-miner -cf ADMinerReport"_${domain}" -b bolt://127.0.0.1:"${bolt_port}" -u "${neo4j_user}" -p "${neo4j_pass}" --cluster 127.0.0.1:"${bolt_port}":32
    rm -rf "${output_dir}"/cache_neo4j 2>/dev/null
    mv render_ADMinerReport"_${domain}" ADMinerReport"_${domain}"
    echo -e ""

    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running GoodHound"
    mkdir -p "${output_dir}/GoodHound_${domain}"
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
    mkdir -p "${output_dir}/PlumHound_${domain}"
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

echo -e "${BLUE}[BloodHoundAnalyzer]${NC} All modules complete!"
