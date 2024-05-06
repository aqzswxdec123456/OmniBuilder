#!/bin/bash

function zabbix_agent_install(){
	rpm_path=$(find /tmp -name zabbix-agent-5.0.30-1.el7.x86_64.rpm)
	conf_path=$(find /tmp -name zabbix_agentd.conf)
	rpm -ivh $rpm_path
	mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak
	cp -rp $conf_path /etc/zabbix/
	sed -i "s/<你的hostname>/`hostname`/g" /etc/zabbix/zabbix_agentd.conf
	systemctl enable zabbix-agent
	systemctl start zabbix-agent
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
;;
"del")
zabbix_agent_del
;;

*)echo "please input:
1. install ：安裝
2. del ：刪除"
;;
esac

