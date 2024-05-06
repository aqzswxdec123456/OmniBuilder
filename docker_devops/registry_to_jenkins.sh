#!/bin/bash

# 串接至 Jenkins，串接上節點
# 專案名稱：<環境>_docker_registry_management_tools
# 用途：docker_registry 管理工具

# 參數化建置
# model(選擇)：check、add、del
# docker_images(字串)：預設空白


###### 針對model參數說明
# check ：檢查
# add ：新增指定 docker_hub images
# del ：刪除registries內的images

###### 針對docker_images參數說明
# 模式為check，請勿填寫值~
# 放docker images，如果放兩個以上，請中間空白
# 例如：docker pull kibana:7.6.2，內容則是kibana:7.6.2即可
# 
# Jenkins 執行 shell
if [[ ${model} = "check" ]]; then
	sh /opt/scripts/registry.sh ${model}
elif [[ ${model} = "add" ]]; then
	for image in ${docker_images[@]}; do
    	sh /opt/scripts/registry.sh ${model} ${image}
    done
elif [[ ${model} = "del" ]]; then
	for image in ${docker_images[@]}; do
		sh /opt/scripts/registry.sh ${model} ${image}
    done
else
	echo "歐白來，沒選擇模式要幹啥??"
fi
