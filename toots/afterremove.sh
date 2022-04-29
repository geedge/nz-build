#!/bin/sh
if [ 0 -eq $1 ];then

	echo 'start remove nz-web module from disk...' 

	systemctl stop nz-web.service

	rm -rf /opt/nezha/nz-web

	systemctl disable nz-web.service

	rm -rf /usr/lib/systemd/system/nz-web.service

	systemctl daemon-reload

	echo 'uninstall success!'
fi
