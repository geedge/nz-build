#!/bin/bash
PACKAGE_NAME=${AGENT_PACKAGE_NAME}
PACKAGE_VERSION=${AGENT_PACKAGE_VERSION}
source ./environment.sh

if [ 1 -eq $? ];then
  exit 1
fi

cd ${SOURCE_PATH}

echo 'start clone confagent from git clone -b '${AGENT_BRANCH}' '${AGENT_URL}
download_source confagent $AGENT_URL $AGENT_BRANCH

echo 'packaging confagent ...'
log 'packaging confagent ...'

cd ${AGENT_WORK_PATH}
sudo mvn clean install -Dxjar.password=111111 -Dxjar.excludes=/db/*,/static/**/*

if [ 1 -eq $? ];then
	log 'package confagent project faild...exit'
	exit 1
fi
rm -rf ${CUR_PATH}/build/confagent/*
mkdir -p ${RPM_AGENT_PATH}/{config,prometheus,snmp_exporter}

cd ${AGENT_WORK_PATH}/target
go build ${AGENT_WORK_PATH}/target/xjar.go
cp -f ${AGENT_WORK_PATH}/target/{confagent.xjar,xjar} ${RPM_AGENT_PATH}

cp -f ${AGENT_WORK_PATH}/src/main/resources/{application-prod.yml,application.yml,logback-spring.xml,auth.yml,token.auth} ${RPM_AGENT_PATH}/config

tar -xzf ${CUR_PATH}/tool/prometheus-2.13.1.linux-amd64.tar.gz --strip-components 1 -C ${RPM_AGENT_PATH}/prometheus
tar -xzf ${CUR_PATH}/tool/snmp_exporter-0.15.0.linux-amd64.tar.gz --strip-components 1 -C ${RPM_AGENT_PATH}/snmp_exporter

fpm -s dir -t rpm -n ${PACKAGE_NAME} -v ${PACKAGE_VERSION} --iteration ${COMMIT_ID}"linux" --rpm-os 'linux' --pre-install ${CUR_PATH}/script/confagent/beforeinstall.sh --post-install ${CUR_PATH}/script/confagent/afterinstall.sh --post-uninstall ${CUR_PATH}/script/confagent/afterremove.sh -C ${CUR_PATH}/build/confagent -f -p ${CUR_PATH}/rpm

log 'package confagent finished'
echo 'package confagent finished'