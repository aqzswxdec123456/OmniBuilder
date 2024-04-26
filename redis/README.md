# 注意
- 準備 rpm os7 [6.2.6版本](https://rhel.pkgs.org/7/remi-x86_64/redis-6.2.6-1.el7.remi.x86_64.rpm.html)
- 支援VM、No Docker
- VM 可無對外網路
- 防火牆使用到的Port 6379、16379、26379 (可自行修改)
- 建立 Jenkins 搭配使用

# redis 安裝腳本注意事項
- 主程式：redis_deployment.sh <ip> <model> <動作>
- 副程式：simple.sh、replication.sh、cluster.sh
- model：呼叫指定副程式
- 動作：install 、 remove

# redis.conf 配置說明
```sh
cat ./redis/install/redis-master.conf
cat ./redis/install/redis-slave.conf
```
## 基本配置
|  config content                   | remark                             |
|  -------------------------------- | ----                               |
| bind 0.0.0.0                      | 指定IP通訊方式，通常不建議開啟0.0.0.0 |
| protected-mode yes                | 通過IP方式連線進來                   |
| port 6379                         | 指定端口，預設6379                   |
| daemonize yes                     | 支援背景執行                         |
| pidfile /var/run/redis_6379.pid   | 運行期間 PID 路徑檔案                |
| logfile /var/log/redis/redis.log  | redis 運行的 log 紀錄               |

## rdb 持久化
- 狀態：將 save 註解即可關閉
- 同步：某個時間內，執行指令符合save條件就進行同步
- 儲存：Redis的值
- 優點：因為有壓縮，檔案大小比aof小，恢復速度較快，適合用於備份
- 缺點：在同步的期間系統會產生一個PID進程，如果數據量很大，會消耗較多資源

|  config content                   | remark                            |
|  -------------------------------- | ----                              |
| save 900 1                        | 900秒內 至少1個 key發生改變就save   |
| save 300 10                       | 300秒內 至少10個 key發生改變就save  |
| save 10  100                      | 10秒內 至少100個 key發生改變就save  |
| stop-writes-on-bgsave-error yes   | 出錯則暫停寫入                     |
| rdbcompression yes                | 啟用壓縮                           |
| rdbchecksum yes                   | 檢查                              |
| dbfilename dump.rdb               | 文件名稱                           |
| dir /var/lib/redis                | rdb文件保存名稱                    |

## aof 持久化
- 狀態：配置 appendonly 來判斷是否開啟或關閉
- 同步：每秒同步，透過appendfsync配置
- 儲存：儲存操作指令
- 優點：因為是每秒紀錄，如果服務死亡只會損失一秒的資料
- 缺點：因為沒有壓縮，檔案大小比rdb較大，因為寫入動作唯一秒觸發機制，如果併發量較大，效率會受到影響，恢復速度比rdb慢

|  config content                   | remark                                                      |
|  -------------------------------- | ----                                                        |
| appendonly yes                    | 啟用持久化，預設為no                                          |
| appendfilename "appendonly.aof"   | aof文件名稱                                                  |
| auto-aof-rewrite-percentage 100   | 當aof達到指定比例重新撰寫操作                                  |
| auto-aof-rewrite-min-size 64mb    | aof重寫操作最小值                                             |
| appendfsync always                | always 更新就執行，數據最安全、速度慢                           |
| appendfsync everysec              | everysec 一秒運行一次持久化，如果0.XX秒斷線可能遺失資料、速度普通 |
| appendfsync no                    | no 不持久化，數據不安全，速度快                                |
