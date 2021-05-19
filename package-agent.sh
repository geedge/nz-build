#!/bin/bash
PACKAGE_NAME=${AGENT_PACKAGE_NAME}
PACKAGE_VERSION=${AGENT_PACKAGE_VERSION}
source ./environment.sh

if [ 1 -eq $? ];then
  exit 1
fi

cd ${SOURCE_PATH}

if [[ 0 -eq ${NET_STATE} && 0 -eq ${SOURCE_FROM} ]];then
  echo 'start clone nz-agent from git clone -b '${AGENT_BRANCH}' '${AGENT_URL}
  download_source nz-agent $AGENT_URL $AGENT_BRANCH
fi

echo 'packaging nz-agent ...'
log 'packaging nz-agent ...'

cd ${AGENT_WORK_PATH}
mvn clean install -Dxjar.password=111111 -Dxjar.excludes=/db/*,/static/**/*

if [ 1 -eq $? ];then
	log 'package nz-agent project faild...exit'
	exit 1
fi
rm -rf ${CUR_PATH}/build/nz-agent/*
mkdir -p ${RPM_AGENT_PATH}/{config,prometheus,snmp_exporter,blackbox_exporter}

cd ${AGENT_WORK_PATH}/target
go build ${AGENT_WORK_PATH}/target/xjar.go
cp -f ${AGENT_WORK_PATH}/target/{nz-agent.xjar,xjar} ${RPM_AGENT_PATH}

cp -f ${AGENT_WORK_PATH}/src/main/resources/{application-prod.yml,application.yml,logback-spring.xml,config/auth.yml,config/token.auth} ${RPM_AGENT_PATH}/config

tar -xzf ${CUR_PATH}/tool/prometheus-2.27.0.linux-amd64.tar.gz --strip-components 1 -C ${RPM_AGENT_PATH}/prometheus
tar -xzf ${CUR_PATH}/tool/snmp_exporter-0.15.0.linux-amd64.tar.gz --strip-components 1 -C ${RPM_AGENT_PATH}/snmp_exporter
tar -xzf ${CUR_PATH}/tool/blackbox_exporter-0.18.0.linux-amd64.tar.gz --strip-components 1 -C ${RPM_AGENT_PATH}/blackbox_exporter
echo '' > ${RPM_AGENT_PATH}/prometheus/rule.yml

cat > ${RPM_AGENT_PATH}/blackbox_exporter/blackbox.yml <EOF
modules:
  http_2xx:
    prober: http
  http_post_2xx:
    prober: http
    http:
      method: POST
  tcp_connect:
    prober: tcp
  pop3s_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^+OK"
      tls: true
      tls_config:
        insecure_skip_verify: false
  ssh_banner:
    prober: tcp
    tcp:
      query_response:
      - expect: "^SSH-2.0-"
  irc_banner:
    prober: tcp
    tcp:
      query_response:
      - send: "NICK prober"
      - send: "USER prober prober prober :prober"
      - expect: "PING :([^ ]+)"
        send: "PONG ${1}"
      - expect: "^:[^ ]+ 001"
  ping:
    prober: icmp
    timeout: 5s
EOF


fpm -s dir -t rpm -n ${PACKAGE_NAME} -v ${PACKAGE_VERSION} --iteration '0' --rpm-os 'linux' --pre-install ${CUR_PATH}/script/nz-agent/beforeinstall.sh --post-install ${CUR_PATH}/script/nz-agent/afterinstall.sh --post-uninstall ${CUR_PATH}/script/nz-agent/afterremove.sh -C ${CUR_PATH}/build/nz-agent -f -p ${CUR_PATH}/rpm

log 'package nz-agent finished'
echo 'package nz-agent finished'
