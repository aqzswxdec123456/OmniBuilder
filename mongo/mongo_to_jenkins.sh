#!/bin/bash

# 專案名稱：<環境>_docker_auto_mongo_build
# 串接 gitlab
# 用途：環境配置好，給予IP自動安裝mongo服務
# 建置前請確認以下六點：
# 1.  VM建置完成、網路配置設定好(IP)、必要指令套件、硬碟配置、使用者配置。
# 2.  Mongo 版本 6.0.2 for RD用 (三台replication 、 三台router 、六台shard )
# 3.  目前不提供Jenkins API 來觸發此專案。


# 參數化建置
# version(選擇)：5.0.13、6.0.2
# replication_ip(字串)：預設空白
# router_ip(字串)：預設空白
# shard_ip(字串)：預設空白
# shard2_ip(字串)：預設空白


###### 針對version參數說明
# 請install 有啥就改啥即可

###### 針對XXXXip系列參數說明
# 支援多組安裝

mongo_replication_ip=($replication_ip)
mongo_replication_ip_count=$(echo ${mongo_replication_ip[@]} | sed "s/ /\n/g" | wc -l)
mongo_router_ip=($router_ip)
mongo_router_ip_count=$(echo ${mongo_router_ip[@]} | sed "s/ /\n/g" | wc -l)
mongo_shard_ip=($shard_ip)
mongo_shard_ip_count=$(echo ${mongo_shard_ip[@]} | sed "s/ /\n/g" | wc -l)
mongo_shard2_ip=($shard2_ip)
mongo_shard2_ip_count=$(echo ${mongo_shard2_ip[@]} | sed "s/ /\n/g" | wc -l)

# 清理mongo上次配置的env檔案
rm -rf mongo/sh/env

# 撰寫env檔案
if [[ -n "${replication_ip}" || -n "${router_ip}" || -n "${shard_ip}" ]];then
    for env in $(seq 1 ${mongo_replication_ip_count}); do
        echo mongo_replication_${env}='"'${mongo_replication_ip[${env}-1]}'"' >> mongo/sh/env
    done
    for env in $(seq 1 ${mongo_router_ip_count}); do
        echo mongo_router_${env}='"'${mongo_router_ip[${env}-1]}'"' >> mongo/sh/env
    done
    for env in $(seq 1 ${mongo_shard_ip_count}); do
        echo mongo_shard_${env}='"'${mongo_shard_ip[${env}-1]}'"' >> mongo/sh/env
    done
    for env in $(seq 1 ${mongo_shard2_ip_count}); do
        echo mongo_shard2_${env}='"'${mongo_shard2_ip[${env}-1]}'"' >> mongo/sh/env
    done
fi

# 判斷服務安裝模式replication、cluster
if [[ ${version} = "5.0.13" ]];then
    rm -rf mongo/install/*6.0.2*
    for replication_install in ${mongo_replication_ip[@]}; do
        sh mongo/sh/scp_file.sh ${replication_install}
        sh mongo/sh/replication_install.sh ${replication_install}
    done

    # 加入 replication(config)
    for replication_join in ${mongo_replication_ip[@]}; do
        sh mongo/sh/replication_join.sh ${replication_join}
    done

elif [[ ${version} = "6.0.2" ]];then
    rm -rf mongo/install/mongodb-org-mongos-5.0.13-1.el7.x86_64.rpm
    rm -rf mongo/install/mongodb-org-server-5.0.13-1.el7.x86_64.rpm
    
    # 安裝 replication
    for replication_install in ${mongo_replication_ip[@]}; do
        sh mongo/sh/scp_file.sh ${replication_install}
        sh mongo/sh/replication_install.sh ${replication_install}
    done
    
    # 加入 replication(config)
    for replication_join in ${mongo_replication_ip[@]}; do
        sh mongo/sh/replication_join.sh ${replication_join}
    done
    
    # 安裝 router
    for router_install in ${mongo_router_ip[@]}; do
        sh mongo/sh/scp_file.sh ${router_install}
        sh mongo/sh/router_install.sh ${router_install}
    done
     
    # 安裝 shard
    for shard_install in ${mongo_shard_ip[@]}; do
        sh mongo/sh/scp_file.sh ${shard_install}
        sh mongo/sh/shard_install.sh ${shard_install}
    done
    
    # 安裝 shard2
    for shard2_install in ${mongo_shard2_ip[@]}; do
        sh mongo/sh/scp_file.sh ${shard2_install}
        sh mongo/sh/shard_install.sh ${shard2_install}
    done
    
    # 加入 shard
    for shard_join in ${mongo_shard_ip[@]}; do
        sh mongo/sh/shard_join.sh ${shard_join}
    done
    
    # 加入 shard2
    for shard2_join in ${mongo_shard2_ip[@]}; do
        sh mongo/sh/shard_join.sh ${shard2_join}
    done
    
    # 加入 router
    for router_join in ${mongo_router_ip[@]}; do
        sh mongo/sh/router_join.sh ${router_join}
    done

else
    echo "正常來說這邊不可能出現才對，會出現就是你亂改Jenkins相關參數喔"
fi
