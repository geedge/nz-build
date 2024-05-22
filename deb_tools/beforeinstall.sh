#!/bin/bash


echo "beforeinstall.sh begin"
echo "P1:"$1
echo "P2:"$2

# 安装目录
NZ_IPMI_EXPORTER_PATH=/opt/nezha/ipmi_exporter
# 临时目录
TMP_PATH=/tmp/nezha/ipmi_exporter

# 备份配置
if [ -d $NZ_IPMI_EXPORTER_PATH ];then
    rm -rf $TMP_PATH
	mkdir -p $TMP_PATH

    file=$NZ_IPMI_EXPORTER_PATH/config.conf && [ -f "${file}" ] && \cp -f ${file} $TMP_PATH
    echo 'backup config file from '${NZ_IPMI_EXPORTER_PATH}
fi

# 停止服务并卸载
if [ 0 -lt $(dpkg -l | grep nz-ipmi-exporter | wc -l) ];then
	echo "stop nz-ipmi-exporter service"
	systemctl stop nz-ipmi-exporter.service
	echo 'clean before install...'
	rm -rf $NZ_IPMI_EXPORTER_PATH
fi

echo "beforeinstall.sh finshed"
