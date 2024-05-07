# 注意
- 準備 rpm os8 [6版本](https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/x86_64/RPMS/)
- 準備 rpm os7 [不選版本](https://repo.mongodb.org/yum/redhat/7/mongodb-org/)
- 支援VM、No Docker
- 防火牆開啟：27017，可以透過replication.sh 、 router.sh 、 shard.sh 查看
- 建立 Jenkins 搭配使用

# mongo 安裝操考腳本
```sh
sh $PWD/mongo/sh/replication.sh
sh $PWD/mongo/sh/router.sh
sh $PWD/mongo/sh/shard.sh
```
- 安裝包概念，執行sh的時候要帶入install、join

# mongo 安裝好的檢查
```sh
# 透過主資料庫去看
echo "rs.status()" | mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin" | grep "stateStr\|name"

# 透過router去看
echo "sh.status()" | mongo -u "root" -p "root" -port 27017 -authenticationDatabase "admin"
```
# mongo 各服務
```sh
# config
systemctl start mongod
systemctl enable mongod

# shard
systemctl start mongod-shard
systemctl enable mongod-shard

# router
systemctl start mongod-router
systemctl enable mongod-router
```
