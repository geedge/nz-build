#!/bin/bash
set -evx
CUR_PWD=`pwd`

PACKAGE_NAME=nz
BRANCH_ARRAY=(${CI_COMMIT_REF_NAME//-/ })
PACKAGE_VERSION=${BRANCH_ARRAY[1]}.$CI_COMMIT_SHORT_SHA
ITERATION=Beta
if [[ "${BRANCH_ARRAY[0]}" == "rel" ]] ; then 
  ITERATION='Release';
fi

RPM_FULL_NAME=${PACKAGE_NAME}-${PACKAGE_VERSION}-${ITERATION}.x86_64.rpm

# 初始化 minio
mc alias set nz $MINIO_HOST $MINIO_USER $MINIO_PWD

#各个依赖包版本
NZ_WEB_PKG="release/nz-web/nz-web-rel-22.05.04-12c44c50.tar.gz"
NZ_AGENT_PKG="release/nz-agent/nz-agent-22.05.03.de5e6a94-Release.x86_64.rpm"
NZ_GUI_PKG="release/nz-gui/nz-gui-451dd2b9.zip"
NZ_TALON_PKG="release/nz-talon/nz-talon-22.03.04.8edfd343-Release.x86_64.rpm"

# 拉取依赖文件
mc cp nz/$NZ_WEB_PKG ./
mc cp nz/$NZ_AGENT_PKG ./
mc cp nz/$NZ_GUI_PKG ./
mc cp nz/$NZ_TALON_PKG ./
mc cp nz/depends/exporter/generator.zip ./
mc cp nz/depends/prometheus/promtool ./
mc cp nz/depends/map/Tiles.zip ./

# rpm 编译目录
BUILD_PATH=$CUR_PWD/build
RPM_NZ_PATH=$BUILD_PATH/opt/nezha/nz-web
mkdir -p $BUILD_PATH $RPM_NZ_PATH $RPM_NZ_PATH/bin $RPM_NZ_PATH/install $RPM_NZ_PATH/config $RPM_NZ_PATH/generator $RPM_NZ_PATH/promtool $RPM_NZ_PATH/public $RPM_NZ_PATH/lib

echo 'packaging  begin ...'

# 解压 nz-web.tar.gz
tar -zxvf nz-web-*.tar.gz -C $RPM_NZ_PATH

# 解压 nz-gui.zip
unzip -o nz-gui-*.zip -d $RPM_NZ_PATH/public

# 解压 map/Tiles.zip 默认 1-7 级
unzip -o -q Tiles.zip -d $RPM_NZ_PATH/public/static

# 移动nz.rpm
mv nz-*.rpm $RPM_NZ_PATH/install
cp ./tools/install.sh.template  $RPM_NZ_PATH/install

# license 校验依赖so
cp ./tools/lib*.so  $RPM_NZ_PATH/lib

# 移动依赖工具
mv promtool $RPM_NZ_PATH/promtool/
unzip -o generator.zip -d $RPM_NZ_PATH/generator/

# 配置文件
cp ./tools/nezha.properties $RPM_NZ_PATH/config
cp ./tools/logback-spring.xml $RPM_NZ_PATH/config

# 设置可执行权限
chmod +x $RPM_NZ_PATH/xjar
chmod +x $RPM_NZ_PATH/promtool/promtool
chmod +x $RPM_NZ_PATH/generator/generator



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
