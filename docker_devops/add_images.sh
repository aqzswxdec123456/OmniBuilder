#!/bin/bash

docker_images=$2

function add_images(){
	docker pull<IP>:5000/${docker_images}
	docker tag <IP>:5000/${docker_images} ${docker_images}
	docker rmi <IP>:5000/${docker_images}
	docker images
}

case $1 in
"install")
add_images
;;
*)
echo "please input: xxx.sh install <images_names>"
;;
esac
