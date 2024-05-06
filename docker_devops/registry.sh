#!/bin/bash

IP="172.31.4.51"
Port="5000"
docker_images=$2

function check_registries_images(){

	line=$(curl -s ${IP}:${Port}/v2/_catalog | jq | awk -F '"' '{print$2}' | sed -e "s/repositories//g" | sed '/^$/d' | wc -l)
	echo "Registries_Name:version"
	for ((i=1; i<=$line; i++)); do
		images_name=$(curl -s ${IP}:${Port}/v2/_catalog | jq | awk -F '"' '{print$2}' | sed -e "s/repositories//g" | sed '/^$/d' | awk NR==${i})
		images_version=$(curl -s ${IP}:${Port}/v2/${images_name}/tags/list | awk -F '"' '{print$4,$8}' | sed -e "s/ /:/g")
		echo ${images_version}
	done
}

function add_registries_images(){
	docker pull ${docker_images}
	docker tag ${docker_images} ${IP}:${Port}/${docker_images}
	docker push ${IP}:${Port}/${docker_images}
	docker rmi ${docker_images}
	docker rmi ${IP}:${Port}/${docker_images}
}

function del_registries_images(){
    docker_volume_path="/opt/data/registry/docker/registry/v2/repositories/"
    echo "刪除前"
    ls ${docker_volume_path}

    # 分割镜像名称和标签
    IFS=':' read -ra ADDR <<< "${docker_images}"
    image_name=${ADDR[0]}
    # 构造要删除的路径
    path_to_delete="${docker_volume_path}${image_name}"

    echo "正在删除: ${path_to_delete}"
    rm -rf ${path_to_delete}

    echo "刪除後"
    ls ${docker_volume_path}
    echo "開始重新啟動，釋放緩存"
    docker restart registry
}

case $1 in
"check")
check_registries_images
;;
"add")
add_registries_images
;;
"del")
del_registries_images
;;

*)echo "please input:
1. check ：檢查
2. add ：新增指定 docker_hub images
3. del ：刪除registries內的images"
;;
esac



