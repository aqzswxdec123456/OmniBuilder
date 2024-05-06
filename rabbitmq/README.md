# 注意
- 安裝rpm (gitlab取得rpm包)
- rpm 參考　url：　https://www.mongodb.com/download-center/community/releases
- 安裝VM Centos8 版本
- 防火牆開啟：4369 、 5672 、 15672 、 25672 ，可以透過 rabbitmq.sh 、 cluster.sh查看

# rabbitmq 版本 3.11.2 單機安裝流程
```sh
sh $PWD/rabbitmq/sh/rabbitmq.sh
```

# rabbitmq 版本 3.11.2 cluster安裝流程
```sh
sh $PWD/rabbitmq/sh/cluster.sh
```

# 外部網站
```sh
# MQ 參考網站
https://www.rabbitmq.com/which-erlang.html

# MQ 下載RPM 這邊可以查看最新版本
https://github.com/rabbitmq/rabbitmq-server/releases

# 指定到最新版本
https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.11.2
```
