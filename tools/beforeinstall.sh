#!/bin/bash

WEB_PATH=/opt/nezha/nz-web

if [ 2 -eq $1 ];then
	if [ ! -d ${WEB_PATH}/config ];then
		exit 0
	fi

        echo "stop nz-web.service"
        systemctl stop nz-web.service
	
	TMP_PATH=/tmp/nezha/nz-web
	rm -rf $TMP_PATH

	mkdir -p $TMP_PATH
	cp -rf $WEB_PATH/config $TMP_PATH
	echo 'backup config file from '${WEB_PATH}
	
	if [ 0 -lt $(rpm -aq nz-web|wc -w) ];then
		echo 'clean before install...'
		rm -rf $WEB_PATH
	fi
fi


