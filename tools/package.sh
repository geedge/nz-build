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

# NZ FTP 服务器信息
# 主要版本 24.01
MAJOR_VERSION=$(echo ${BRANCH_ARRAY[1]} | cut -d "." -f 1,2)
# 创建目录 /Nezha/NZ-V24.01/NZ-V24.01.08/
FTP_MAJOR_VERSION_PATH="NZ-V""$MAJOR_VERSION"
FTP_SPECIFIC_VERSION_PATH="$FTP_MAJOR_VERSION_PATH/""NZ-V""${BRANCH_ARRAY[1]}/"

# 初始化 minio
mc alias set nz $MINIO_HOST $MINIO_USER $MINIO_PWD

#各个依赖包版本
NZ_WEB_PKG="release/nz-web/nz-web-rel-24.01.25-8eec9b90.tar.gz"
NZ_AGENT_PKG="release/nz-agent/nz-agent-24.01.02.6ba7db29-Release.x86_64.rpm"
NZ_GUI_PKG="release/nz-gui/nz-gui-676ca8a7.zip"
NZ_TALON_PKG="release/nz-talon/nz-talon-24.01.03.58a61ff4-Release.x86_64.rpm"

# 依赖jdk 文件名
JDK_FILENAME=jdk-21-0-3_linux-x64_bin.tar.gz
CHROME_FILENAME=chrome-117.0.5938.149-linux64.zip
CHROMEDRIVER_FILENAME=chromedriver-117.0.5938.149-linux64.zip
# 拉取依赖文件
mc cp nz/$NZ_WEB_PKG ./
mc cp nz/$NZ_AGENT_PKG ./
mc cp nz/$NZ_GUI_PKG ./
mc cp nz/$NZ_TALON_PKG ./
mc cp nz/depends/exporter/generator-0.21.0.linux-amd64.zip ./
mc cp nz/depends/prometheus/promtool ./
mc cp nz/depends/map/Tiles.zip ./
mc cp nz/depends/jdk/$JDK_FILENAME ./
mc cp nz/depends/chrome/$CHROME_FILENAME ./
mc cp nz/depends/chrome/$CHROMEDRIVER_FILENAME ./

# rpm 编译目录
BUILD_PATH=$CUR_PWD/build
RPM_NZ_PATH=$BUILD_PATH/opt/nezha/nz-web
RPM_JDK_PATH=$RPM_NZ_PATH/jdk
mkdir -p $BUILD_PATH $RPM_NZ_PATH $RPM_NZ_PATH/bin $RPM_NZ_PATH/install $RPM_NZ_PATH/config $RPM_NZ_PATH/generator $RPM_NZ_PATH/promtool $RPM_NZ_PATH/public $RPM_NZ_PATH/lib
mkdir -p $RPM_JDK_PATH

echo 'packaging  begin ...'
# 解压jdk
tar -xzf ./$JDK_FILENAME --strip-components 1 -C $RPM_JDK_PATH

# 解压 chrome&chromedriver 依赖
unzip -oq  ./$CHROME_FILENAME -d $RPM_NZ_PATH/lib
unzip -oqj ./$CHROMEDRIVER_FILENAME -d $RPM_NZ_PATH/lib

# 解压 nz-web.tar.gz
tar -zxvf nz-web-*.tar.gz -C $RPM_NZ_PATH

# 解压 nz-gui.zip
unzip -o nz-gui-*.zip -d $RPM_NZ_PATH/public

# 解压 map/Tiles.zip 默认 1-7 级
unzip -o -q Tiles.zip -d $RPM_NZ_PATH/public/static

# 移动nz.rpm
mv nz-*.rpm $RPM_NZ_PATH/install
cp ./tools/install-agent.sh.template  $RPM_NZ_PATH/install
cp ./tools/install-talon.sh.template  $RPM_NZ_PATH/install

# license&acc 校验依赖so
cp ./tools/lib*.so  $RPM_NZ_PATH/lib
cp ./tools/hasp_rus $RPM_NZ_PATH/lib

# 移动依赖工具
mv promtool $RPM_NZ_PATH/promtool/
unzip -o generator-0.21.0.linux-amd64.zip -d $RPM_NZ_PATH/generator/

# 配置文件
cp ./tools/nezha.properties $RPM_NZ_PATH/config
cp ./tools/logback-spring.xml $RPM_NZ_PATH/config

# 设置可执行权限
chmod +x $RPM_NZ_PATH/xjar
chmod +x $RPM_NZ_PATH/promtool/promtool
chmod +x $RPM_NZ_PATH/generator/generator
chmod +x $RPM_NZ_PATH/lib/hasp_rus



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

# 上传 ftp 服务器
curl -s -o /dev/null -Q "-*MKD $FTP_MAJOR_VERSION_PATH"  -Q "-*MKD $FTP_SPECIFIC_VERSION_PATH" -u $FTP_USER:$FTP_PWD $FTP_HOST
curl $FTP_HOST$FTP_SPECIFIC_VERSION_PATH -u $FTP_USER:$FTP_PWD -T "{$BUILD_PATH/$RPM_FULL_NAME,$BUILD_PATH/$RPM_FULL_NAME.md5sum.txt}"

echo 'package  finished'
