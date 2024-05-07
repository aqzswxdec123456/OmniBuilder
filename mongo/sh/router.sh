#!/bin/bash

source /tmp/sh/env

function rpm_mongo(){
	rpm -ivh /tmp/install/mongodb-org-*
}

function router_install(){
	# 修改
	sed -i "s/<mongo_replication_1>/${mongo_replication_1}/g" /tmp/conf/router.conf
	sed -i "s/<mongo_replication_2>/${mongo_replication_2}/g" /tmp/conf/router.conf
	sed -i "s/<mongo_replication_3>/${mongo_replication_3}/g" /tmp/conf/router.conf

	# 移動配置檔案 + 給予權限
	mv /tmp/conf/router.conf /etc/mongos.conf
	chown mongod:mongod /etc/mongos.conf

	# 配置 systemctl start mongos
	cat << EOF >/etc/systemd/system/mongos.service
	[Unit]
	Description=mongo-router
	After=network.target

	[Service]
	Type=forking
	ExecStart=/usr/bin/mongos -f /etc/mongos.conf
	PrivateTmp=true

	[Install]
	WantedBy=multi-user.target
EOF

	# 配置linux TIME_WAIT 大量導致CPU阻塞
	echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf

	# 讓網路相關配置生效
	/sbin/sysctl -p

	systemctl daemon-reload
	systemctl start mongos
	systemctl enable mongos
	systemctl disable mongod
}

function firewall_open(){
	firewall-cmd --zone=public --add-port=27017/tcp --permanent
	firewall-cmd --reload
}

function router_join_to_cluster(){
	sed -i "s/<mongo_shard_1>/${mongo_shard_1}/g" /tmp/conf/join_shard_to_cluster.js
	sed -i "s/<mongo_shard_2>/${mongo_shard_2}/g" /tmp/conf/join_shard_to_cluster.js
	sed -i "s/<mongo_shard_3>/${mongo_shard_3}/g" /tmp/conf/join_shard_to_cluster.js
	mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" < /tmp/conf/join_shard_to_cluster.js
}

function router_join_to_cluster2(){
	sed -i "s/<mongo_shard2_1>/${mongo_shard2_1}/g" /tmp/conf/join_shard2_to_cluster.js
	sed -i "s/<mongo_shard2_2>/${mongo_shard2_2}/g" /tmp/conf/join_shard2_to_cluster.js
	sed -i "s/<mongo_shard2_3>/${mongo_shard2_3}/g" /tmp/conf/join_shard2_to_cluster.js
	mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" < /tmp/conf/join_shard2_to_cluster.js
}

case $1 in
"install")
	rpm_mongo
	router_install
	firewall_open
    ;;

"join")
if [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${mongo_router_1} ]];then
	echo "判斷數量"
	line=$(cat /tmp/sh/env | grep shard | wc -l)
	if [ ${line} -le 3 ]; then
		router_join_to_cluster
	elif [ ${line} -le 6 ]; then
		router_join_to_cluster
		router_join_to_cluster2
	else
		echo "超過7個暫時沒有自動化"
	fi
fi
    ;;

*)
    echo "輸入: install 或者 join"
    ;;
esac



# 驗證登入
# echo "rs.status()" | mongo -u "root" -p "root" -host 172.31.4.103 -port 27017 -authenticationDatabase "admin" | grep "stateStr\|name"
# echo "rs.status()" | mongo -u "root" -p "root" -host 172.31.4.103 -port 27017 -authenticationDatabase "admin" | grep "set\|stateStr\|name"
