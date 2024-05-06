#!/bin/bash

# 專案名稱：<環境>_docker_auto_rabbitmq_build
# 串接 gitlab
# 用途：環境配置好，給予IP自動安裝rabbitmq服務
# 建置前請確認以下三點：
# 1.  VM建置完成、網路配置設定好(IP)、必要指令套件、硬碟配置、使用者配置。
# 2.  RabbitMQ 版本 3.11.2 RD 用 (1 disk 、6 ram)
# 3.  目前不提供Jenkins API 來觸發此專案。


# 參數化建置
# model(選擇)：one、cluster
# disk_ip(字串)：預設空白
# ram_ip(字串)：預設空白
# disk_host(字串)：預設空白
# ram_host(字串)：預設空白


###### 針對version參數說明
# 請選擇 rabbitmq 安裝模式：
# cluster → 參數請填寫 disk_ip、ram_ip、disk_host、ram_host
# one → 參數請填寫 disk_ip

###### 針對XXXXip系列參數說明
# 支援多組安裝

rm -rf rabbitmq/sh/env_ip
rm -rf rabbitmq/sh/env_host
rm -rf rabbitmq/sh/env

if [[ ${model} = "one" ]]; then
    echo "目前沒功能"
    # echo ${disk_ip}
    sh rabbitmq/sh/scp_file.sh ${disk_ip}
    sh rabbitmq/sh/rabbit_install.sh ${disk_ip}
    
elif [[ ${model} = "cluster" ]]; then
    rabbitmq_disk_ip=($disk_ip)
    rabbitmq_disk_ip_count=$(echo ${rabbitmq_disk_ip[@]} | sed "s/ /\n/g" | wc -l)
    rabbitmq_ram_ip=($ram_ip)
    rabbitmq_ram_ip_count=$(echo ${rabbitmq_ram_ip[@]} | sed "s/ /\n/g" | wc -l)
    rabbitmq_disk_host=($disk_host)
    rabbitmq_disk_host_count=$(echo ${rabbitmq_disk_host[@]} | sed "s/ /\n/g" | wc -l)
    rabbitmq_ram_host=($ram_host)
    rabbitmq_ram_host_count=$(echo ${rabbitmq_ram_host[@]} | sed "s/ /\n/g" | wc -l)


    # 撰寫env檔案
    if [[ -n "${disk_ip}" || -n "${ram_ip}" || -n "${disk_host}" || -n "${ram_host}" ]];then
        for env in $(seq 1 ${rabbitmq_disk_ip_count}); do
            echo rabbitmq_disk_ip_${env}='"'${rabbitmq_disk_ip[${env}-1]}'"' >> rabbitmq/sh/env_ip
        done
        for env in $(seq 1 ${rabbitmq_ram_ip_count}); do
            echo rabbitmq_ram_ip_${env}='"'${rabbitmq_ram_ip[${env}-1]}'"' >> rabbitmq/sh/env_ip
        done
        for env in $(seq 1 ${rabbitmq_disk_host_count}); do
            echo rabbitmq_disk_host_${env}='"'${rabbitmq_disk_host[${env}-1]}'"' >>  rabbitmq/sh/env_host
        done
        for env in $(seq 1 ${rabbitmq_ram_host_count}); do
            echo rabbitmq_ram_host_${env}='"'${rabbitmq_ram_host[${env}-1]}'"' >>  rabbitmq/sh/env_host
        done
    fi
    echo "abc=123" >  rabbitmq/sh/env
    
    # 安裝 MQ disk
    for cluster_disk_install in ${rabbitmq_disk_ip[@]}; do
        echo ${cluster_disk_install}
        sh rabbitmq/sh/scp_file.sh ${cluster_disk_install}
        sh rabbitmq/sh/cluster_install.sh ${cluster_disk_install} > /dev/null 2>&1 &
    done
    echo "黑洞執行中，30秒以後往後執行安裝ram"
    sleep 30
    scp root@${disk_ip}:/var/lib/rabbitmq/.erlang.cookie ${PWD}/rabbitmq/conf/.erlang.cookie
    join_cookie=$(cat rabbitmq/conf/.erlang.cookie)
    echo disk_cookie='"'${join_cookie}'"' > rabbitmq/sh/env
    # 安裝 MQ ram
    for cluster_ram_install in ${rabbitmq_ram_ip[@]}; do
        # echo ${cluster_ram_install}
        sh rabbitmq/sh/scp_file.sh ${cluster_ram_install}
        sh rabbitmq/sh/cluster_install.sh ${cluster_ram_install} > /dev/null 2>&1 &
        echo "黑洞執行中，60秒以後往後執行"
        sleep 60
    done

else
    echo "歐白來，沒選擇模式要安裝啥??"
fi
