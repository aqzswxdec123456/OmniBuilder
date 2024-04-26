#!/bin/bash

function ssh_key_scp_node {
	scp -rp ${PWD}/redis/{conf,sh,install} root@${IP}:/tmp/
}

IP=$1
ssh_key_scp_node
