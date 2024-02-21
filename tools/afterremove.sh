#!/bin/bash

# 安装目录
NZ_NODE_EXPORTER_PATH=/opt/nezha/node_exporter

if [ 0 -eq $1 ];then

	echo 'start remove nz-node-exporter from disk...'

	systemctl stop nz-node-exporter.service

	rm -rf $NZ_NODE_EXPORTER_PATH

	systemctl disable nz-node-exporter.service

	rm -rf /usr/lib/systemd/system/nz-node-exporter.service
	rm -rf /etc/rsyslog.d/nz-node-exporter.conf
	rm -rf /etc/logrotate.d/nz-node-exporter

	systemctl daemon-reload
	systemctl restart rsyslog

	echo 'uninstall success!'
fi
