#!/bin/sh
if [ 0 -eq $1 ];then

	echo 'start remove nz-talon module from disk...'

	systemctl stop nz-talon.service
	systemctl stop nz-promtail.service

	rm -rf /opt/nezha/nz-talon
	rm -rf /opt/nezha/promtail

	systemctl disable nz-talon.service
	systemctl disable nz-promtail.service

	rm -rf /usr/lib/systemd/system/{nz-talon.service,nz-promtail.service}

	systemctl daemon-reload

	echo 'uninstall success!'
fi
