#!/bin/bash

source /tmp/sh/env

function rpm_mongo(){
	rpm -ivh /tmp/install/mongodb-org-*
}

function replication_1(){
	mv /etc/mongod.conf /etc/mongod.conf.bak
	mv /tmp/conf/mongo.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
	systemctl start mongod
	mongo ${mongo_replication_1}:27017 < /tmp/conf/account.js
	systemctl stop mongod
	rm -rf /etc/mongod.conf
	mv /tmp/conf/mongod.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
}

function replication_node(){
	mv /etc/mongod.conf /etc/mongod.conf.bak
	mv /tmp/conf/mongod.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
	systemctl start mongod
}

function firewall_open(){
	firewall-cmd --zone=public --add-port=27017/tcp --permanent
	firewall-cmd --reload
}

function replication_join_node(){
	systemctl restart mongod
	sed -i "s/<mongo_replication_1>/${mongo_replication_1}/g" /tmp/conf/replicat.js
	sed -i "s/<mongo_replication_2>/${mongo_replication_2}/g" /tmp/conf/replicat.js
	sed -i "s/<mongo_replication_3>/${mongo_replication_3}/g" /tmp/conf/replicat.js
	mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" < /tmp/conf/replicat.js
	echo "rs.status()"| mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" | grep "stateStr\|name"

}


case $1 in
"install")
if [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${mongo_replication_1} ]];then
	rpm_mongo
	replication_1
	firewall_open
else
	rpm_mongo
	replication_node
	firewall_open
fi
    ;;

"join")
if [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${mongo_replication_1} ]];then
	echo "添加主資料庫cluster"
	replication_join_node
else
	echo "這台不是主資料庫，跳過此動作"
fi
    ;;

*)
    echo "輸入: install 或者 join"
    ;;
esac
