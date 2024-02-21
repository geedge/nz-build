#!/bin/bash

# 安装目录
NZ_NODE_EXPORTER_PATH=/opt/nezha/node_exporter
# 临时目录
TMP_PATH=/tmp/nezha/node_exporter

# 备份配置
if [ -d $NZ_NODE_EXPORTER_PATH ];then
    rm -rf $TMP_PATH
	mkdir -p $TMP_PATH

    file=$NZ_NODE_EXPORTER_PATH/config.conf && [ -f "${file}" ] && \cp -f ${file} $TMP_PATH
    echo 'backup config file from '${NZ_NODE_EXPORTER_PATH}
fi

# 停止服务并卸载
if [ 0 -lt $(rpm -aq nz-node-exporter|wc -w) ];then
	echo "stop nz-node-exporter service"
	systemctl stop nz-node-exporter.service
	echo 'clean before install...'
	rm -rf $NZ_NODE_EXPORTER_PATH
fi
