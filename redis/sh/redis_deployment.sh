#!/bin/bash

IP=$1
operation=$2
model=$3

function ssh_execute() {
  local ip=$1
  local script=$2
  local op=$3

  ssh -tt root@${ip} /bin/bash <<EOT
  sh /tmp/sh/${script}.sh ${op}
  exit
EOT
}

case ${operation} in
  "install")
    case ${model} in
      "one") ssh_execute ${IP} "simple" "install" ;;
      "simple") ssh_execute ${IP} "simple" "install" ;;
      "replication") ssh_execute ${IP} "replication" "install" ;;
      "cluster")
        ssh_execute ${IP} "cluster" "install"
        ssh_execute ${IP} "cluster" "join" ;;
      *)
        echo "未知模式：${model}"
        exit 1 ;;
    esac
    ;;

    "remove")
      case ${model} in
        "one") ssh_execute ${IP} "simple" "remove" ;;
        "simple") ssh_execute ${IP} "simple" "remove" ;;
        "replication") ssh_execute ${IP} "replication" "remove" ;;
        "cluster")
          ssh_execute ${IP} "cluster" "remove"
          ssh_execute ${IP} "cluster" "join" ;;
        *)
          echo "未知模式：${model}"
          exit 1 ;;
      esac
      ;;

    *)
      echo "輸入: install 或者 remove"
      exit 1 ;;
esac
