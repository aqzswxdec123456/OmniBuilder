#!/bin/bash

IP=$1
ssh -tt root@${IP} /bin/bash <<'EOT'
sh /tmp/sh/router.sh install
exit
EOT
