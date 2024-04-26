#!/bin/bash

###################################################
# 以下才參考，少了移除功能，主要是依公司環境去配置更好 #
###################################################
# 專案名稱：<環境>_redis_build
# 串接 gitlab
# 用途：環境配置好，給予IP自動安裝redis服務
# 建置前請確認以下六點：
# 1.  VM建置完成、網路配置設定好(IP)、必要指令套件、硬碟配置、使用者配置。
# 2.  安裝 redis_one，裝一台
# 3.  安裝 redis_simple，專案支援三台各別安裝Master、Slave、Sentinel (1主、1從、1哨兵)，如果不符合這樣規格請勿執行。
# 4.  安裝 redis_replication ，專案支援六台各別安裝Master、Slave、Sentinel (1主、2從、3哨兵)，如果不符合這樣規格請勿執行。
# 5.  安裝 redis_cluster，專案支援六台各別安裝，3Master、3Slave (3主3從)，如果不符合這樣規格請勿執行。

# 參數化建置
# model(選擇)：one、simple、replication、cluster
# master_ip(字串)：預設空白
# slave_ip(字串)：預設空白
# sentinel_ip(字串)：預設空白
# cluster_ip(字串)：預設空白

###### 針對model參數說明
# 請選擇 redis 安裝模式：
# one (1台) → 參數請填寫 master_ip
# simple (1主 1從 1哨兵) → 參數請填寫 master_ip 、 slave_ip 、 sentine_ip
# replication (1主 2從 3哨兵) → 參數請填寫 master_ip 、 slave_ip 、 sentine_ip
# cluster (3主 3從) → 參數請填寫 cluster_ip

###### 針對XXXXip系列參數說明
# 支援多組安裝

redis_slave_ip=(${slave_ip})
redis_sentinel_ip=($sentinel_ip)
redis_cluster_ip=($cluster_ip)
redis_cluster_ip_count=$(echo ${redis_cluster_ip[@]} | sed "s/ /\n/g" | wc -l)

# 清理上次配置的env檔案
rm -rf redis/sh/env

# 撰寫env檔案
if [[ ${model} = "one" ]]; then
		echo replication_ip_master='"'${master_ip}'"' >> redis/sh/env
		sh redis/sh/scp_file.sh ${master_ip}
		sh redis/sh/simple_install.sh ${master_ip} simple install
elif [[ ${model} = "simple" ]]; then
		echo replication_ip_master='"'${master_ip}'"' >> redis/sh/env
		echo replication_ip_slave='"'${slave_ip}'"' >> redis/sh/env
		echo replication_ip_sentinel='"'${sentinel_ip}'"' >> redis/sh/env
		sh redis/sh/scp_file.sh ${master_ip}
		sh redis/sh/redis_deployment.sh ${master_ip} simple install
		sh redis/sh/scp_file.sh ${slave_ip}
		sh redis/sh/redis_deployment.sh ${slave_ip} simple install
		sh redis/sh/scp_file.sh ${sentinel_ip}
		sh redis/sh/redis_deployment.sh ${sentinel_ip} simple install
elif [[ ${model} = "replication" ]]; then
		echo replication_ip_master='"'${master_ip}'"' >> redis/sh/env
		echo replication_ip_slave_1='"'${redis_slave_ip[0]}'"' >> redis/sh/env
		echo replication_ip_slave_2='"'${redis_slave_ip[1]}'"' >> redis/sh/env
		echo replication_ip_sentinel_1='"'${redis_sentinel_ip[0]}'"' >> redis/sh/env
		echo replication_ip_sentinel_2='"'${redis_sentinel_ip[1]}'"' >> redis/sh/env
		echo replication_ip_sentinel_3='"'${redis_sentinel_ip[2]}'"' >> redis/sh/env
		sh redis/sh/scp_file.sh ${master_ip}
		sh redis/sh/redis_deployment.sh ${master_ip} replication install
		sh redis/sh/scp_file.sh ${redis_slave_ip[0]}
		sh redis/sh/redis_deployment.sh ${redis_slave_ip[0]} replication install
		sh redis/sh/scp_file.sh ${redis_slave_ip[1]}
		sh redis/sh/redis_deployment.sh ${redis_slave_ip[1]} replication install
		for scp_ssh in ${redis_sentinel_ip[@]}; do
				sh redis/sh/scp_file.sh ${scp_ssh}
				sh redis/sh/redis_deployment.sh ${scp_ssh} replication install
		done

elif [[ ${model} = "cluster" ]];then
	if [[ -n "${cluster_ip}" ]];then
        for env in $(seq 1 ${redis_cluster_ip_count}); do
            echo cluster_ip_${env}='"'${redis_cluster_ip[${env}-1]}'"' >> redis/sh/env
        done
        for scp_ssh in ${redis_cluster_ip[@]}; do
            sh redis/sh/scp_file.sh ${scp_ssh}
            sh redis/sh/redis_deployment.sh ${scp_ssh} cluster install
        done
    else
    	echo "redis_cluster_ip 沒有填值，redis安裝失敗"
    fi
else
	echo "歐白來，沒選擇模式要安裝啥??"
fi
