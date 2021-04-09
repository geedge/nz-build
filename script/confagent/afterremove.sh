#!/bin/sh
if [ 0 -eq $1 ];then

	echo 'start remove confagent module from disk...' 

	systemctl stop confagent.service
	systemctl stop prometheus.service
	systemctl stop snmp-exporter.service

	rm -rf /opt/nezha/confagent

	systemctl disable confagent.service
	systemctl disable prometheus.service
	systemctl disable snmp-exporter.service

	rm -rf /usr/lib/systemd/system/{confagent.service,prometheus.service,snmp-exporter.service}

	systemctl daemon-reload

	echo 'uninstall success!'
fi
