#!/bin/bash

echo "======= SERVER STATES =======" 

# Cpu Usage 
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{ print $2 + $4 }')
echo "CPU Usage: $cpu%"

# Memory Usage 
free_mem=$(free -m | awk 'NR==2{ printf "%sMb (%.2f%%) \n", $3 , $3*100/$2 }')
echo "Memory Used: $free_mem"
