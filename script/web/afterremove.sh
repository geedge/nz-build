#!/bin/sh
if [ 0 -eq $1 ];then

	echo 'start remove nz-web module from disk...' 

	systemctl stop nzweb.service

	rm -rf /opt/nezha/nz-web

	systemctl disable nzweb.service

	rm -rf /usr/lib/systemd/system/nzweb.service

	systemctl daemon-reload

	echo 'uninstall success!'
fi
