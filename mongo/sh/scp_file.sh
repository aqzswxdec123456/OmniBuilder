#!/bin/bash

IP=$1

expect << EOF
spawn ssh root@${IP}
expect "yes"
send "yes\r"
expect "login"
send "exit\r"
expect eof;
EOF

scp -rp mongo/{conf,sh,install} root@${IP}:/tmp/

