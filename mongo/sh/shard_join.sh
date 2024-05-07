#!/bin/bash

IP=$1
ssh -tt root@${IP} /bin/bash <<'EOT'
sh /tmp/sh/shard.sh join
exit
EOT
