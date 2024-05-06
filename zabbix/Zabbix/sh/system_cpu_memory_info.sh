#!/bin/bash


path_exe="/etc/zabbix/scripts/system_cpu_memory_info"

case $1 in
"cpu_load1")
${path_exe} | jq | grep '"cpu_load1"' | awk '{print$2}' | sed "s/,//g";;
"cpu_load5")
${path_exe} | jq | grep '"cpu_load5"' | awk '{print$2}' | sed "s/,//g";;
"cpu_load15")
${path_exe} | jq | grep '"cpu_load15"' | awk '{print$2}' | sed "s/,//g";;
"Mem_Total")
${path_exe} | jq | grep 'Mem_Total' | awk '{print$2}' | sed "s/,//g";;
"Mem_UsedPercent")
${path_exe} | jq | grep 'Mem_UsedPercent' | awk '{print$2}' | sed "s/,//g";;
"Hostname")
${path_exe} | jq | grep 'Hostname' | awk '{print$2}' | sed "s/,//g" | sed 's/"//g';;
"Uptime")
${path_exe} | jq | grep 'Uptime' | awk '{print$2}' | sed "s/,//g";;
"OS_version")
${path_exe} | jq | grep 'OS_version' | awk '{print$2}' | sed "s/,//g";;
esac


