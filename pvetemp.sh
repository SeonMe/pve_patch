#!/bin/bash

PkgList="lm-sensors hddtemp"

apt update && apt install ${PkgList} -y

default | sensors-detect

[ ! -d "pve_patch" ] && mkdir -p pve_patch && pushd pve_patch > /dev/null

wget https://raw.githubusercontent.com/SeonMe/pve_patch/master/nodes.patch
wget https://raw.githubusercontent.com/SeonMe/pve_patch/master/pvemanagerlib.patch

patch -p0 /usr/share/perl5/PVE/API2/Nodes.pm < nodes.patch
patch -p0 /usr/share/pve-manager/js/pvemanagerlib.js < pvemanagerlib.patch
rm -r pve_patch
popd > /dev/null

cat > /etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/rc.local <<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF

chmod +x /etc/rc.local && systemctl enable rc-local && systemctl start rc-local.service

sed -i '/^exit 0/,$d' /etc/rc.local
cat >> /etc/rc.local <<EOF
hddtemp -d /dev/sd?
exit 0
EOF

/etc/rc.local

systemctl restart pveproxy
