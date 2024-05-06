# 注意
- docker registry安裝
- 防火牆開啟：5000

# docker registry 安裝流程
```sh
# 基本套件安裝
yum update -y
yum install vim git wget net-tools -y
yum install epel-release -y
yum install jq -y

# 透過 curl 
curl -fsSL https://get.docker.com/ | sh
curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 啟動
systemctl enable docker
systemctl start docker

# 修改連registry配置
cp -rp ${PWD}daemon.json /etc/docker/daemon.json
sed -i "s/<IP>/${IP}/g" /etc/docker/daemon.json
systemctl restart docker

# 運行 container
docker run -d -p 5000:5000 --restart=always -e REGISTRY_STORAGE_DELETE_ENABLED=true -v /opt/data/registry:/var/lib/registry --name registry registry

```

# docker registry 指令操作
```sh
# 拉下來
docker pull <registry_IP>:<registry_port><docker_images>
docker tag <registry_IP>:<registry_port><docker_images> <docker_images>
docker rmi <registry_IP>:<registry_port><docker_images>

# 運行 container
docker run <依照環境自己配置>
docker compose <依照環境自己配置>
```

# docker registry API
```sh
# 查看目前倉庫有多少個images
curl -s ${IP}:${Port}/v2/_catalog
# 查看images 詳細 tags 版本
curl -s ${IP}:${Port}/v2/${images_name}/tags/list
```
