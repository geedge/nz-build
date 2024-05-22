#!/bin/bash
set -evx
CUR_PWD=`pwd`

PACKAGE_NAME=nz-ipmi-exporter
BRANCH_ARRAY=(${CI_COMMIT_REF_NAME//-/ })
PACKAGE_VERSION=${BRANCH_ARRAY[1]}.$CI_COMMIT_SHORT_SHA
ITERATION=Release

RPM_FULL_NAME=${PACKAGE_NAME}-${PACKAGE_VERSION}-${ITERATION}.x86_64.rpm

# 初始化 minio
mc alias set nz $MINIO_HOST $MINIO_USER $MINIO_PWD

#依赖包版本
IPMI_EXPORTER_PKG=ipmi_exporter-1.8.0.linux-amd64.tar.gz

# 拉取依赖文件
mc cp nz/depends/exporter/$IPMI_EXPORTER_PKG ./
mc cp nz/depends/exporter/freeipmi-1.5.7-3.el7.x86_64.rpm ./

# rpm 编译目录
BUILD_PATH=$CUR_PWD/build
RPM_NZ_IPMI_EXPORTER_PATH=$BUILD_PATH/opt/nezha/ipmi_exporter

mkdir -p $BUILD_PATH $RPM_NZ_IPMI_EXPORTER_PATH $RPM_NZ_IPMI_EXPORTER_PATH/deps

echo 'packaging begin ...'

# 解压
tar -xzf ./$IPMI_EXPORTER_PKG --strip-components 1 -C $RPM_NZ_IPMI_EXPORTER_PATH

# 配置文件
cp ./tools/ipmi_local.yml $RPM_NZ_IPMI_EXPORTER_PATH

# 依赖资源
cp freeipmi-1.5.7-3.el7.x86_64.rpm $RPM_NZ_IPMI_EXPORTER_PATH/deps

# RPM
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

echo 'package finished'
