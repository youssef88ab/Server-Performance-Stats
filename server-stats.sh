#!/bin/bash

# ==============================================================================
#                      🚀  SERVER DASHBOARD 🚀
#
# Description: A script to display a comprehensive overview of the server's
#              status, including resource usage, system info, and services.
# Author:      Youssef Abou ELjihad
# Version:     1.0
# ==============================================================================


# --- Configuration ---
# Services to check. Add or remove service names here.
SERVICES_TO_CHECK=("nginx" "mysql" "sshd")

# Resource usage thresholds for color-coding.
CPU_WARN_THRESHOLD=70
MEM_WARN_THRESHOLD=70
CPU_CRIT_THRESHOLD=90
MEM_CRIT_THRESHOLD=90


# --- Colors and Styles ---
C_OFF='\033[0m'
C_BLACK='\033[0;30m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_MAGENTA='\033[0;35m'
C_CYAN='\033[0;36m'
C_WHITE='\033[0;37m'
S_BOLD='\033[1m'
S_UNDERLINE='\033[4m'


# --- Helper Functions ---

# Prints a formatted section header.
# Arguments: $1 = Header Text
print_header() {
    printf "\n${S_BOLD}${C_CYAN}❖ %s${C_OFF}\n" "$1"
    printf "${C_BLUE}%.s─${C_OFF}" $(seq 1 $((${#1}+4)))
    printf "\n"
}

# Determines the color for a value based on warning and critical thresholds.
# Arguments: $1 = Value, $2 = Warning Threshold, $3 = Critical Threshold
get_color() {
    local value=$(printf "%.0f" "$1")
    local warn=$2
    local crit=$3

    if (( value >= crit )); then
        echo -en "${C_RED}"
    elif (( value >= warn )); then
        echo -en "${C_YELLOW}"
    else
        echo -en "${C_GREEN}"
    fi
}


# --- Information Gathering Functions ---

show_system_info() {
    print_header "System Information"
    os_version=$(grep "PRETTY_NAME" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    kernel_version=$(uname -r)
    uptime_val=$(uptime -p)
    cpu_cores=$(nproc)
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)

    printf "%-20s : %s\n" "Operating System" "$os_version"
    printf "%-20s : %s\n" "Kernel Version" "$kernel_version"
    printf "%-20s : %s\n" "Uptime" "${uptime_val}"
    printf "%-20s : %s\n" "CPU Cores" "$cpu_cores"
    printf "%-20s : %s\n" "Load Average" "$load_avg"
}

show_resource_usage() {
    print_header "Resource Usage"
    
    # CPU Usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    cpu_color=$(get_color "$cpu_usage" $CPU_WARN_THRESHOLD $CPU_CRIT_THRESHOLD)
    printf "%-20s : ${cpu_color}${S_BOLD}%.2f%%${C_OFF}\n" "CPU Usage" "$cpu_usage"

    # Memory Usage
    mem_info=$(free -m | awk 'NR==2{printf "%s %s", $2, $3}')
    mem_total=$(echo "$mem_info" | awk '{print $1}')
    mem_used=$(echo "$mem_info" | awk '{print $2}')
    mem_percent=$(awk "BEGIN {printf \"%.2f\", ($mem_used/$mem_total)*100}")
    mem_color=$(get_color "$mem_percent" $MEM_WARN_THRESHOLD $MEM_CRIT_THRESHOLD)
    printf "%-20s : ${mem_color}${S_BOLD}%sMiB / %sMiB (%.2f%%)${C_OFF}\n" "Memory Usage" "$mem_used" "$mem_total" "$mem_percent"

   # Disk Usage (formatted as a table)
    printf "%-25s :\n" "Disk Usage"
    printf "  ${UNDERLINE}%-20s %-8s %-8s %-8s${NC}\n" "Filesystem" "Total" "Used" "Use%"
    df -h | grep '^/dev/' | awk -v NC='\033[0m' '{
        usage_percent=int(substr($5, 1, length($5)-1));
        if (usage_percent > 90) color="\033[0;31m";
        else if (usage_percent > 75) color="\033[1;33m";
        else color="\033[0;32m";
        printf color "  %-20s %-8s %-8s %-8s" NC "\n", $1, $2, $3, $5;
    }'
}

show_top_processes() {
    print_header "Top 5 Processes by CPU & Memory"
    
    # By CPU
    printf "${S_UNDERLINE}By CPU Usage:${C_OFF}\n"
    printf "%-8s %-25s %-8s %-8s\n" "PID" "COMMAND" "%CPU" "%MEM"
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6 | tail -n 5 | awk '{
        printf "%-8s %-25s %-8.2f %-8.2f\n", $1, $2, $3, $4
    }'

    # By Memory
    printf "\n${S_UNDERLINE}By Memory Usage:${C_OFF}\n"
    printf "%-8s %-25s %-8s %-8s\n" "PID" "COMMAND" "%CPU" "%MEM"
    ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 6 | tail -n 5 | awk '{
        printf "%-8s %-25s %-8.2f %-8.2f\n", $1, $2, $3, $4
    }'
}

show_users() {
    print_header "User Information"
    users_count=$(who | wc -l)
    printf "%-20s : %d\n" "Logged-in Users" "$users_count"
    if [ "$users_count" -gt 0 ]; then
        printf "${S_UNDERLINE}Details:${C_OFF}\n"
        who
    fi
}

show_service_status() {
    print_header "Service Status"
    for service in "${SERVICES_TO_CHECK[@]}"; do
        if systemctl is-active --quiet "$service"; then
            status="active"
            color="${C_GREEN}"
        else
            status="inactive"
            color="${C_RED}"
        fi
        printf "%-20s : ${color}${S_BOLD}[ %s ]${C_OFF}\n" "$service" "${status^^}"
    done
}

show_large_dirs() {
    print_header "Top 5 Largest Directories in /"
    printf "${C_YELLOW}Note: This check can be slow and I/O intensive.${C_OFF}\n"
    du -sh /* 2>/dev/null | sort -hr | head -n 5 | awk '{
        size=$1;
        path=$2;
        printf "  %-10s %s\n", size, path;
    }'
}


# --- Main Execution ---

main() {
    clear
    printf "${S_BOLD}${C_MAGENTA}"
    echo "========================================="
    echo "        SERVER DASHBOARD REPORT"
    echo "========================================="
    printf "${C_OFF}"

    show_system_info
    show_resource_usage
    show_service_status
    show_users
    show_top_processes
    show_large_dirs

    # Footer
    printf "\n${C_BLUE}%.s─${C_OFF}" $(seq 1 41)
    printf "\n${C_CYAN}Report generated on: $(date '+%Y-%m-%d %H:%M:%S')${C_OFF}\n"
}

# Run the main function
main