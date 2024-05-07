#!/bin/bash

source /tmp/sh/env

function rpm_mongo(){
	rpm -ivh /tmp/install/mongodb-org-*
}

function shard_1(){
	mv /etc/mongod.conf /etc/mongod.conf.bak
	mv /tmp/conf/mongo.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
	systemctl start mongod
	mongo ${mongo_shard_1}:27017 < /tmp/conf/account.js
	systemctl stop mongod
	rm -rf /etc/mongod.conf
	mv /tmp/conf/shard.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
}

function shard2_1(){
	mv /etc/mongod.conf /etc/mongod.conf.bak
	mv /tmp/conf/mongo.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
	systemctl start mongod
	mongo ${mongo_shard2_1}:27017 < /tmp/conf/account.js
	systemctl stop mongod
	rm -rf /etc/mongod.conf
	mv /tmp/conf/shard2.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
}

function shard_node1(){
	mv /etc/mongod.conf /etc/mongod.conf.bak
	mv /tmp/conf/shard.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
	systemctl start mongod
}

function shard_node2(){
	mv /etc/mongod.conf /etc/mongod.conf.bak
	mv /tmp/conf/shard2.conf /etc/mongod.conf
	chown mongod:mongod /etc/mongod.conf
	systemctl start mongod
}

function firewall_open(){
	firewall-cmd --zone=public --add-port=27017/tcp --permanent
	firewall-cmd --reload
}

function shard_join_node(){
	systemctl restart mongod
	sed -i "s/<mongo_shard_1>/${mongo_shard_1}/g" /tmp/conf/shard.js
	sed -i "s/<mongo_shard_2>/${mongo_shard_2}/g" /tmp/conf/shard.js
	sed -i "s/<mongo_shard_3>/${mongo_shard_3}/g" /tmp/conf/shard.js
	mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" < /tmp/conf/shard.js
	echo "rs.status()"| mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" | grep "stateStr\|name"

}

function shard_join_node2(){
	systemctl restart mongod
	sed -i "s/<mongo_shard2_1>/${mongo_shard2_1}/g" /tmp/conf/shard2.js
	sed -i "s/<mongo_shard2_2>/${mongo_shard2_2}/g" /tmp/conf/shard2.js
	sed -i "s/<mongo_shard2_3>/${mongo_shard2_3}/g" /tmp/conf/shard2.js
	mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" < /tmp/conf/shard2.js
	echo "rs.status()"| mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" | grep "stateStr\|name"

}


case $1 in
"install")
if [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${mongo_shard_1} ]];then
	rpm_mongo
	shard_1
	firewall_open

elif [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${mongo_shard2_1} ]];then
	rpm_mongo
	shard2_1
	firewall_open

elif [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${mongo_shard2_2} ]];then
	rpm_mongo
	shard_node2
	firewall_open

elif [[ `hostname -I | awk '{print$1}' | sed "s/ //g"` = ${mongo_shard2_3} ]];then
	rpm_mongo
	shard_node2
	firewall_open

else
	rpm_mongo
	shard_node1
	firewall_open
fi
    ;;

"join")

if [[ `hostname -I | sed "s/ //g"` = ${mongo_shard_1} ]];then
	shard_join_node
elif [[ `hostname -I | sed "s/ //g"` = ${mongo_shard2_1} ]];then
	shard_join_node2
else
	echo "這台不是主資料庫"
fi

    ;;

*)
    echo "輸入: install 或者 join"
    ;;
esac
