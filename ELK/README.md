# 注意
- 透過 Docker-compose
- Linux 用 filebeat
- Windows 用 winlogbeat
- 防火牆使用到的Port 5044
- 目前手動，不提供自動化腳本

# Docker 安裝參考
```sh
yum install epel-release -y
yum install yum-utils device-mapper-persistent-data lvm2 -y
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce -y
yum install docker-compose -y
systemctl start docker
systemctl enable docker
```

## 基本配置
```sh
# 臨時生效
sysctl -w vm.max_map_count=262144

# 下次重開生效
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
```

## docker-compose 使用到的指令
```sh
# 給予容器執行權限
chown -R 1000:1000 /data

# 背景啟動 container  (把 -d 拿掉，就變成啟動不是背景執行)
docker-compose up -d

# 停掉 container
docker-compose down

# 重新啟動 container
docker-compose restart
```
