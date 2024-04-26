#!/bin/bash

# 呼叫環境參數檔
source /tmp/sh/env

function check_os_version(){
    os_version=$(cat /etc/os-release | grep "VERSION_ID" | sed -e 's/"//g' | awk -F "=" '{print $2}')
    if [[ ${os_version} != "7" ]] && [[ ${os_version} != "8" ]]; then
        echo "不支持的 Linux 版本。支持的版本為 centos7 或 centos8。"
        exit 1
    fi
    echo ${os_version}
}

function manage_redis(){
    local operation=$1
    os_version=$(cat /etc/os-release | grep "VERSION_ID" | sed -e 's/"//g' | awk -F "=" '{print $2}')
    if [[ ${os_version} == "7" ]]; then
        if [[ ${operation} == "install" ]]; then
            rpm -ivh /tmp/install/redis-6.2.6-1.el7.remi.x86_64.rpm
        elif [[ ${operation} == "remove" ]]; then
            rpm -e redis-6.2.6-1.el7.remi.x86_64
            rm -rf /var/lib/redis /var/log/redis /etc/redis
        else
            echo "未知操作：${operation}"
            exit 1
        fi
    elif [[ ${os_version} == "8" ]]; then
        if [[ ${operation} == "install" ]]; then
            rpm -ivh /tmp/install/redis-7.0.12-1.el8.remi.x86_64.rpm
        elif [[ ${operation} == "remove" ]]; then
            rpm -e redis-7.0.12-1.el8.remi.x86_64
            rm -rf /var/lib/redis /var/log/redis /etc/redis
        else
            echo "未知操作：${operation}"
            exit 1
        fi
    else
        echo "不支持的 Linux 版本。支持的版本為 centos7 或 centos8。"
        exit 1
    fi
}

function configure_redis(){
  local config_type=$1
  local os_version=$(check_os_version)
  if [[ ${os_version} == "7" ]]; then
    if [[ ${config_type} == "master" ]]; then
      mv /etc/redis/redis.conf /etc/redis/redis.conf.bak
      mv /tmp/conf/redis-master.conf /etc/redis/redis.conf
      chown redis:root /etc/redis/redis.conf
      systemctl start redis
      systemctl enable redis
    elif [[ ${config_type} == "slave" ]]; then
      mv /etc/redis/redis.conf /etc/redis/redis.conf.bak
    	mv /tmp/conf/redis-slave.conf /etc/redis/redis.conf
    	sed -i "s/<redis_master>/${replication_ip_master}/g" /etc/redis/redis.conf
    	chown redis:root /etc/redis/redis.conf
    	systemctl start redis
    	systemctl enable redis
    elif [[ ${config_type} == "sentinel" ]]; then
      mv /etc/redis/sentinel.conf /etc/redis/sentinel.conf.bak
    	mv /tmp/conf/sentinel.conf /etc/redis/sentinel.conf
    	sed -i "s/<redis_master>/${replication_ip_master}/g" /etc/redis/sentinel.conf
    	chown redis:root /etc/redis/sentinel.conf
    	systemctl start redis-sentinel
    	systemctl enable redis-sentinel
    fi
  elif [[ ${os_version} == "8" ]]; then
    if [[ ${config_type} == "master" ]]; then
      mv /etc/redis/redis.conf /etc/redis/redis.conf.bak
      mv /tmp/conf/redis-master.conf /etc/redis/redis.conf
      chown redis:root /etc/redis/redis.conf
      echo "requirepass 123456" >> /etc/redis/redis.conf
      systemctl start redis
      systemctl enable redis
    elif [[ ${config_type} == "slave" ]]; then
      mv /etc/redis/redis.conf /etc/redis/redis.conf.bak
    	mv /tmp/conf/redis-slave.conf /etc/redis/redis.conf
    	sed -i "s/<redis_master>/${replication_ip_master}/g" /etc/redis/redis.conf
    	chown redis:root /etc/redis/redis.conf
      echo "requirepass 123456" >> /etc/redis/redis.conf
      echo "masterauth 123456" >> /etc/redis/redis.conf
    	systemctl start redis
    	systemctl enable redis
    elif [[ ${config_type} == "sentinel" ]]; then
      mv /etc/redis/sentinel.conf /etc/redis/sentinel.conf.bak
    	mv /tmp/conf/sentinel.conf /etc/redis/sentinel.conf
    	sed -i "s/<redis_master>/${replication_ip_master}/g" /etc/redis/sentinel.conf
    	chown redis:root /etc/redis/sentinel.conf
      echo "sentinel auth-pass mymaster 123456" >> /etc/redis/sentinel.conf
    	systemctl start redis-sentinel
    	systemctl enable redis-sentinel
    fi
  else
    echo "不支持的 Linux 版本。支持的版本為 centos7 或 centos8。"
    exit 1
  fi

}

function manage_firewall(){
    local operation=$1
    if [[ ${operation} == "add" ]]; then
        firewall-cmd --zone=public --add-port=6379/tcp --permanent
        firewall-cmd --zone=public --add-port=26379/tcp --permanent
        firewall-cmd --reload
    elif [[ ${operation} == "remove" ]]; then
        firewall-cmd --zone=public --remove-port=6379/tcp --permanent
        firewall-cmd --zone=public --remove-port=26379/tcp --permanent
        firewall-cmd --reload
    else
        echo "未知操作：${operation}"
        exit 1
    fi
}

case $1 in
"install")
if [[ `hostname -I | sed "s/ //g"` = ${replication_ip_master} ]];then
	manage_redis install
	configure_redis master
	manage_firewall add
elif [[ `hostname -I | sed "s/ //g"` = ${replication_ip_slave_1} ]];then
	manage_redis install
	configure_redis slave
	manage_firewall add
elif [[ `hostname -I | sed "s/ //g"` = ${replication_ip_slave_2} ]];then
	manage_redis install
	configure_redis slave
	manage_firewall add
else
	manage_redis install
	configure_redis sentinel
	manage_firewall add
fi
;;

"remove")
if [[ `hostname -I | sed "s/ //g"` = ${replication_ip_master} ]];then
  systemctl stop redis
  systemctl disable redis
	manage_redis remove
	manage_firewall remove
elif [[ `hostname -I | sed "s/ //g"` = ${replication_ip_slave_1} ]];then
  systemctl stop redis
  systemctl disable redis
	manage_redis remove
	manage_firewall remove
elif [[ `hostname -I | sed "s/ //g"` = ${replication_ip_slave_2} ]];then
  systemctl stop redis
  systemctl disable redis
	manage_redis remove
	manage_firewall remove
else
  systemctl stop redis-sentinel
  systemctl disable redis-sentinel
	manage_redis remove
	manage_firewall remove
fi
;;

*) echo "輸入: install 或者 remove" ;;
esac
