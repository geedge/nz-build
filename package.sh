#!/bin/sh
source ./environment.sh

if [ 1 -eq $? ];then
  exit 1
fi

source ./package-agent.sh

if [ 1 -eq $? ];then
  exit 1
fi

PACKAGE_NAME=${WEB_PACKAGE_NAME}
PACKAGE_VERSION=${WEB_PACKAGE_VERSION}

cd ${SOURCE_PATH}

if [[ 0 -eq ${NET_STATE} && 0 -eq ${SOURCE_FROM} ]];then
  echo 'start clone nz-web from git clone -b '${WEB_BRANCH}' '${WEB_URL}
  COMMIT_ID=`download_source nz-web $WEB_URL $WEB_BRANCH`
  echo 'start clone nezha-fronted from git clone -b '${GUI_BRANCH}' '${GUI_URL}
  COMMIT_ID=`download_source nezha-fronted $GUI_URL $GUI_BRANCH`

  COMMIT_ID=${COMMIT_ID}"_"
fi

cd ${GUI_WORK_PATH}
echo 'packaging nezha gui ...'
log 'packaging nezha gui ...'
sudo npm install >> $LOG
sudo npm run build >>$LOG

if [ 1 -eq $? ];then
	log 'build faild,please check nodejs environment'
	echo 'build faild,please check nodejs environment'
	exit 1
fi

rm -rf ${WEB_WORK_PATH}/nz-admin/src/main/resources/{static,statics}

mkdir ${WEB_WORK_PATH}/nz-admin/src/main/resources/static

cp ${GUI_WORK_PATH}/dist/nz-gui*.zip ${WEB_WORK_PATH}/nz-admin/src/main/resources/static/

cd ${WEB_WORK_PATH}/nz-admin/src/main/resources/static/

unzip nz-gui*.zip >>/dev/null

#mv ${WEB_WORK_PATH}/nz-admin/src/main/resources/static/dist/* ${WEB_WORK_PATH}/nz-admin/src/main/resources/static/
#rm -rf ${WEB_WORK_PATH}/nz-admin/src/main/resources/static/dist/

if [ 1 -eq $(ls ${WEB_WORK_PATH}/nz-admin/src/main/resources/static/static |wc -l) ];then
	\cp -rf ${GUI_WORK_PATH}/static/Tiles ${WEB_WORK_PATH}/nz-admin/src/main/resources/static/static
fi

cd ${WEB_WORK_PATH}

sudo mvn clean install -Dxjar.password=111111 -Dxjar.excludes=/db/*,/static/**/*,/install/*

if [ 1 -eq $? ];then
	log 'package web project faild...exit'
	exit 1
fi

rm -rf ${CUR_PATH}/build/nz-web/*

mkdir -p ${RPM_WEB_PATH}/{config,install}

cd ${WEB_WORK_PATH}/nz-admin/target/
go build ${WEB_WORK_PATH}/nz-admin/target/xjar.go

cp ${WEB_WORK_PATH}/nz-admin/target/{nz-admin.xjar,xjar} ${RPM_WEB_PATH}

cp ${WEB_WORK_PATH}/nz-admin/src/main/resources/install/install.sh.template ${RPM_WEB_PATH}/install/
cp ${CUR_PATH}/rpm/${AGENT_PACKAGE_NAME}-${AGENT_PACKAGE_VERSION}-0.x86_64.rpm ${RPM_WEB_PATH}/install/

#cp -r ${WEB_WORK_PATH}/build_node_exporter ${RPM_WEB_PATH}

cp ${WEB_WORK_PATH}/nz-admin/src/main/resources/config/{nezha.properties,logback-spring.xml} ${RPM_WEB_PATH}/config

cp ${CUR_PATH}/tool/tool.tar.gz ${RPM_WEB_PATH}
cd ${RPM_WEB_PATH}
tar -xzf tool.tar.gz && rm -rf tool.tar.gz

if [ -n ${COMMIT_ID} ];then
	echo $COMMIT_ID
	COMMIT_ID=${COMMIT_ID%_*}
	echo $COMMIT_ID
fi

fpm -s dir -t rpm -n ${PACKAGE_NAME} -v ${PACKAGE_VERSION} --iteration '0'  --rpm-os 'linux' --pre-install ${CUR_PATH}/script/web/beforeinstall.sh --post-install ${CUR_PATH}/script/web/afterinstall.sh --post-uninstall ${CUR_PATH}/script/web/afterremove.sh -C ${CUR_PATH}/build/nz-web -f -p ${CUR_PATH}/rpm

log 'finished'
echo 'finished'
