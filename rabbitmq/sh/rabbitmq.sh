#!/bin/bash

# 呼叫環境參數檔
source /tmp/sh/env

function rpm_rabbitmq(){
	rpm -ivh /tmp/install/erlang-*
	rpm -ivh /tmp/install/rabbitmq-server*
}

function rabbitmq_start(){
	rabbitmq-plugins enable rabbitmq_management
	systemctl enable rabbitmq-server
	systemctl start rabbitmq-server
	rabbitmqctl add_user admin admin
	rabbitmqctl set_user_tags admin administrator
	rabbitmqctl set_permissions -p "/" admin ".*" ".*" ".*"

}

function firewall_open(){
	firewall-cmd --zone=public --add-port=5672/tcp --permanent
	firewall-cmd --zone=public --add-port=15672/tcp --permanent
	firewall-cmd --reload
}

case $1 in
"install")
	rpm_rabbitmq
	rabbitmq_start
	firewall_open
    ;;

*)
    echo "輸入: install"
    ;;
esac

