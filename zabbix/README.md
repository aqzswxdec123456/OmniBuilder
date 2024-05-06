# 注意
- 自行判斷zabbix-server版本
- 支援VM
- 防火牆使用到的Port 10050、10051
- 自動觸發可 Jenkins 搭配使用

# redis 安裝腳本注意事項
- zbxag 與 zabbix-agent 意思相同
- service_check 監控 Linux 可能性服務使用
- zbx_tools 自動探索功能，關於build 以後自動加入zabbix-server
- zbx_get_item 取得群組相關資料

# zbx_tools 使用說明
```sh
# zabbix-server 安裝好以後 會知道 IP、使用者、密碼
http://<ip>/zabbix/api_jsonrpc.php', '<user>', '<password>

# add 參數
python3 zbx_tools.py add <hostname> <ip> <group_id> <template_id>

# del
python3 zbx_tools.py del <hostname> <host_id>

# check_all
python3 zbx_tools.py check_all
```
