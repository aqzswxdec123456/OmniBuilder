#!/bin/bash

IP=$1
ssh -tt root@${IP} /bin/bash <<'EOT'
export docker_images="<docker_images>"
echo "${docker_images}"
sh /opt/scripts/add_images.sh install ${docker_images}
exit
EOT