#!/bin/bash

echo "======= SERVER STATES =======" 

#Cpu Usage 
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{ print $2 + $4 }')
echo "CPU Usage: $cpu%"