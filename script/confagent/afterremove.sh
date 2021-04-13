#!/bin/sh
if [ 0 -eq $1 ];then

	echo 'start remove nz-agent module from disk...'

	systemctl stop nz-agent.service
	systemctl stop prometheus.service
	systemctl stop snmp-exporter.service

	rm -rf /opt/nezha/nz-agent

	systemctl disable nz-agent.service
	systemctl disable prometheus.service
	systemctl disable snmp-exporter.service

	rm -rf /usr/lib/systemd/system/{nz-agent.service,prometheus.service,snmp-exporter.service}

	systemctl daemon-reload

	echo 'uninstall success!'
fi
