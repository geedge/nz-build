#!/bin/bash

#from git 0 from local 1
export SOURCE_FROM=0
#0 internet 1 local
export NET_STATE=0

#web 打包的名称
export WEB_PACKAGE_NAME='nezha'
#web 打包的版本
export WEB_PACKAGE_VERSION='21.07'
#agent 打包名称
export AGENT_PACKAGE_NAME='nz-agent'
#agent打包版本
export AGENT_PACKAGE_VERSION='21.07'
#talon 打包名称
export TALON_PACKAGE_NAME='nz-talon'
#talon打包版本
export TALON_PACKAGE_VERSION='21.07'

#下载代码的分支
export WEB_BRANCH='dev-2.0'
export GUI_BRANCH='dev-2.0'
export AGENT_BRANCH='dev'
export TALON_BRANCH='dev'
# Alpha、Beta、RC、Release
export ITERATION='Release'

export CUR_PATH=`pwd`

export SOURCE_PATH=${CUR_PATH}/source
if [ ! -d ${SOURCE_PATH} ]; then
        mkdir -p ${SOURCE_PATH}
fi


export LOG=${CUR_PATH}/logger.log

#下载代码的url，SSH方式
export WEB_URL='git@git.mesalab.cn:nezha/nz-web.git'
export GUI_URL='git@git.mesalab.cn:nezha/nezha-fronted.git'
export AGENT_URL='git@git.mesalab.cn:nezha/nz-agent.git'
export TALON_URL='git@git.mesalab.cn:nezha/nz-talon.git'
#拉取的源代码的根路径
export GUI_WORK_PATH=${SOURCE_PATH}/nezha-fronted/nezha-fronted
export WEB_WORK_PATH=${SOURCE_PATH}/nz-web
export AGENT_WORK_PATH=${SOURCE_PATH}/nz-agent
export TALON_WORK_PATH=${SOURCE_PATH}/nz-talon

#构建rpm包的虚拟路径，每次打包之前需要保证目录纯净
export RPM_WORK_PATH=${CUR_PATH}/build
export RPM_WEB_PATH=${RPM_WORK_PATH}/nz-web/opt/nezha/nz-web/
export RPM_AGENT_PATH=${RPM_WORK_PATH}/nz-agent/opt/nezha/nz-agent/
export RPM_TALON_PATH=${RPM_WORK_PATH}/nz-talon/opt/nezha/nz-talon/
log()
{
	echo '['$(/usr/bin/date -d today +"%Y-%m-%d %T")'] '$1 >>$LOG
}
if [[ 0 -eq ${NET_STATE} && 0 -eq ${SOURCE_FROM} ]];then
  #准备git
  if [ 1 -eq `/usr/bin/which /usr/bin/git >> /dev/null;echo $?` ];then
    log 'start install git...'
    yum install -y git >> $LOG
  fi
fi
if [ 0 -eq ${NET_STATE} ];then
  #准备maven
  if [ 1 -eq $(which mvn >/dev/null;echo $?) ];then
          log 'start install maven...'
          yum install -y maven >> $LOG
          if [ 1 -eq $? ];then
            log 'install maven faild...exti'
            exit 1
          fi
          mkdir -p /root/.m2
          mv ${CUR_PATH}/tool/repository.tar.gz /root/.m2
          cd /root/.m2 && tar -xzf repository.tar.gz
  fi
  #准备nodejs
  if [ 1 -eq $(which npm>/dev/null;echo $?) ];then
          log 'start install nodeJS...'
          curl --silent --location https://rpm.nodesource.com/setup_10.x | bash >> $LOG
          yum install -y nodejs >> $LOG
          if [ 1 -eq $? ];then
            log 'install nodeJS faild...exti'
            exit 1
          fi
  fi
  #准备golang
  if [ 1 -eq $(which go>>/dev/null;echo $?) ];then
    log 'missing golang envorinment...start install...'
    yum install -y epel-release >> $LOG
    yum install -y go >> $LOG

    if [ 1 -eq $? ];then
      log 'install golang faild...exti'
      exit 1
    fi
  fi
  #检查fpm，因fpm需要ruby > 2.3.0 需手动安装该命令
  if [ 1 -eq $(which fpm >>/dev/null;echo $?) ];then
    echo 'there need "fpm" command,please install yourself...'
    exit 1;
  fi
fi

if [ ! -d ${CUR_PATH}/rpm ];then
	mkdir -p ${CUR_PATH}/rpm
fi

#拉取代码
download_source()
{
	local PATH=$1
	local URL=$2
	local BRENCH=$3
	local WORK_PATH=${SOURCE_PATH}/${PATH}

	if [ ! -d ${WORK_PATH} ];then
		log 'start clone '${PATH}'from git clone -b '${BRENCH}' '${URL}
		/usr/bin/git clone -b $BRENCH $URL >>$LOG
	else
		if [ ! -d ${WORK_PATH}'/.git' ];then
			rm -rf ${WORK_PATH}
			log 'start clone '${PATH}' from git clone -b '${BRENCH}' '${URL}
			/usr/bin/git clone -b $BRENCH $URL >> $LOG
		else
			log 'start pull '${PATH}' from git pull origin '${BRENCH}
			cd ${WORK_PATH}
			/usr/bin/git pull origin $BRENCH >> $LOG
		fi

		if [ 1 -eq $? ];then
        		log "pull faild"
        		exit 1
		fi
	fi
	if [ ! 0 -eq $? ];then
		log 'download source file faild,please try again!';
		exit 1;
	fi
	local SHORT_COMMIT_ID=`/usr/bin/git rev-parse --short HEAD`
	echo ${COMMIT_ID}${SHORT_COMMIT_ID:0:4}"_"
	return $?
}
