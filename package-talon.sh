#!/bin/bash
source ./environment.sh
PACKAGE_NAME=${TALON_PACKAGE_NAME}
PACKAGE_VERSION=${TALON_PACKAGE_VERSION}


if [ 1 -eq $? ];then
  exit 1
fi

cd ${SOURCE_PATH}

if [[ 0 -eq ${NET_STATE} && 0 -eq ${SOURCE_FROM} ]];then
  echo 'start clone nz-talon from git clone -b '${TALON_BRANCH}' '${TALON_URL}
  download_source nz-talon $TALON_URL $TALON_BRANCH
fi

echo 'packaging nz-talon ...'
log 'packaging nz-talon ...'

cd ${TALON_WORK_PATH}
mvn clean install
#mvn clean install -Dxjar.password=111111 -Dxjar.excludes=/db/*,/static/**/*

if [ 1 -eq $? ];then
	log 'package nz-talon project faild...exit'
	exit 1
fi
rm -rf ${CUR_PATH}/build/nz-talon/*
mkdir -p ${RPM_TALON_PATH}/config

cd ${TALON_WORK_PATH}/target
#go build ${TALON_WORK_PATH}/target/xjar.go
#cp -f ${TALON_WORK_PATH}/target/{nz-talon.xjar,xjar} ${RPM_TALON_PATH}
cp -f ${TALON_WORK_PATH}/target/nz-talon.jar ${RPM_TALON_PATH}
if [ ! -e ${CUR_PATH}/dist ];then
        mkdir -p ${CUR_PATH}/dist
fi
#rm -rf ${CUR_PATH}/dist/nz-talon.xjar
#cp ${TALON_WORK_PATH}/target/nz-talon.xjar ${CUR_PATH}/dist
rm -rf ${CUR_PATH}/dist/nz-talon.jar
cp ${TALON_WORK_PATH}/target/nz-talon.jar ${CUR_PATH}/dist

cp -f ${TALON_WORK_PATH}/src/main/resources/{application-prod.yml,application.yml,logback-spring.xml,config/auth.yml,config/token.auth,config/promtail.version} ${RPM_TALON_PATH}/config



fpm -s dir -t rpm -n ${PACKAGE_NAME} -v ${PACKAGE_VERSION} --iteration ${ITERATION} --rpm-os 'linux' --pre-install ${CUR_PATH}/script/nz-talon/beforeinstall.sh --post-install ${CUR_PATH}/script/nz-talon/afterinstall.sh --post-uninstall ${CUR_PATH}/script/nz-talon/afterremove.sh -C ${CUR_PATH}/build/nz-talon -f -p ${CUR_PATH}/rpm

log 'package nz-talon finished'
echo 'package nz-talon finished'
