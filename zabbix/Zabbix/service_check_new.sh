#!/bin/bash

function check_services(){
        services=$(systemctl list-unit-files --type=service --state=enabled --no-pager | awk '{print $1}' | grep -vE "auditd|chronyd|crond|irqbalance|kdump|lvm2-monitor|NetworkManager-wait-online|NetworkManager|oddjobd|rhel-dmesg|rhel-domainname|rhel-import-state|rhel-readonly|rsyslog|snmpd|sshd|sssd|tuned" | sed 's/\.service//g' | grep -v "@")

        for service in $services; do
                status=$(systemctl is-active ${service}.service)
                if [ "$status" == "active" ]; then
                        running_services+=("$service")
                fi
        done
}

function check_services_no_install(){
    local services_to_check=(
    redis
    mongod
    rabbitmq-server
    docker
    mongos
    firewalld
    itfilebeat
    zabbix-agent
    redis-sentinel
    )

    for service in ${services_to_check[@]}; do
        if systemctl --no-pager --no-legend --quiet list-unit-files | grep -q "^${service}.service"; then
            :
        else
            echo "`hostname` ${service}_running no_service"
        fi
    done
}

function service_name(){
        local service=$1
        if systemctl --no-pager --no-legend --quiet list-unit-files | grep -q "^${service}.service"; then
                systemctl status $service | grep Active | awk -F ":" '{print$2}' | awk '{print$2}' | sed "s/[()]//g"
        else
                echo "not install"
        fi
}



function check_redis_status() {
    redis_pasword=$(cat /etc/redis/redis.conf | grep "requirepass" | awk '{print$2}' | sed -e 's/"//g')

    if [[ `service_name redis` == "running" ]]; then
        if [ `redis-cli info | wc -l` -eq 1 ]; then
                echo "`hostname` ${zbx_key}[redis_check] running"
                echo "`hostname` ${zbx_key}[redis_version] `redis-cli -a ${redis_pasword} info Server 2> /dev/null | grep redis_version | awk -F ":" '{print$2}'`"
                        if [[ `redis-cli -a ${redis_pasword} info Cluster 2> /dev/null | grep -v "#"` == *"1"* ]];then
                        echo "`hostname` ${zbx_key}[redis_model] Cluster-`redis-cli cluster nodes | grep `hostname -I` | awk -F ',' '{print$2}' | awk '{print$1}'`"
                else
                        echo "`hostname` ${zbx_key}[redis_model] `redis-cli -a ${redis_pasword} info Replication 2> /dev/null | grep -v "#" | grep "role" | awk -F ":" '{print$2}'`"
                fi
        else
                echo "`hostname` ${zbx_key}[redis_check] running"
                echo "`hostname` ${zbx_key}[redis_version] `redis-cli info Server | grep redis_version | awk -F ":" '{print$2}'`"
                if [[ `redis-cli info Cluster | grep -v "#"` == *"1"* ]];then
                        echo "`hostname` ${zbx_key}[redis_model] Cluster-`redis-cli cluster nodes | grep $(hostname -I) | awk -F ',' '{print$2}' | awk '{print$1}'`"
                else
                        echo "`hostname` ${zbx_key}[redis_model] `redis-cli info Replication | grep -v "#" | grep "role" | awk -F ":" '{print$2}'`"
                fi
        fi
    else
        echo "`hostname` ${zbx_key}[redis_check] dead"
    fi
}

function check_mongod_status() {
    if [[ `service_name mongod` == "running" ]]; then
        echo "`hostname` ${zbx_key}[mongod_check] running"
        mongo_architecture=$(echo "rs.isMaster().setName" | mongo --quiet -u "root" -p "root" -port 27017 -authenticationDatabase "admin" | tail -n 1)
        if [[ ${mongo_architecture} == "shardsvr" ]];then
            echo "`hostname` ${zbx_key}[mongod_model] shard"
        else
            mongo_replication=$(echo 'rs.status().members.forEach((member) => { if (member.self) { print(member.name + " " + member.stateStr); } });' | mongo --quiet --port 27017 --authenticationDatabase "admin" -u "root" -p "root" | tail -n 1 | awk '{print$2}')
            echo "`hostname` ${zbx_key}[mongod_model] ${mongo_replication}"
        fi
    else
        echo "`hostname` ${zbx_key}[mongod_check] dead"
    fi
}


function check_rabbitmq_status() {
    if [[ `service_name rabbitmq-server` == "running" ]]; then
        echo "`hostname` ${zbx_key}[rabbitmq_check] running"

        host=$(hostname)
        disk_nodes=$(rabbitmqctl cluster_status | awk '/Disk Nodes/ { getline; getline; print }' | sed "s/rabbit@//g")
        ram_nodes=$(rabbitmqctl cluster_status | awk '/RAM Nodes/ { getline; while (getline && !/Running Nodes/) print }' | sed "s/rabbit@//g")
        disk_nodes_array=($disk_nodes)
        ram_nodes_array=($ram_nodes)

        if [[ " ${disk_nodes_array[@]} " =~ " ${host} " ]]; then
            echo "`hostname` ${zbx_key}[rabbitmq_model] Cluster Disk"
        elif [[ " ${ram_nodes_array[@]} " =~ " ${host} " ]]; then
            echo "`hostname` ${zbx_key}[rabbitmq_model] Cluster Ram"
        else
            echo "`hostname` ${zbx_key}[rabbitmq_model] 單機"
        fi
    else
        echo "`hostname` ${zbx_key}[rabbitmq_check] dead"
    fi
}


function services_status(){

    zbx_key="monitor_service"

    for service in ${running_services[@]}; do
        case $service in
            redis) check_redis_status;;
            mongod) check_mongod_status;;  # replication or shard
            rabbitmq-server) check_rabbitmq_status;;
            docker) echo "`hostname` ${zbx_key}[docker_check] `service_name docker`";;
            mongos) echo "`hostname` ${zbx_key}[mongos_rounter_check] `service_name mongos`";;
            firewalld) echo "`hostname` ${zbx_key}[firewalld_check] `service_name firewalld`";;
            itfilebeat) echo "`hostname` ${zbx_key}[itfilebeat_check] `service_name itfilebeat`";;
            zabbix-agent) echo "`hostname` ${zbx_key}[zbxAg_check] `service_name zabbix-agent`";;
            redis-sentinel) echo "`hostname` ${zbx_key}[redis_sentinel_check] `service_name redis-sentinel`";;
            *) continue;; # echo "${service}：不知名的服務";;
        esac
    done
}


check_services
############## check_services_no_install   ##### 這行別刪除
services_status > /etc/zabbix/scripts/zbx_service_check.txt


file="/etc/zabbix/scripts/zbx_service_check.txt"
backup_file="/etc/zabbix/scripts/.zbx_service_check.txt"
diff_file="/etc/zabbix/scripts/.diff_output.txt"
zbx=$(grep -oP 'Server=\K(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' /etc/zabbix/zabbix_agentd.conf)

if [ ! -f $backup_file ]; then
    cp ${file} ${backup_file}
    line=$(wc -l ${backup_file} | awk '{print $1}')

    for (( i=1; i<=${line}; i++ ))
    do
        host=$(cat ${backup_file} | awk "NR==${i}"| awk '{print $1}')
        name=$(grep -oP '\[\K(.*)(?=_check)' ${backup_file} | awk "NR==${i}"| awk '{print $1}' )
        key=$(cat ${backup_file} | awk "NR==${i}"| awk '{print $2}' | grep -oP '\[\K[^]]*')
        value=$(cat ${backup_file} | awk "NR==${i}"| awk '{print $3}')
        /usr/bin/zabbix_sender -z ${zbx} -s "${host}" -k Linux.Service.Discovery -o "{\"data\":[{\"{#NAME}\":\"${name}_服務監控\",\"{#KEY}\":\"${key}\"}]}"

    done
    sleep 10
else
    diff --changed-group-format='%>' --unchanged-group-format='' ${backup_file} ${file} > ${diff_file}
    line2=$(wc -l ${diff_file} | awk '{print $1}')
    for (( i=1; i<=${line2}; i++ ))
    do
        host=$(cat ${diff_file} | awk "NR==${i}"| awk '{print $1}')
        name=$(grep -oP '\[\K(.*)(?=_check)' ${diff_file} | awk "NR==${i}"| awk '{print $1}' )
        key=$(cat ${diff_file} | awk "NR==${i}"| awk '{print $2}' | grep -oP '\[\K[^]]*')
        value=$(cat ${diff_file} | awk "NR==${i}"| awk '{print $3}')
        /usr/bin/zabbix_sender -z ${zbx} -s "${host}" -k Linux.Service.Discovery -o "{\"data\":[{\"{#NAME}\":\"${name}_服務監控\",\"{#KEY}\":\"${key}\"}]}"

    done
    cp ${file} ${backup_file}
    sleep 10
fi

/usr/bin/zabbix_sender -z ${zbx} -i /etc/zabbix/scripts/zbx_service_check.txt

