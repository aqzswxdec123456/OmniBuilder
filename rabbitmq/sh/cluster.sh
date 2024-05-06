#!/bin/bash

# 呼叫環境參數檔
source /tmp/sh/env_ip
source /tmp/sh/env_host
source /tmp/sh/env

function rpm_rabbitmq(){
	rpm -ivh /tmp/install/erlang-*
	rpm -ivh /tmp/install/rabbitmq-server*
	rabbitmq-plugins enable rabbitmq_management
	systemctl enable rabbitmq-server
	systemctl start rabbitmq-server
}

function rabbitmq_host(){
	line=$(cat /tmp/sh/env_ip | wc -l)
	for ((i=1; i<=${line}; i++))
	do
		name=$(cat /tmp/sh/env_ip | awk NR==$i | awk -F '"' '{print$2}')
		ip=$(cat /tmp/sh/env_host | awk NR==$i | awk -F '"' '{print$2}')
		echo ${name} ${ip} >> /etc/hosts
	done
}

function rabbitmq_disk_cluster(){
	# IT 用
	rabbitmqctl add_user <最高權限使用者> <最高權限使用者>
	rabbitmqctl set_user_tags <最高權限使用者> administrator
	rabbitmqctl set_permissions -p "/" <最高權限使用者> ".*" ".*" ".*"
	# 別的部門
	rabbitmqctl add_user <其他需求使用者> <其他需求密碼>
	rabbitmqctl set_user_tags <其他需求使用者> administrator
	rabbitmqctl set_permissions -p "/" <其他需求使用者> ".*" ".*" ".*"
	# 刪除預設
	rabbitmqctl delete_user guest

	rabbitmq-server -detached
	sleep 2
	rabbitmqctl stop
	sleep 2
	systemctl restart rabbitmq-server
	sleep 2
	rabbitmqctl start_app
	sleep 2
	systemctl restart rabbitmq-server
	echo "成功重啟，準備離開"
}


function rabbitmq_ram_cluster(){
	echo ${disk_cookie} > /var/lib/rabbitmq/.erlang.cookie
	systemctl restart rabbitmq-server
	rabbitmqctl stop
	rabbitmq-server -detached
	sleep 3
	rabbitmqctl stop_app
	sleep 3
	rabbitmqctl join_cluster --ram rabbit@${rabbitmq_disk_host_1}
	sleep 3
	rabbitmqctl start_app
	sleep 3
	rabbitmqctl stop
	sleep 3
	systemctl restart rabbitmq-server
	echo "成功重啟，準備離開"
}

function firewall_open(){
	firewall-cmd --zone=public --add-port=4369/tcp --permanent
	firewall-cmd --zone=public --add-port=5672/tcp --permanent
	firewall-cmd --zone=public --add-port=15672/tcp --permanent
	firewall-cmd --zone=public --add-port=25672/tcp --permanent
	firewall-cmd --reload
}

case $1 in
"install")
if [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${rabbitmq_disk_ip_1} ]];then
	rpm_rabbitmq
	rabbitmq_host
	firewall_open
	rabbitmq_disk_cluster
else
	rpm_rabbitmq
	rabbitmq_host
	firewall_open
	rabbitmq_ram_cluster
fi
;;
*)
echo "輸入: install";;
esac
