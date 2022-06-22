#!/bin/bash
set -vx
CUR_PWD=`pwd`

MYSQL_HOSTNAME="mariadb"
MYSQL_ROOTUSERNAME="root"
REDIS_HOSTNAME="redis"

RPM_PACKAGE_NAME="nz"
RPM_INSTALL_PATH="/opt/nezha/nz-web"

BRANCH_ARRAY=(${CI_COMMIT_REF_NAME//-/ })
PACKAGE_VERSION=${BRANCH_ARRAY[1]}.$CI_COMMIT_SHORT_SHA
ITERATION=Beta
if [[ "${BRANCH_ARRAY[0]}" == "rel" ]] ; then
  ITERATION='Release';
fi
RPM_FULL_NAME=${RPM_PACKAGE_NAME}-${PACKAGE_VERSION}-${ITERATION}.x86_64.rpm

echo 'install test begin ...'
# 先查询 rpm -qa nz
QUERY_RESULT=`rpm -qa $RPM_PACKAGE_NAME`
if [ ! -z "$QUERY_RESULT" ];then
      echo "nz system is installed, version is: $QUERY_RESULT"
      exit 1
      # rpm -e nz
fi

# 安装
rpm -ivh $RPM_FULL_NAME

# 检查安装是否成功
IS_INSTALLED=`rpm -qa | grep ${RPM_FULL_NAME/.rpm/}`
if [ $? -eq 0 ];then
    echo 'install success'
    sleep 10
else
    echo 'install failed'
    exit 1
fi

# 安装成功后，模拟 setup 操作
RETRY_NUM=5
RETRY_COUNT=0

while true
do
RETRY_COUNT=$((RETRY_COUNT+1))
API_AVAILABLE=`curl -I -k -m 10 -o /dev/null -s -w %{http_code}  http://localhost/setup/inited`
if [ $API_AVAILABLE -eq 200 ];then
    echo "nz api available"
    break
elif [ $RETRY_COUNT -lt $RETRY_NUM ];then
    sleep 10
    echo "Retrying API available..."
    continue
else
    echo "nz api unavailable"
    exit 1
fi
done

# check_code
VALIDATE_CODE=$(uuidgen |sed 's/-//g')
echo -n $VALIDATE_CODE > ${RPM_INSTALL_PATH}/tmp/nezha.auth
CHECKCODE=`curl -I -k -m 10 -o /dev/null -s -w %{http_code} http://localhost/setup/checkCode?code=$VALIDATE_CODE`
if [ $CHECKCODE -eq 200 ];then
    echo "setup auth code ok"
else
    echo "setup auth code error"
    exit 1
fi

# check_db
REQUEST_BODY="{\"database\":{\"host\":\"$MYSQL_HOSTNAME\",\"port\":$MYSQL_PORT,\"name\":\"$MYSQL_DATABASE\",\"username\":\"$MYSQL_ROOTUSERNAME\",\"pin\":\"$MYSQL_ROOT_PASSWORD\"},\"code\":\"$VALIDATE_CODE\"}"
CHECKDB=`curl -k -m 10 -o /dev/null -s -w %{http_code} -X POST -H 'Content-Type:application/json;charset=UTF-8' -d "${REQUEST_BODY}" 'http://localhost/setup/checkDb'`
if [ $CHECKDB -eq 200 ];then
    echo "db is connected"
else
    echo "db connection exception"
    exit 1
fi

# check_redis
REQUEST_BODY="{\"redis\":{\"host\":\"$REDIS_HOSTNAME\",\"port\":$REDIS_PORT,\"pin\":\"\"},\"code\":\"$VALIDATE_CODE\"}"
CHECKREDIS=`curl -k -m 10 -o /dev/null -s -w %{http_code} -X POST -H 'Content-Type:application/json;charset=UTF-8' -d "${REQUEST_BODY}" 'http://localhost/setup/checkRedis'`
if [ $CHECKREDIS -eq 200 ];then
    echo "redis is connected"
else
    echo "redis connection exception"
    exit 1
fi

# config
REQUEST_BODY="{\"database\":{\"host\":\"$MYSQL_HOSTNAME\",\"port\":$MYSQL_PORT,\"name\":\"$MYSQL_DATABASE\",\"username\":\"$MYSQL_ROOTUSERNAME\",\"pin\":\"$MYSQL_ROOT_PASSWORD\"},\
		\"redis\":{\"host\":\"$REDIS_HOSTNAME\",\"port\":$REDIS_PORT,\"pin\":\"\"},\
		\"system\":{\"username\":\"admin\",\"pin\":\"admin\",\"alertPrefix\":\"\",\"haMode\":1,\"haVip\":\"\",\"federationEnabled\":1},\
		\"code\":\"${VALIDATE_CODE}\"}"
CONFIG_RESULT=`curl -k -m 10 -o /dev/null -s -w %{http_code} -X POST -H 'Content-Type:application/json;charset=UTF-8' -d "${REQUEST_BODY}" 'http://localhost/setup/config'`
if [ $CONFIG_RESULT -eq 200 ];then
    echo "setup config finished"
else
    echo "setup config error"
    exit 1
fi

# check healthy
RETRY_NUM=5
RETRY_COUNT=0

while true
do
RETRY_COUNT=$((RETRY_COUNT+1))
SERVER_AVAILABLE=`curl -I -k -m 10 -o /dev/null -s -w %{http_code}  http://localhost/healthy`
if [ $SERVER_AVAILABLE -eq 200 ];then
    echo "nz server healthy"
    break
elif [ $RETRY_COUNT -lt $RETRY_NUM ];then
    sleep 30
    echo "Retrying server state..."
    continue
else
    echo "nz server unhealthy"
    exit 1
fi
done
echo 'install test success'
