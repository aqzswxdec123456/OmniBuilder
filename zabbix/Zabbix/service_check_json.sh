#!/bin/bash

# 建立 serviceStatuses 数组 key、value
declare -A serviceStatuses
hostname=$(hostname)

function check_services(){
    services=$(systemctl list-unit-files --type=service --state=enabled --no-pager | awk '{print $1}' | grep -vE "auditd|chronyd|crond|irqbalance|kdump|lvm2-monitor|NetworkManager-wait-online|NetworkManager|oddjobd|rhel-dmesg|rhel-domainname|rhel-import-state|rhel-readonly|rsyslog|snmpd|sshd|sssd|tuned" | sed 's/\.service//g' | grep -v "@")
    declare -a running_services=()

    for service in $services; do
        status=$(systemctl is-active ${service}.service)
        if [ "$status" == "active" ]; then
            running_services+=("$service")
        fi
    done
}

function check_services_install(){
    local services_to_check=(
    redis
    mongod
    mongod-shard
    mongos-router
    rabbitmq-server
    docker
    firewalld
    zabbix-agent
    redis-sentinel
    )

    # 0 未安裝 
    # 1 安裝+運行 
    # 2 安裝沒運行
    for service in ${services_to_check[@]}; do
        if systemctl --no-pager --no-legend --quiet list-unit-files | grep -q "^${service}.service"; then
            if systemctl is-active --quiet ${service}.service; then
                serviceStatuses[${service}]="1"
            else
                serviceStatuses[${service}]="2"
            fi
        else
            serviceStatuses[${service}]="0"
        fi
    done
}

function check_redis_status() {
    if [ "${serviceStatuses[redis]}" == "1" ]; then
        local redis_version=$(redis-cli info | grep redis_version | awk -F":" '{print $2}' | tr -d ' \r\n')
        local redis_replication=$(redis-cli info Replication | grep role | awk -F":" '{print $2}' | tr -d ' \r\n')
        local redis_cluster=$(redis-cli info Cluster | grep cluster_enabled | awk -F":" '{print $2}' | tr -d ' \r\n')
        local redis_status="running"

        local mode="Standalone" # 默認一台
        if [ "${redis_cluster}" == "1" ]; then
            mode="Cluster"
        elif [ "${redis_replication}" == "master" ]; then
            mode="Master"
        elif [ "${redis_replication}" == "slave" ]; then
            mode="Slave"
        fi

        # 宣告JSON
        local redis_details="{\"status\": \"${redis_status}\", \"version\": \"${redis_version}\", \"mode\": \"${mode}\"}"

        # 更新serviceStatuses Array
        serviceStatuses[redis]="${redis_details}"
    fi
}

function check_rabbitmq_status() {
    if [ "${serviceStatuses[rabbitmq-server]}" == "1" ]; then
        local rabbitmq_version=$(rabbitmqctl status | grep "version" | awk -F":" '{print $2}' | tr -d ' ",}')
        local rabbitmq_status="running"

        host=$(hostname)
        disk_nodes=$(rabbitmqctl cluster_status | awk '/Disk Nodes/ { getline; getline; print }' | sed "s/rabbit@//g")
        ram_nodes=$(rabbitmqctl cluster_status | awk '/RAM Nodes/ { getline; while (getline && !/Running Nodes/) print }' | sed "s/rabbit@//g")
        disk_nodes_array=($disk_nodes)
        ram_nodes_array=($ram_nodes)

        local mode="Standalone" # 默認一台
        if [[ " ${disk_nodes_array[@]} " =~ " ${host} " ]]; then
            mode="Cluster Disk"
        elif [[ " ${ram_nodes_array[@]} " =~ " ${host} " ]]; then
            mode="Cluster Ram"
        fi

        local rabbitmq_details="{\"install\": \"1\", \"status\": \"${rabbitmq_status}\", \"version\": \"${rabbitmq_version}\", \"mode\": \"${mode}\"}"
        serviceStatuses[rabbitmq-server]="${rabbitmq_details}"
    elif [ "${serviceStatuses[rabbitmq-server]}" == "0" ]; then
        serviceStatuses[rabbitmq-server]="0"
    elif [ "${serviceStatuses[rabbitmq-server]}" == "2" ]; then
        serviceStatuses[rabbitmq-server]="2"
    fi
}

function check_mongod_status() {
    local service_name=$1
    local port=$2

    if [[ ${serviceStatuses[$service_name]} == "1" ]]; then
        local mongod_status="running"
        local mongo_output=$(mongosh --quiet --port $port -u "root" -p "root" --authenticationDatabase "admin" --eval "rs.isMaster()")
        local is_primary=$(echo "$mongo_output" | grep 'ismaster' | grep -q 'true' && echo "true")
        local is_secondary=$(echo "$mongo_output" | grep 'secondary' | grep -q 'true' && echo "true")
        
        local mode="Standalone"
        if [ "$is_primary" == "true" ]; then
            mode="Primary"
        elif [ "$is_secondary" == "true" ]; then
            mode="Secondary"
        fi

        serviceStatuses[$service_name]="{\"install\": \"1\", \"status\": \"${mongod_status}\", \"mode\": \"${mode}\"}"
    fi
}

function generate_json_output() {
    check_redis_status
    check_rabbitmq_status
    check_mongod_status mongod 27017
    check_mongod_status mongod-shard 27018

    json_output="{ \"$hostname\": {"

    keys=(${!serviceStatuses[@]})
    last_index=$((${#keys[@]} - 1))

    for i in "${!keys[@]}"; do
        key=${keys[$i]}
        value=${serviceStatuses[$key]}

        if [[ $value == "0" ]]; then
            json_output+="\"$key\": $value"
        elif [[ $value == "1" || $value == "2" ]]; then
            json_output+="\"$key\": \"$value\""
        else
            json_output+="\"$key\": $value"
        fi

        if [[ $i -ne $last_index ]]; then
            json_output+=","
        fi
    done

    json_output+="}}"
    echo $json_output
}

# 取得services 抓出没有安装的
check_services
check_services_install

# 输出 json
generate_json_output