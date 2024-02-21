#!/bin/bash
set -evx
CUR_PWD=`pwd`

PACKAGE_NAME=nz-node-exporter
BRANCH_ARRAY=(${CI_COMMIT_REF_NAME//-/ })
PACKAGE_VERSION=${BRANCH_ARRAY[1]}.$CI_COMMIT_SHORT_SHA
ITERATION=Release

RPM_FULL_NAME=${PACKAGE_NAME}-${PACKAGE_VERSION}-${ITERATION}.x86_64.rpm

# 初始化 minio
mc alias set nz $MINIO_HOST $MINIO_USER $MINIO_PWD

#依赖包版本
NODE_EXPORTER_PKG=node_exporter-1.7.0.linux-amd64.tar.gz

# 拉取依赖文件
mc cp nz/depends/exporter/$NODE_EXPORTER_PKG ./

# rpm 编译目录
BUILD_PATH=$CUR_PWD/build
RPM_NZ_NODE_EXPORTER_PATH=$BUILD_PATH/opt/nezha/node_exporter

mkdir -p $BUILD_PATH $RPM_NZ_NODE_EXPORTER_PATH $RPM_NZ_NODE_EXPORTER_PATH/prom

echo 'packaging  begin ...'

# 解压
tar -xzf ./$NODE_EXPORTER_PKG --strip-components 1 -C $RPM_NZ_NODE_EXPORTER_PATH

fpm -s dir -t rpm -n ${PACKAGE_NAME} -v ${PACKAGE_VERSION} --iteration ${ITERATION} --rpm-os 'linux'  \
	--pre-install ./tools/beforeinstall.sh  \
	--post-install ./tools/afterinstall.sh  \
	--post-uninstall ./tools/afterremove.sh  \
	-C $BUILD_PATH -f  \
	-p $BUILD_PATH 
	
# 计算md5值
cd $BUILD_PATH && md5sum $RPM_FULL_NAME > $RPM_FULL_NAME.md5sum.txt
cd $CUR_PWD 

# 上传编译的rpm 文件
mc cp $BUILD_PATH/$RPM_FULL_NAME nz/release/$PACKAGE_NAME/$RPM_FULL_NAME
mc cp $BUILD_PATH/$RPM_FULL_NAME.md5sum.txt nz/release/$PACKAGE_NAME/$RPM_FULL_NAME.md5sum.txt

echo 'package  finished'
