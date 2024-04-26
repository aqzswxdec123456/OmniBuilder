#!/bin/bash

# 呼叫環境參數檔
source /tmp/sh/env

function manage_redis(){
    local operation=$1
    os_version=$(cat /etc/os-release | grep "VERSION_ID" | sed -e 's/"//g' | awk -F "=" '{print $2}')
    if [[ ${os_version} == "7" ]]; then
        if [[ ${operation} == "install" ]]; then
            rpm -ivh /tmp/install/redis-6.2.6-1.el7.remi.x86_64.rpm
            mv /etc/redis/redis.conf /etc/redis/redis.conf.bak
            mv /tmp/conf/redis-cluster.conf /etc/redis/redis.conf
            chown redis:root /etc/redis/redis.conf
            firewall-cmd --zone=public --add-port=6379/tcp --permanent
            firewall-cmd --zone=public --add-port=16379/tcp --permanent
            firewall-cmd --reload
            systemctl start redis
            systemctl enable redis
        elif [[ ${operation} == "remove" ]]; then
            systemctl stop redis
            systemctl disable redis
            rpm -e redis-6.2.6-1.el7.remi.x86_64
            rm -rf /var/lib/redis /var/log/redis /etc/redis
            firewall-cmd --zone=public --remove-port=6379/tcp --permanent
            firewall-cmd --zone=public --remove-port=16379/tcp --permanent
            firewall-cmd --reload
        else
            echo "未知操作：${operation}"
            exit 1
        fi
    elif [[ ${os_version} == "8" ]]; then
        if [[ ${operation} == "install" ]]; then
            rpm -ivh /tmp/install/redis-7.0.12-1.el8.remi.x86_64.rpm
            mv /etc/redis/redis.conf /etc/redis/redis.conf.bak
            mv /tmp/conf/redis-cluster.conf /etc/redis/redis.conf
            chown redis:root /etc/redis/redis.conf
            firewall-cmd --zone=public --add-port=6379/tcp --permanent
            firewall-cmd --zone=public --add-port=16379/tcp --permanent
            firewall-cmd --reload
            sed -i "s/protected-mode yes/protected-mode no/g" /etc/redis/redis.conf
            systemctl start redis
            systemctl enable redis
        elif [[ ${operation} == "remove" ]]; then
            systemctl stop redis
            systemctl disable redis
            rpm -e redis-7.0.12-1.el8.remi.x86_64
            rm -rf /var/lib/redis /var/log/redis /etc/redis
            firewall-cmd --zone=public --remove-port=6379/tcp --permanent
            firewall-cmd --zone=public --remove-port=16379/tcp --permanent
            firewall-cmd --reload
        else
            echo "未知操作：${operation}"
            exit 1
        fi
    else
        echo "不支持的 Linux 版本。支持的版本為 centos7 或 centos8。"
        exit 1
    fi
}

function cluster_join(){
	expect << EOF
	spawn redis-cli --cluster create ${cluster_ip_1}:6379 ${cluster_ip_2}:6379 ${cluster_ip_3}:6379 ${cluster_ip_4}:6379 ${cluster_ip_5}:6379 ${cluster_ip_6}:6379 --cluster-replicas 1
	expect "yes"
	send "yes\r"
	expect eof;
	sleep 3
EOF
}
# redis-cli cluster nodes

case $1 in
"install") manage_redis install ;;
"remove") manage_redis remove ;;
"join") cluster_join ;;
*) echo "輸入: install 、 remove 、 join" ;;
esac
