#!/bin/sh
if [ 0 -eq $1 ];then

	echo 'start remove nz-agent module from disk...'

	systemctl stop nz-agent.service
	systemctl stop prometheus.service
	systemctl stop snmp-exporter.service
	systemctl stop blackbox-exporter.service

	rm -rf /opt/nezha/nz-agent
	rm -rf /opt/nezha/prometheus
	rm -rf /opt/nezha/snmp_exporter
	rm -rf /opt/nezha/blackbox_exporter

	systemctl disable nz-agent.service
	systemctl disable prometheus.service
	systemctl disable snmp-exporter.service
	systemctl disable blackbox-exporter.service

	rm -rf /usr/lib/systemd/system/{nz-agent.service,prometheus.service,snmp-exporter.service,blackbox-exporter.service}

	systemctl daemon-reload

	echo 'uninstall success!'
fi
