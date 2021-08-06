#!/bin/sh
if [ 0 -eq $1 ];then

	echo 'start remove nz-talon module from disk...'

	systemctl stop nz-talon.service
	

	rm -rf /opt/nezha/nz-talon

	systemctl disable nz-talon.service
	

	rm -rf /usr/lib/systemd/system/{nz-talon.service}

	systemctl daemon-reload

	echo 'uninstall success!'
fi
