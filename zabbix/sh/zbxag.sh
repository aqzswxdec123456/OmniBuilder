#!/bin/bash


function zabbix_agent_install(){
	# rpm 包安裝
	rpm -ivh /tmp/install/zabbix-agent-5.0.30-1.el7.x86_64.rpm
	# 配置zabbix-agent
	mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak
	cp -rp /tmp/conf/lin_zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
	sed -i "s/<你的hostname>/`hostname`/g" /etc/zabbix/zabbix_agentd.conf
	# 自定義配置
	#mkdir /etc/zabbix/scripts
	#cp -rp /tmp/sh/system_cpu_memory_info.sh /etc/zabbix/scripts
	#cp -rp /tmp/conf/lin/system_cpu_memory_info /etc/zabbix/scripts
	#cp -rp /tmp/conf/lin/system_cpu_memory_info.conf /etc/zabbix/zabbix_agentd.d
	# 啟動服務
	systemctl enable zabbix-agent
	systemctl start zabbix-agent
}

function firewall_open(){
	firewall-cmd --zone=public --add-port=10050/tcp --permanent
	firewall-cmd --zone=public --add-port=10051/tcp --permanent
	firewall-cmd --reload
}

function firewall_close(){
	firewall-cmd --zone=public --remove-port=10050/tcp --permanent
	firewall-cmd --zone=public --remove-port=10051/tcp --permanent
	firewall-cmd --reload
}

function zabbix_agent_del(){
	systemctl stop zabbix-agent
	systemctl disable zabbix-agent
	rpm -e zabbix-agent-5.0.30-1.el7.x86_64
	rm -rf /etc/zabbix/
}


case $1 in
"install")
zabbix_agent_install
firewall_open
;;
"del")
zabbix_agent_del
firewall_close
;;

*)echo "please input:
1. install ：安裝
2. del ：刪除"
;;
esac
