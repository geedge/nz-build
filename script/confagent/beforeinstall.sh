#!/bin/bash

AGENT_PATH=/opt/nezha/nz-agent

if [ 2 -eq $1 ];then
	
	if [ ! -d ${AGENT_PATH}/config ];then
		exit 0
	fi
	
	systemctl stop nz-agent
	
	TMP_PATH=/tmp/nezha/nz-agent
	rm -rf $TMP_PATH

	mkdir -p $TMP_PATH
	cp -rf $AGENT_PATH/config $TMP_PATH
	echo 'backup config file from '${AGENT_PATH}
	
	if [ 0 -lt $(rpm -aq nz-agent|wc -w) ];then
		echo 'clean before install...'
		rm -rf $AGENT_PATH
	fi
fi


