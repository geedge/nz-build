#!/bin/bash

TALON_PATH=/opt/nezha/nz-talon
PROMTAIL_PATH=/opt/nezha/promtail

if [ 2 -eq $1 ];then
	
	if [ ! -d ${TALON_PATH}/config ];then
		exit 0
	fi
	
	systemctl stop nz-talon
	systemctl stop nz-promtail
	
	TMP_PATH=/tmp/nezha/nz-talon
	rm -rf $TMP_PATH

	mkdir -p $TMP_PATH
	cp -rf $TALON_PATH/config $TMP_PATH
	cp -rf $PROMTAIL_PATH/promtail.yml $TMP_PATH
	echo 'backup config file from '${TALON_PATH}
	
	if [ 0 -lt $(rpm -aq nz-talon|wc -w) ];then
		echo 'clean before install...'
		rm -rf $TALON_PATH
		rm -rf $PROMTAIL_PATH
	fi
fi


