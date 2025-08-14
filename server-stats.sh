#!/bin/bash

echo "======= SERVER STATES =======" 

# Cpu Usage 
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{ print $2 + $4 }')
echo "CPU Usage: $cpu%"

# Memory Usage 
free_mem=$(free -m | awk 'NR==2{ printf "%sMb (%.2f%%) \n", $3 , $3*100/$2 }')
echo "Memory Used: $free_mem"

# Disk Usage 
disk=$(df -h | grep '^/dev/' | awk '{printf "%-20s %-8s used (Total: %s)\n", $1, $5, $2}')
echo -e "Disk Usage:\n$disk"

# Top 5 processes by CPU usage
processes_usage=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6) 
echo -e "Top 5 Process Usage:\n$processes_usage"

