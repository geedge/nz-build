#!/bin/bash

# 安装目录
NZ_IPMI_EXPORTER_PATH=/opt/nezha/ipmi_exporter

if [ "$1" = "remove" ]; then

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
