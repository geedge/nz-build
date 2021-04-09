#!/bin/bash

AGENT_PATH=/opt/nezha/confagent

if [ 2 -eq $1 ];then
	
	if [ ! -d ${AGENT_PATH}/config ];then
		exit 0
	fi
	
	systemctl stop confagent
	
	TMP_PATH=/tmp/nezha/confagent
	rm -rf $TMP_PATH

	mkdir -p $TMP_PATH
	cp -rf $AGENT_PATH/config $TMP_PATH
	echo 'backup config file from '${AGENT_PATH}
	
	if [ 0 -lt $(rpm -aq confagent|wc -w) ];then
		echo 'clean before install...'
		rm -rf $AGENT_PATH
	fi
fi


