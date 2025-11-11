#!/bin/bash
# Title: BloodHoundAnalyzer
# Author: lefayjey

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
PURPLE='\033[1;35m'
NC='\033[0m'

# Configuration
tools_dir="/opt/BA_tools"
bloodhound_cli="${tools_dir}/bloodhound-cli"
current_dir=$(pwd)
output_dir="/opt/BA_output"
python3="${tools_dir}/.venv/bin/python3"

# Ports
bolt_port=7687
neo4j_port=7474
web_port=7080

# API configuration
admin_user="admin"
admin_pass=""
jwt_token=""
bh_api_url="http://127.0.0.1:${web_port}"
custom_password="BloodHound2025!@"
neo4j_password="bloodhoundcommunityedition"

# User inputs
domain=""
modules=""
bhd_data=""

# Module flags
list_bool=false
start_bool=false
collect_bool=false
import_bool=false
analyze_bool=false
stop_bool=false
clean_bool=false

print_banner() {
    echo -e "
         ___ _                 _                             _   _               _                    
        / __\ | ___   ___   __| | /\  /\___  _   _ _ __   __| | /_\  _ __   __ _| |_   _ _______ _ __ 
       /__\// |/ _ \ / _ \ / _' |/ /_/ / _ \| | | | '_ \ / _' |//_\\| '_ \ / _' | | | | |_  / _ \ '__|
      / \/  \ | (_) | (_) | (_| / __  / (_) | |_| | | | | (_| /  _  \ | | | (_| | | |_| |/ /  __/ |   
      \_____/_|\___/ \___/ \__,_\/ /_/ \___/ \__,_|_| |_|\__,_\_/ \_/_| |_|\__,_|_|\__, /___\___|_|   
                                                                                   |___/              
      ${BLUE}BloodHoundAnalyzer: ${CYAN}version 1.1 ${NC}
      https://github.com/lefayjey/BloodHoundAnalyzer
      ${BLUE}Author: ${CYAN}lefayjey${NC}
"
}

print_help() {
    print_banner
    echo -e "${YELLOW}Parameters${NC}"
    echo -e "-d/--domain DOMAIN          Specify the AD domain to analyze (required for BloodHound CE)."
    echo -e "                            Containers will be named: <domain>-graph-db-1, <domain>-app-db-1, <domain>-bloodhound-1"
    echo -e "-u/--username               Username (required for Collection only)."
    echo -e "-p/--password               Password - NTLM authentication (required for Collection only)."
    echo -e "-H/--hash                   LM:NT - NTLM authentication (required for Collection only)."
    echo -e "-K/--kerb                   Location to Kerberos ticket './krb5cc_ticket' - Kerberos authentication (required for Collection only)."
    echo -e "-A/--aes                    AES Key - Kerberos authentication (required for Collection only)."
    echo -e "--dc                        IP Address of Target Domain Controller (required for Collection only)."
    echo -e "-o/--output OUTPUT_DIR      Specify the directory where analysis results will be saved."
    echo -e "-D/--data DATA_PATH         Specify the path to BloodHound data (accepts .zip file, .json file, or folder containing JSON files)"
    echo -e "-M/--module MODULES         Comma separated modules to execute between: list, start, import, analyze, stop, clean"
    echo -e "  ${YELLOW}collect${NC}:  Run bloodHound-ce to collect Active Directory data."
    echo -e "  ${YELLOW}list${NC}:     List deployed BloodHound projects and their containers."
    echo -e "  ${YELLOW}start${NC}:    Start BloodHound CE containers for the specified domain (persists containers/volumes)."
    echo -e "  ${YELLOW}import${NC}:   Import BloodHound data. Automatically starts containers if not running."
    echo -e "  ${YELLOW}analyze${NC}:  Run analysis tools (AD-miner, GoodHound, Ransomulator, PlumHound) on imported data."
    echo -e "  ${YELLOW}stop${NC}:     Stop BloodHound CE containers for the specified domain (preserves volumes)."
    echo -e "  ${YELLOW}clean${NC}:    Remove BloodHound CE containers, volumes, and project data for the specified domain."
    echo -e "--bolt-port PORT            Specify neo4j bolt port (default: 7687)"
    echo -e "--neo4j-port PORT           Specify neo4j HTTP port (default: 7474)"
    echo -e "--web-port PORT             Specify BloodHound web port (default: 7080)"
    echo -e "-h/--help                   Display the help message."
    echo -e ""
}

# ==================
# ARGUMENT PARSING
# ==================

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
        --bolt-port)
            bolt_port="${2}"
            shift
            ;;
        --neo4j-port)
            neo4j_port="${2}"
            shift
            ;;
        --web-port)
            web_port="${2}"
            bh_api_url="http://127.0.0.1:${web_port}"
            shift
            ;;
        -h | --help)
            print_help
            exit
            ;;
        *)
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Unknown option: ${1}"
            echo -e "Use: -h for help"
            exit 1
            ;;
    esac
    shift
done
set -- "${args[@]}"


# ====================
# SYSTEM VALIDATION
# ====================

# Check Docker installation and daemon
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} Docker is not installed"
        echo -e "${YELLOW}[INFO]${NC} Install Docker Desktop: https://www.docker.com/products/docker-desktop"
        return 1
    fi
    
    if ! docker ps &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} Docker daemon is not running"
        echo -e "${YELLOW}[INFO]${NC} Please start Docker Desktop"
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} Docker Compose is not available"
        echo -e "${YELLOW}[INFO]${NC} Docker Compose is included in Docker Desktop"
        return 1
    fi
    
    return 0
}

# Check port availability
check_neo4j_ports() {
    echo -e "${CYAN}[CHECK]${NC} Checking port availability..."
    
    # Run port check once and store result
    port_output=$(netstat -tuln 2>/dev/null || ss -tuln 2>/dev/null)
    ports_in_use=false
    
    if echo "$port_output" | grep -q ":${bolt_port} "; then
        echo -e "${YELLOW}[CHECK]${NC} Port ${bolt_port} (Neo4j Bolt) is already in use"
        ports_in_use=true
    fi
    
    if echo "$port_output" | grep -q ":${neo4j_port} "; then
        echo -e "${YELLOW}[CHECK]${NC} Port ${neo4j_port} (Neo4j HTTP) is already in use"
        ports_in_use=true
    fi
    
    if echo "$port_output" | grep -q ":${web_port} "; then
        echo -e "${YELLOW}[CHECK]${NC} Port ${web_port} (BloodHound Web) is already in use"
        ports_in_use=true
    fi
    
    if [ "$ports_in_use" = true ]; then
        echo -e "${YELLOW}[CHECK]${NC} Some ports are in use by other services"
        return 1
    else
        echo -e "${GREEN}[CHECK]${NC} All required ports are available"
        return 0
    fi
}

# ===============
# API FUNCTIONS
# ===============

# Login and get JWT token
bh_api_login() {
    username=$1
    password=$2
    
    echo -e "${CYAN}[API]${NC} Logging in as ${username}..."
    
    response=$(curl -s -X POST "${bh_api_url}/api/v2/login" \
        -H "Content-Type: application/json" \
        -d "{\"login_method\":\"secret\",\"secret\":\"${password}\",\"username\":\"${username}\"}")
    
    jwt_token=$(echo "$response" | grep -o '"session_token":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$jwt_token" ]; then
        echo -e "${RED}[API]${NC} Login failed"
        return 1
    fi
    
    echo -e "${GREEN}[API]${NC} Login successful"
    return 0
}

# Reset admin password to standard
reset_admin_password() {
    container=$1
    
    echo -e "${CYAN}[START]${NC} Configuring admin password..."
    
    # Get initial password from logs
    echo -e "${CYAN}[START]${NC} Retrieving initial password from container..."
    initial_pass=$(docker logs "$container" 2>&1 | grep -i "Initial Password Set To:" | sed 's/.*Initial Password Set To:[[:space:]]*//; s/[[:space:]]*#[[:space:]]*$//')
    
    if [ -z "$initial_pass" ]; then
        echo -e "${YELLOW}[START]${NC} Could not retrieve initial password"
        echo -e "${YELLOW}[INFO]${NC} Check manually: docker logs ${container} | grep -i password"
        admin_pass=""
        return 1
    fi
    
    # Login with initial password
    if ! bh_api_login "$admin_user" "$initial_pass"; then
        echo -e "${YELLOW}[START]${NC} Login failed with initial password"
        admin_pass=""
        return 1
    fi
    
    admin_pass="$initial_pass"
    
    # Get user ID
    user_response=$(curl -s -X GET "${bh_api_url}/api/v2/self" \
        -H "Authorization: Bearer ${jwt_token}")
    
    user_id=$(echo "$user_response" | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$user_id" ]; then
        echo -e "${YELLOW}[START]${NC} Failed to get user ID, keeping initial password"
        return 1
    fi
    
    # Reset to standard password
    echo -e "${CYAN}[START]${NC} Resetting to standard password..."
    pwd_response=$(curl -s -w "\n%{http_code}" -X PUT "${bh_api_url}/api/v2/bloodhound-users/${user_id}/secret" \
        -H "Authorization: Bearer ${jwt_token}" \
        -H "Content-Type: application/json" \
        -d "{\"current_secret\":\"${initial_pass}\",\"secret\":\"${custom_password}\",\"needs_password_reset\":false}")
    
    http_code=$(echo "$pwd_response" | tail -n1)
    response_body=$(echo "$pwd_response" | sed '$d')
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "204" ]; then
        echo -e "${GREEN}[START]${NC} Password reset successfully to standard password"
        admin_pass="$custom_password"
        return 0
    else
        echo -e "${YELLOW}[START]${NC} Failed to reset password (HTTP ${http_code}), using initial password"
        return 1
    fi
}

# Upload files to BloodHound
bh_api_upload_files() {
    input_path=$1
    temp_dir=$(mktemp -d)
    json_files=()
    is_zip=false
    
    # Determine input type
    if [ -f "$input_path" ]; then
        if [[ "$input_path" == *.zip ]]; then
            echo -e "${CYAN}[API]${NC} Uploading ZIP file: $(basename "$input_path")..."
            is_zip=true
        elif [[ "$input_path" == *.json ]]; then
            echo -e "${CYAN}[API]${NC} Using single JSON file: $(basename "$input_path")..."
            json_files+=("$input_path")
        else
            echo -e "${RED}[API]${NC} Unsupported file type. Please provide a .zip or .json file"
            rm -rf "$temp_dir"
            return 1
        fi
    elif [ -d "$input_path" ]; then
        echo -e "${CYAN}[API]${NC} Using folder: $input_path..."
        while IFS= read -r -d '' file; do
            json_files+=("$file")
        done < <(find "$input_path" -type f -name "*.json" -print0)
    else
        echo -e "${RED}[API]${NC} Input path does not exist: $input_path"
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ "$is_zip" = false ] && [ ${#json_files[@]} -eq 0 ]; then
        echo -e "${RED}[API]${NC} No JSON files found to upload"
        rm -rf "$temp_dir"
        return 1
    fi
    
    if [ "$is_zip" = false ]; then
        echo -e "${CYAN}[API]${NC} Found ${#json_files[@]} JSON file(s) to upload"
    fi
    
    # Create upload batch
    echo -e "${CYAN}[API]${NC} Creating upload batch..."
    batch_response=$(curl -s -X POST "${bh_api_url}/api/v2/file-upload/start" \
        -H "Authorization: Bearer ${jwt_token}" \
        -H "Content-Type: application/json" \
        -d '{}')
    
    batch_id=$(echo "$batch_response" | grep -o '"id":[0-9]*' | cut -d':' -f2)
    
    if [ -z "$batch_id" ]; then
        echo -e "${RED}[API]${NC} Failed to create upload batch"
        echo -e "${YELLOW}[API]${NC} Response: ${batch_response}"
        rm -rf "$temp_dir"
        return 1
    fi
    
    echo -e "${GREEN}[API]${NC} Upload batch created: ${batch_id}"
    
    upload_count=0
    failed_count=0
    
    # Upload files
    if [ "$is_zip" = true ]; then
        echo -e "${CYAN}[API]${NC} Uploading ZIP file..."
        zip_filename=$(basename "$input_path")
        upload_response=$(curl -s -w "\n%{http_code}" -X POST "${bh_api_url}/api/v2/file-upload/${batch_id}" \
            -H "Authorization: Bearer ${jwt_token}" \
            -H "Content-Type: application/zip" \
            -H "X-File-Upload-Name: ${zip_filename}" \
            --data-binary "@${input_path}")
        
        http_code=$(echo "$upload_response" | tail -n1)
        response_body=$(echo "$upload_response" | sed '$d')
        
        if [ "$http_code" = "202" ] || [ "$http_code" = "200" ]; then
            echo -e "${GREEN}[API]${NC} ZIP file uploaded successfully"
            upload_count=1
        else
            echo -e "${RED}[API]${NC} Failed to upload ZIP file"
            echo -e "${YELLOW}[API]${NC} Response: ${response_body}"
            failed_count=1
        fi
    else
        # Upload JSON files individually
        echo -e "${CYAN}[API]${NC} Uploading JSON files..."
        for json_file in "${json_files[@]}"; do
            if [ -f "$json_file" ]; then
                filename=$(basename "$json_file")
                echo -e "  Uploading: ${filename}"
                
                upload_response=$(curl -s -w "\n%{http_code}" -X POST "${bh_api_url}/api/v2/file-upload/${batch_id}" \
                    -H "Authorization: Bearer ${jwt_token}" \
                    -H "Content-Type: application/json" \
                    --data-binary "@${json_file}")
                
                http_code=$(echo "$upload_response" | tail -n1)
                
                if [ "$http_code" = "202" ] || [ "$http_code" = "200" ]; then
                    upload_count=$((upload_count + 1))
                else
                    failed_count=$((failed_count + 1))
                    response_body=$(echo "$upload_response" | sed '$d')
                    echo -e "${YELLOW}[API]${NC} Failed to upload ${filename} (HTTP ${http_code})"
                    echo -e "${YELLOW}[API]${NC} Response: ${response_body}"
                fi
            fi
        done
        echo ""
    fi
    
    if [ $failed_count -gt 0 ]; then
        echo -e "${YELLOW}[API]${NC} Uploaded ${upload_count} file(s), ${failed_count} failed"
    else
        echo -e "${GREEN}[API]${NC} Uploaded ${upload_count} file(s)"
    fi
    
    # Finalize batch
    echo -e "${CYAN}[API]${NC} Finalizing upload..."
    curl -s -X POST "${bh_api_url}/api/v2/file-upload/${batch_id}/end" \
        -H "Authorization: Bearer ${jwt_token}" > /dev/null
    
    # Wait for ingestion to complete
    echo -e "${CYAN}[API]${NC} Waiting for data ingestion to complete..."
    max_wait=600
    waited=0
    check_interval=5
    
    while [ $waited -lt $max_wait ]; do
        sleep $check_interval
        waited=$((waited + check_interval))
        
        # Check completed tasks for this batch
        response=$(curl -s -X GET "${bh_api_url}/api/v2/file-upload/${batch_id}/completed-tasks" \
            -H "Authorization: Bearer ${jwt_token}")
        
        # Check if we got task data (not null)
        if echo "$response" | grep -q '"data":\['; then
            task_count=$(echo "$response" | grep -o '"id":' | wc -l)
            if [ "$task_count" -gt 0 ]; then
                echo -e "\r${GREEN}[API]${NC} Data ingestion complete! Processed ${task_count} file(s)"
                rm -rf "$temp_dir"
                return 0
            fi
        fi
        
        echo -ne "\r${CYAN}[API]${NC} Ingesting data... ${waited}s elapsed    "
    done
    
    echo -e "\n${YELLOW}[API]${NC} Ingestion still in progress after ${max_wait}s"
    echo -e "${YELLOW}[INFO]${NC} Check BloodHound UI for ingestion status: http://127.0.0.1:${web_port}/ui/administration/file-ingest"
    rm -rf "$temp_dir"
    return 0
}


# Wait for API to be ready
wait_for_api() {
    echo -e "${CYAN}[API]${NC} Waiting for BloodHound API to be ready..."
    
    max_attempts=90
    for i in $(seq 1 $max_attempts); do
        if curl -s -o /dev/null -w "%{http_code}" "${bh_api_url}/api/version" | grep -q "401"; then
            echo -e "\n${GREEN}[API]${NC} BloodHound API is ready!"
            return 0
        fi
        echo -ne "\r  Attempt $i/$max_attempts..."
        sleep 3
    done
    
    echo -e "\n${RED}[ERROR]${NC} API not responding after $((max_attempts * 3))s"
    echo -e "${RED}[ERROR]${NC} BloodHound API failed to start"
    exit 1
}

# ====================
# MODULE VALIDATION
# ====================

if [ -z "${modules}" ]; then
    echo -e "${RED}[BloodHoundAnalyzer]${NC} Please specify one or more modules"
    echo -e "Use: -h for help"
    exit 1
fi

# Parse and validate modules
for m in ${modules//,/ }; do
    case $m in
        list)
            list_bool=true
            ;;
        collect)
            if [ -z "${domain}" ] || [ -z "${username}" ] || [ -z "${creds}" ] || [ -z "${dc}" ]; then
                echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain, DC IP, username or credentials not specified"
                exit 1
            fi
            collect_bool=true
            ;;
        start)
            if [ -z "${domain}" ]; then
                echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain not specified"
                exit 1
            fi
            start_bool=true
            ;;
        import)
            if [ -z "${bhd_data}" ]; then
                echo -e "${RED}[BloodHoundAnalyzer]${NC} BloodHound data not specified (provide .zip, .json, or folder path)"
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
            analyze_bool=true
            start_bool=true
            ;;
        stop)
            if [ -z "${domain}" ]; then
                echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain required for stop operation"
                exit 1
            fi
            stop_bool=true
            ;;
        clean)
            if [ -z "${domain}" ]; then
                echo -e "${RED}[BloodHoundAnalyzer]${NC} Domain required for clean operation"
                exit 1
            fi
            clean_bool=true
            stop_bool=true
            ;;
        *)
            echo -e "${RED}[BloodHoundAnalyzer]${NC} Unknown module: ${m}"
            exit 1
            ;;
    esac
done

# ===================
# MODULE EXECUTION
# ===================

print_banner

# Check if bloodhound-cli exists and is executable
if [ ! -x "$bloodhound_cli" ]; then
    echo -e "${RED}[ERROR]${NC} bloodhound-cli not found or not executable at ${bloodhound_cli}"
    echo -e "${YELLOW}[INFO]${NC} Please run ./install.sh or install from: https://github.com/SpecterOps/BloodHound"
    exit 1
fi

# Set project variables early if domain is provided
if [ -n "${domain}" ]; then
    normalized_domain=$(echo "$domain" | tr '.' '-' | tr '[:upper:]' '[:lower:]')
    proj_dir="${tools_dir}/projects/${domain}"
    proj_out_dir="${output_dir}/${domain}"
else
    # Domain is required for start, import, analyze, stop, clean modules
    if [ "${start_bool}" == true ] || [ "${import_bool}" == true ] || [ "${analyze_bool}" == true ] || [ "${stop_bool}" == true ] || [ "${clean_bool}" == true ]; then
        echo -e "${RED}[ERROR]${NC} Domain is required for this operation"
        echo -e "${YELLOW}[INFO]${NC} Use -d or --domain to specify the domain"
        exit 1
    fi
fi

# List deployed projects
if [ "${list_bool}" == true ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer LIST]${NC} Deployed BloodHound Projects"
    echo ""
    
    if [ ! -d "$tools_dir/projects" ]; then
        echo -e "${YELLOW}[LIST]${NC} No projects directory found"
        echo ""
    else
    
    has_projects=false
    
    for proj in "$tools_dir"/projects/*; do
        if [ -d "$proj" ]; then
            has_projects=true
            proj_domain=$(basename "$proj")
            normalized_domain_local=$(echo "$proj_domain" | tr '.' '-' | tr '[:upper:]' '[:lower:]')
            
            # Check running containers
            running=$(docker ps --filter "name=${normalized_domain_local}" --format "{{.Names}}" 2>/dev/null)
            all_containers=$(docker ps -a --filter "name=${normalized_domain_local}" --format "{{.Names}}" 2>/dev/null)
            
            echo -e "${CYAN}Project: ${proj_domain}${NC}"
            echo -e "  Location: ${proj}"
            
            if [ -n "$running" ]; then
                echo -e "  ${GREEN}Status: RUNNING${NC}"
                echo -e "  Containers:"
                docker ps --filter "name=${normalized_domain_local}" --format "    {{.Names}}: {{.Status}}"
            elif [ -n "$all_containers" ]; then
                echo -e "  ${YELLOW}Status: STOPPED${NC}"
                echo -e "  Containers:"
                docker ps -a --filter "name=${normalized_domain_local}" --format "    {{.Names}}: {{.Status}}"
            else
                echo -e "  ${RED}Status: NO CONTAINERS${NC}"
            fi
            
            # Check volumes
            volumes=$(docker volume ls --filter "name=${normalized_domain_local}" --format "{{.Name}}" 2>/dev/null)
            if [ -n "$volumes" ]; then
                echo -e "  Volumes:"
                echo "$volumes" | while read vol; do
                    echo -e "    ${vol}"
                done
            fi
            
            echo ""
        fi
    done
    
    if [ "$has_projects" = false ]; then
        echo -e "${YELLOW}[LIST]${NC} No BloodHound projects found"
        echo -e "${YELLOW}[LIST]${NC} Start a project with: -d <domain> -M start"
    fi
    
    fi
    echo ""
fi

# Start BloodHound CE containers
if [ "${start_bool}" == true ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer START]${NC} Deploying BloodHound CE for domain: ${domain}"
    
    # Check Docker once
    check_docker || exit 1
    
    # Check if containers are already running
    running=$(docker ps --filter "name=${normalized_domain}" --format "{{.Names}}" 2>/dev/null | wc -l)
    
    if [ "$running" -gt 0 ]; then
        echo -e "${YELLOW}[START]${NC} BloodHound CE containers already running for ${domain}"
        echo -e ""
    else
        # Check port availability
        if ! check_neo4j_ports; then
            echo -e "${YELLOW}[INFO]${NC} Stop other BloodHound instances or use different ports with --bolt-port, --neo4j-port, --web-port"
            exit 1
        else

        # Create project directory
        mkdir -p "${proj_dir}"

        echo ""
        echo -e "${CYAN}[START]${NC} Project directory: ${proj_dir}"
        echo -e "${CYAN}[START]${NC} Container prefix: ${normalized_domain}"
        
        # Download the docker-compose.yml to project directory (overwrite if exists to ensure latest version)
        echo -e "${CYAN}[START]${NC} Downloading docker-compose.yml to ${proj_dir}..."
        cd "$proj_dir" || exit 1
        
        if ! curl -sSL -o "${proj_dir}/docker-compose.yml" "https://raw.githubusercontent.com/SpecterOps/BloodHound/refs/heads/main/examples/docker-compose/docker-compose.yml"; then
            echo -e "${RED}[ERROR]${NC} Failed to download docker-compose.yml (curl error)"
            echo -e "${YELLOW}[INFO]${NC} Check your internet connection and try again"
            cd "$current_dir" || exit 1
            exit 1
        fi
        
        # Verify the file was downloaded
        if [ ! -f "${proj_dir}/docker-compose.yml" ]; then
            echo -e "${RED}[ERROR]${NC} docker-compose.yml not found after download"
            cd "$current_dir" || exit 1
            exit 1
        fi
        
        # Customize docker-compose.yml with domain-specific naming
        echo -e "${CYAN}[START]${NC} Customizing docker-compose.yml for domain ${domain}..."
        
        # Update container names with domain prefix
        sed -i "s/container_name: bloodhound-postgres/container_name: ${normalized_domain}-app-db-1/" "${proj_dir}/docker-compose.yml"
        sed -i "s/container_name: bloodhound-neo4j/container_name: ${normalized_domain}-graph-db-1/" "${proj_dir}/docker-compose.yml"
        sed -i "s/container_name: bloodhound/container_name: ${normalized_domain}-bloodhound-1/" "${proj_dir}/docker-compose.yml"
        
        # Update volume names
        sed -i "s/name: bloodhound_neo4j-data/name: ${normalized_domain}_neo4j-data/" "${proj_dir}/docker-compose.yml"
        sed -i "s/name: bloodhound_postgres-data/name: ${normalized_domain}_postgres-data/" "${proj_dir}/docker-compose.yml"
        
        # Update network name
        sed -i "s/name: bloodhound_network/name: ${normalized_domain}_network/" "${proj_dir}/docker-compose.yml"
        
        # Create .env file with custom ports and compose project name
        cat > "${proj_dir}/.env" << EOF
COMPOSE_PROJECT_NAME=${normalized_domain}
BLOODHOUND_HOST=127.0.0.1
BLOODHOUND_PORT=${web_port}
NEO4J_DB_PORT=${bolt_port}
NEO4J_WEB_PORT=${neo4j_port}
EOF
        
        # Export project name for docker-compose
        export COMPOSE_PROJECT_NAME="$normalized_domain"
        
        echo -e "${CYAN}[START]${NC} Starting Docker containers..."
        # Change to project directory and start containers
        cd "$proj_dir" || exit 1
        "$bloodhound_cli" up -f "${proj_dir}/docker-compose.yml"
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR]${NC} Failed to start containers"
            cd "$current_dir" || exit 1
            exit 1
        fi
        
        cd "$current_dir" || exit 1
        
        # Wait for API and configure admin password
        sleep 5
        wait_for_api
        reset_admin_password "${normalized_domain}-bloodhound-1"
        
        # Display deployment summary
        echo ""
        echo -e "${GREEN}[START]${NC} BloodHound CE deployed successfully for ${domain}!"
        echo ""
        echo -e "${CYAN}[START]${NC} Container Status:"
        docker ps --filter "name=${normalized_domain}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo ""
        echo -e "${CYAN}[START]${NC} Access BloodHound CE at:"
        echo -e "  http://127.0.0.1:${web_port}/ui/login"
        echo -e "  Username: admin"
        if [ -n "$admin_pass" ]; then
            echo -e "  Password: ${admin_pass}"
        else
            echo -e "  Password: Check container logs with: docker logs ${normalized_domain}-bloodhound-1 | grep -i password"
        fi
        echo ""
        fi
    fi
fi

# Collect data
if [ "${collect_bool}" == true ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer COLLECT]${NC} Running BloodHound Collection"
    if [ ! -f "$(which bloodhound-ce-python)" ]; then
        echo -e "${YELLOW}[COLLECT]${NC} bloodhound-ce-python script not found, skipping bloodhound-ce-python collection"
        echo -e "${YELLOW}[INFO]${NC} Run ./install.sh to install bloodhound-ce-python"
    else
        # Create project directory
        mkdir -p "${proj_out_dir}"
        cd "${proj_out_dir}" || exit
        echo -e "${CYAN}[CMD]${NC} bloodhound-ce-python -d \"${domain}\" \"-u ${username}\\@${domain}\" \"${creds}\" -c all,LoggedOn -ns \"${dc}\" --dns-timeout 5 --dns-tcp --zip"
        eval bloodhound-ce-python -d "${domain}" "-u ${username}\\@${domain}" "${creds}" -c all,LoggedOn -ns "${dc}" --dns-timeout 5 --dns-tcp --zip
        bhd_data_new="$(find "${proj_out_dir}" -type f -name '*_bloodhound.zip' -print -quit)"
        if [ -n "${bhd_data_new}" ]; then
            echo -e "${GREEN}[COLLECT]${NC} BloodHound Data collected successfully"
        else
            echo -e "${RED}[COLLECT]${NC} Error collecting BloodHound Data"
        fi
        cd "${current_dir}" || exit
        echo -e ""
    fi
fi

# Import data
if [ "${import_bool}" == true ]; then
    if [ -z "${bhd_data}" ]; then
        echo -e "${RED}[IMPORT]${NC} BloodHound data path not provided"
        exit 1
    fi
    
    echo -e "${GREEN}[BloodHoundAnalyzer IMPORT]${NC} Importing data from ${bhd_data}"
    sleep 3
    
    echo -e "${CYAN}[IMPORT]${NC} Authenticating with BloodHound API..."
    
    # Try custom password first
    if bh_api_login "$admin_user" "$custom_password"; then
        admin_pass="$custom_password"
    # Try stored password
    elif [ -n "$admin_pass" ] && bh_api_login "$admin_user" "$admin_pass"; then
        :
    # Fallback: get initial password
    else
        echo -e "${YELLOW}[IMPORT]${NC} Login failed, retrieving initial password from container..."
        container="${normalized_domain}-bloodhound-1"
        
        initial_pass=$(docker logs "$container" 2>&1 | grep -i "Initial Password Set To:" | sed 's/.*Initial Password Set To:[[:space:]]*//; s/[[:space:]]*#[[:space:]]*$//')
        
        if [ -z "$initial_pass" ] || ! bh_api_login "$admin_user" "$initial_pass"; then
            echo -e "${RED}[IMPORT]${NC} Authentication failed"
            echo -e "${YELLOW}[INFO]${NC} Manual check: docker logs ${container} | grep -i password"
            exit 1
        fi
        admin_pass="$initial_pass"
    fi
    
    bh_api_upload_files "$bhd_data"
    echo -e ""
fi

# Run analysis tools
if [ "${analyze_bool}" == true ]; then

    # Validate Python venv exists
    if [ ! -x "${python3}" ]; then
        echo -e "${RED}[ANALYZE]${NC} Python virtual environment not found at ${python3}"
        echo -e "${YELLOW}[INFO]${NC} Please run ./install.sh to set up the environment"
        exit 1
    fi

    mkdir -p "${proj_out_dir}"
    cd "${proj_out_dir}" || exit
    
    echo -e "${GREEN}[BloodHoundAnalyzer ANALYZE]${NC} Running analysis tools for domain: ${domain}"
    echo -e "${CYAN}[ANALYZE]${NC} BloodHound CE web interface: http://127.0.0.1:${web_port}/ui/login"
    echo -e ""
    
    # AD-miner
    echo -e "${GREEN}[ANALYZE]${NC} Running AD-miner"
    if [ ! -f "$(which AD-miner)" ]; then
        echo -e "${YELLOW}[ANALYZE]${NC} AD-miner script not found, skipping AD-miner analysis"
        echo -e "${YELLOW}[INFO]${NC} Run ./install.sh to install AD-miner"
        echo -e ""
    else
        echo -e "${CYAN}[CMD]${NC} AD-miner -cf ADMinerReport_${domain} -b bolt://127.0.0.1:${bolt_port} -u neo4j -p ${neo4j_password} --cluster 127.0.0.1:${bolt_port}:32"
        AD-miner -cf ADMinerReport"_${domain}" -b bolt://127.0.0.1:"${bolt_port}" -u neo4j -p "${neo4j_password}" --cluster 127.0.0.1:"${bolt_port}":32
        rm -rf "${proj_out_dir}"/cache_neo4j 2>/dev/null
        mv render_ADMinerReport"_${domain}" ADMinerReport"_${domain}" 2>/dev/null
        echo -e ""
    fi

    # GoodHound
    echo -e "${GREEN}[ANALYZE]${NC} Running GoodHound"
    if [ ! -f "$(which GoodHound)" ]; then
        echo -e "${YELLOW}[ANALYZE]${NC} GoodHound script not found, skipping GoodHound analysis"
        echo -e "${YELLOW}[INFO]${NC} Run ./install.sh to install GoodHound"
        echo -e ""
    else
        mkdir -p "${proj_out_dir}/GoodHound_${domain}"
        echo -e "${CYAN}[CMD]${NC} GoodHound -s bolt://127.0.0.1:${bolt_port} -u neo4j -p ${neo4j_password} -d ${proj_out_dir}/GoodHound_${domain} --db-skip --patch41"
        GoodHound -s bolt://127.0.0.1:"${bolt_port}" -u neo4j -p "${neo4j_password}" -d "${proj_out_dir}/GoodHound_${domain}" --db-skip --patch41
        echo -e ""
    fi

    # BloodHoundQuickWin
    echo -e "${GREEN}[ANALYZE]${NC} Running BloodHoundQuickWin"
    if [ ! -f "${tools_dir}/bhqc.py" ]; then
        echo -e "${YELLOW}[ANALYZE]${NC} BloodHoundQuickWin script not found, skipping BloodHoundQuickWin analysis"
        echo -e "${YELLOW}[INFO]${NC} Run ./install.sh to install BloodHoundQuickWin"
        echo -e ""
    else
        echo "[*] Running BloodHound QuickWin..."
        echo -e "${CYAN}[CMD]${NC} ${python3} ${tools_dir}/bhqc.py -u neo4j -p ${neo4j_password} -d ${domain} --heavy -b bolt://127.0.0.1:${bolt_port}"
        ${python3} "${tools_dir}/bhqc.py" -u neo4j -p "${neo4j_password}" -d "${domain}" --heavy -b bolt://127.0.0.1:"${bolt_port}" | tee "${proj_out_dir}/bhqc_${domain}.txt"
        echo -e ""
    fi

    # Ransomulator
    echo -e "${GREEN}[ANALYZE]${NC} Running Ransomulator"
    if [ ! -f "${tools_dir}/ransomulator.py" ]; then
        echo -e "${YELLOW}[ANALYZE]${NC} Ransomulator directoscriptry not found, skipping Ransomulator analysis"
        echo -e "${YELLOW}[INFO]${NC} Run ./install.sh to install Ransomulator"
        echo -e ""
    else
        echo -e "${CYAN}[CMD]${NC} ${python3} ${tools_dir}/ransomulator.py -l bolt://127.0.0.1:${bolt_port} -u neo4j -p ${neo4j_password} -w 12 -o ${proj_out_dir}/ransomulator_${domain}.csv"
        ${python3} "${tools_dir}/ransomulator.py" -l bolt://127.0.0.1:"${bolt_port}" -u neo4j -p "${neo4j_password}" -w 12 -o"${proj_out_dir}/ransomulator_${domain}.csv"
        echo -e ""
    fi

    # PlumHound
    echo -e "${GREEN}[ANALYZE]${NC} Running PlumHound"
    if [ ! -d "${tools_dir}/PlumHound-master" ]; then
        echo -e "${YELLOW}[ANALYZE]${NC} PlumHound directory not found, skipping PlumHound analysis"
        echo -e "${YELLOW}[INFO]${NC} Run ./install.sh to install PlumHound"
        echo -e ""
    else
        mkdir -p "${proj_out_dir}/PlumHound_${domain}"
        cd "${tools_dir}/PlumHound-master" || exit
        echo -e "${CYAN}[CMD]${NC} ${python3} ${tools_dir}/PlumHound-master/PlumHound.py -x tasks/default.tasks -s bolt://127.0.0.1:${bolt_port} -u neo4j -p ${neo4j_password} -v 0 --op ${proj_out_dir}/PlumHound_${domain}"
        ${python3} ${tools_dir}/PlumHound-master/PlumHound.py -x tasks/default.tasks -s "bolt://127.0.0.1:${bolt_port}" -u neo4j -p "${neo4j_password}" -v 0 --op "${proj_out_dir}/PlumHound_${domain}"
        echo -e "${CYAN}[CMD]${NC} ${python3} ${tools_dir}/PlumHound-master/PlumHound.py -bp short 5 -s bolt://127.0.0.1:${bolt_port} -u neo4j -p ${neo4j_password} --op ${proj_out_dir}/PlumHound_${domain}"
        ${python3} ${tools_dir}/PlumHound-master/PlumHound.py -bp short 5 -s "bolt://127.0.0.1:${bolt_port}" -u neo4j -p "${neo4j_password}" --op "${proj_out_dir}/PlumHound_${domain}"
        echo -e "${CYAN}[CMD]${NC} ${python3} ${tools_dir}/PlumHound-master/PlumHound.py -bp all 5 -s bolt://127.0.0.1:${bolt_port} -u neo4j -p ${neo4j_password} --op ${proj_out_dir}/PlumHound_${domain}"
        ${python3} ${tools_dir}/PlumHound-master/PlumHound.py -bp all 5 -s "bolt://127.0.0.1:${bolt_port}" -u neo4j -p "${neo4j_password}" --op "${proj_out_dir}/PlumHound_${domain}"
        echo -e ""
    fi

    # ad-recon
    if [ ! -d "${tools_dir}/ad-recon-main" ]; then
        echo -e "${YELLOW}[ANALYZE]${NC} ad-recon directory not found, skipping ad-recon analysis"
        echo -e "${YELLOW}[INFO]${NC} Run ./install.sh to install ad-recon"
        echo -e ""
    else
        echo -e "${GREEN}[ANALYZE]${NC} Running ad-recon"
        mkdir -p "${proj_out_dir}/ad-recon_${domain}"
        cd "${tools_dir}/ad-recon-main" || exit
        echo -e "${CYAN}[CMD]${NC} ${python3} ${tools_dir}/ad-recon-main/ad_recon.py --pathing --transitive -U bolt://127.0.0.1:${bolt_port} -u neo4j -p ${neo4j_password} -d neo4j"
        ${python3} ${tools_dir}/ad-recon-main/ad_recon.py --pathing --transitive -U "bolt://127.0.0.1:${bolt_port}" -u neo4j -p "${neo4j_password}" -d neo4j
        mv "${tools_dir}/ad-recon-main/output/"* "${proj_out_dir}/ad-recon_${domain}/"
        echo -e ""
    fi

    cd "${current_dir}" || exit
fi

# Stop containers
if [ "${stop_bool}" == true ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer STOP]${NC} Stopping BloodHound CE for domain: ${domain}"
    
    if [ ! -d "${proj_dir}" ]; then
        echo -e "${RED}[ERROR]${NC} Project directory not found: ${proj_dir}"
        echo -e "${YELLOW}[INFO]${NC} BloodHound CE may not have been deployed for this domain"
        echo -e "${YELLOW}[INFO]${NC} Use '-M list' to see deployed projects"
        exit 1
    fi
    
    if [ ! -f "${proj_dir}/docker-compose.yml" ]; then
        echo -e "${RED}[ERROR]${NC} docker-compose.yml not found in ${proj_dir}"
        echo -e "${YELLOW}[INFO]${NC} Project may be corrupted or incomplete"
        exit 1
    fi
    
    containers=$(docker ps --filter "name=${normalized_domain}" --format "{{.Names}}")
    
    if [ -z "$containers" ]; then
        echo -e "${YELLOW}[STOP]${NC} No running BloodHound CE containers found for ${domain}"
    else
        cd "$proj_dir" || {
            echo -e "${RED}[ERROR]${NC} Failed to change to project directory: ${proj_dir}"
            exit 1
        }
        export COMPOSE_PROJECT_NAME="$normalized_domain"
        
        echo -e "${CYAN}[STOP]${NC} Stopping containers..."
        "$bloodhound_cli" down -f "${proj_dir}/docker-compose.yml"
        
        cd "$current_dir" || exit 1
        
        echo -e "${GREEN}[STOP]${NC} BloodHound CE stopped for ${domain}"
        echo -e "${YELLOW}[INFO]${NC} Volumes preserved for restart"
    fi
    echo ""
fi

# Clean up deployment
if [ "${clean_bool}" == true ]; then
    echo -e "${GREEN}[BloodHoundAnalyzer CLEAN]${NC} Removing BloodHound CE for domain: ${domain}"
    echo -e "${YELLOW}[CLEAN]${NC} This will remove containers, volumes, and project data for ${domain}"
    
    read -p "Are you sure? (y/n) " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[CLEAN]${NC} Operation cancelled"
    else
        # Remove any remaining containers (in case stop didn't run or failed)
        containers=$(docker ps -a --filter "name=${normalized_domain}" --format "{{.Names}}")
        if [ -n "$containers" ]; then
            echo -e "${CYAN}[CLEAN]${NC} Removing containers..."
            for container in $containers; do
                docker rm -f "$container" 2>/dev/null
            done
        fi
        
        # Remove all volumes with normalized domain name prefix
        echo -e "${CYAN}[CLEAN]${NC} Removing volumes..."
        volumes=$(docker volume ls --format "{{.Name}}" | grep "${normalized_domain}")
        if [ -n "$volumes" ]; then
            for volume in $volumes; do
                echo -e "${CYAN}[CLEAN]${NC} Removing volume: ${volume}..."
                docker volume rm -f "$volume" 2>/dev/null
            done
        fi
        
        # Remove project directory
        if [ -d "$proj_dir" ]; then
            echo -e "${CYAN}[CLEAN]${NC} Removing project directory..."
            rm -rf "$proj_dir"
        fi
        
        echo -e "${GREEN}[CLEAN]${NC} BloodHound CE removed for ${domain}"
    fi
    echo ""
fi

# Execution complete
echo -e "${BLUE}[BloodHoundAnalyzer]${NC} Execution complete!"
echo ""
