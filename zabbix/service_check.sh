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

#function count_services(){
	#if [ ${#running_services[@]} -le 100 ];then
		#echo "OK"
	#else
		#echo "ERROR"
	#fi
#}


function services_status(){
	for service in ${running_services[@]}; do
		case $service in
			redis)
				redis_status=$(systemctl status redis | grep running | wc -l)
				if [ ${redis_status} -eq 1 ];then
					redis_architecture=$(redis-cli info Cluster | grep -v "#" | awk -F ":" '{print$2}')
					if [ ${redis_architecture} == 1 ];then
						echo "Redis is cluster"
					else
						redis_replication=$(redis-cli info Replication | grep -v "#" | grep "role" | awk -F ":" '{print$2}')
						if [[ ${redis_replication} == *"master"* ]];then
							echo "Redis is master or one"
						else
							echo "Redis is slave"
						fi
					fi
				else
					echo "Redis not running"
				fi
;;
			mongod) # replication or shard
				mongo_status=$(systemctl status mongod | grep running | wc -l)
				if [ "$mongo_status" -eq 1 ];then
					mongo_architecture=$(echo "rs.isMaster().setName" | mongo --quiet -u "root" -p "root" -port 27017 -authenticationDatabase "admin" |tail -n 1)
					if [[ ${mongo_architecture} == "shardsvr" ]];then
						echo "Mongo is shard"
					else
						mongo_replication=$(echo 'rs.status().members.forEach((member) => { if (member.self) { print(member.name + " " + member.stateStr); } });' | mongo --quiet --port 27017 --authenticationDatabase "admin" -u "root" -p "root" | tail -n 1 | awk '{print$2}')
						echo "Mongo is ${mongo_replication}"
					fi
				else
					echo "Mongo not running"
				fi
;;
			rabbitmq-server)
				rabbitmq_status=$(systemctl status rabbitmq-server | grep running | wc -l)
				if [ ${rabbitmq_status} -eq 1 ];then
					host=$(hostname)
					disk_nodes=$(rabbitmqctl cluster_status | awk '/Disk Nodes/ { getline; getline; print }' | sed "s/rabbit@//g")
					ram_nodes=$(rabbitmqctl cluster_status | awk '/RAM Nodes/ { getline; while (getline && !/Running Nodes/) print }' | sed "s/rabbit@//g")
					disk_nodes_array=($disk_nodes)
					ram_nodes_array=($ram_nodes)

					if [[ " ${disk_nodes_array[@]} " =~ " ${host} " ]]; then
						echo "Rabbitmq is cluster disk"
					elif [[ " ${ram_nodes_array[@]} " =~ " ${host} " ]]; then
						echo "Rabbitmq is cluster ram"
					else
						echo "Cluster is not found"
					fi
				else
					echo "Rabbitmq not running"
				fi
;;
			docker)
				echo "Docker is `systemctl status docker | grep Active | awk -F ":" '{print$2}' | awk '{print$2}' | sed "s/[()]//g"`";;
			mongos)  # Rounter
				echo "Mongo_Rounter is `systemctl status mongos | grep Active | awk -F ":" '{print$2}' | awk '{print$2}' | sed "s/[()]//g"`";;
			zabbix-agent)
				echo "Zabbix_agent is `systemctl status zabbix-agent | grep Active | awk -F ":" '{print$2}' | awk '{print$2}' | sed "s/[()]//g"`";;
			itfilebeat)
				echo "Itfilebeat is `systemctl status itfilebeat | grep Active | awk -F ":" '{print$2}' | awk '{print$2}' | sed "s/[()]//g"`";;
			firewalld)
				echo "Firewalld is `systemctl status firewalld | grep Active | awk -F ":" '{print$2}' | awk '{print$2}' | sed "s/[()]//g"`";;

			*)
				continue;; # echo "${service}：不知名的服務";;
		esac
	done
}


check_services
services_status
#if [[ `count_services` == "OK" ]];then
	#services_status
#else
	#echo "有問題"
#fi

