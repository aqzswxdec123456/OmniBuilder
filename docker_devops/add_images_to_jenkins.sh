#!/bin/bash

# 串接至 Jenkins，串接上節點
# 專案名稱：<環境>_docker_add_images
# 用途：添加各機器images，!!!!! 支援同時多台+多images安裝 !!!!!

# 參數化建置
# IP_list(字串)：預設空白
# docker_images(字串)：預設空白

###### 針對model參數說明
# 已經透過各服務安裝的機器才可以添加

###### 針對docker_images參數說明 不需要



# Jenkins 執行 shell
for IP in ${IP_list[@]};do
	check_ip=$(cat /root/.ssh/known_hosts | awk '{print$1}' | grep "${IP}")
    if [ "${check_ip}" == "${IP}" ];then
    	for images in ${docker_images[@]};do
        	# echo ${images}
    		sed -i "s|<docker_images>|${images}|g" /opt/scripts/connect_node.sh
    		sh /opt/scripts/connect_node.sh ${IP}
            sed -i "s|${images}|<docker_images>|g" /opt/scripts/connect_node.sh
        done
    else
    	echo "偵測到IP：${IP} 還沒添加進Jenkins自動化行列，請確認以後再執行"
    fi
done




