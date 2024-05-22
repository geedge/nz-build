#!/bin/bash

echo "afterremove.sh begin"
echo "P1:"$1
echo "P2:"$2

# 安装目录
NZ_IPMI_EXPORTER_PATH=/opt/nezha/ipmi_exporter

if (( 0 == $1 )); then

	echo 'start remove nz-ipmi-exporter from disk...'

	systemctl stop nz-ipmi-exporter.service

	rm -rf $NZ_IPMI_EXPORTER_PATH

	systemctl disable nz-ipmi-exporter.service

	rm -rf /usr/lib/systemd/system/nz-ipmi-exporter.service
	rm -rf /etc/rsyslog.d/nz-ipmi-exporter.conf
	rm -rf /etc/logrotate.d/nz-ipmi-exporter

	systemctl daemon-reload
	systemctl restart rsyslog

	echo 'uninstall success!'
fi

echo "afterremove.sh finshed"

