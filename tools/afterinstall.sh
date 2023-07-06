#!/bin/sh

WORK_DIR=/opt/nezha/nz-web

# Find Java
if [[ -x "$WORK_DIR/jdk/bin/java" ]]; then
    JAVA_EXE="$WORK_DIR/jdk/bin/java"
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    JAVA_EXE="$JAVA_HOME/bin/java"
elif type -p java > /dev/null 2>&1; then
    JAVA_EXE=$(type -p java)
elif [[ -x "/usr/bin/java" ]];  then
    JAVA_EXE="/usr/bin/java"
else
    echo "Unable to find Java"
    JAVA_EXE="java"
#    exit 1
fi

WEB_PATH=/opt/nezha/nz-web
TMP_PATH=/tmp/nezha/nz-web
LIB_PATH=/usr/lib

cp -f $WEB_PATH/lib/* $LIB_PATH
# install
if [ 1 -eq $1 ];then

	cd /usr/lib/systemd/system
	echo 'start registory service file...'
	echo '[Unit]' >> nz-web.service
	echo 'Description=nz-web' >> nz-web.service
	echo 'After=network.target' >> nz-web.service
	echo '[Service]' >> nz-web.service
	echo 'WorkingDirectory=/opt/nezha/nz-web' >> nz-web.service
	echo 'ExecStart=/opt/nezha/nz-web/xjar '${JAVA_EXE}' -jar /opt/nezha/nz-web/nz-admin.xjar -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/nezha/nz-web/logs' >> nz-web.service
	echo 'RestartSec=10s' >> nz-web.service
	echo 'Restart=always' >> nz-web.service
	echo '[Install]' >> nz-web.service
	echo 'WantedBy=multi-user.target' >> nz-web.service
	chmod 755 nz-web.service
	systemctl daemon-reload
	systemctl enable nz-web.service
	systemctl start nz-web.service
	
	echo 'install success !'
	echo 'You should see the NEZHA setup page come up by going to:http://SERVER-IP/'
fi
compareMD5()
{
        if [ ! -f $1 ] || [ ! -f $2 ];then
		echo 1
		return 1
	fi
	
	local f1MD5=`md5sum $1|awk '{print $1}'`
        local f2MD5=`md5sum $2|awk '{print $1}'`

        if [ ${f1MD5} = ${f2MD5} ];then
                echo 0
                return 0
        else
                echo 1
                return 1
        fi
}
# update
if [ 2 -eq $1 ];then

	echo 'move backup config file...'
	if [ -d $TMP_PATH ];then
		for i in $(ls $WEB_PATH/config);do
			if [ 1 -eq `compareMD5 $WEB_PATH/config/$i $TMP_PATH/config/$i` ];then
				echo 'return config file '${i}
				cp -f $TMP_PATH/config/$i $WEB_PATH/config/$i
			fi	
		done

        # nz 配置文件
        # database.host 和 database.port 如果存在，拼接后赋值给 database.url
        # redis.host 和 redis.port 如果存在，拼接后赋值给 redis.url
        # 删除 database.host,database.port,redis.host,redis.port
        # 新增 redis.mode=standalone
        web_config_file=$WEB_PATH/config/nezha.properties
        while IFS='=' read -r key value; do
          key="${key// /}"
          value="${value// /}"

          case "$key" in
            database.host)
              database_host="$value"
              ;;
            database.port)
              database_port="$value"
              ;;
            redis.host)
              redis_host="$value"
              ;;
            redis.port)
              redis_port="$value"
              ;;
            *)
          esac
        done < "$web_config_file"

        if [[ -n $database_host ]] && [[ -n $database_port ]]; then
          database_url="${database_host}:${database_port}"
          sed -i '/^database\.\(host\|port\)=/d' "$web_config_file"
          echo "database.url=$database_url" >> "$web_config_file"

          echo "nezha.properties add properties. key='database.url' value=$database_url"
        fi

        if [[ -n $redis_host ]] && [[ -n $redis_port ]]; then
          redis_url="${redis_host}:${redis_port}"


          sed -i '/^redis\.\(host\|port\)=/d' "$web_config_file"
          echo "redis.url=$redis_url" >> "$web_config_file"
          echo "redis.mode=standalone" >> "$web_config_file"

          echo "nezha.properties add properties. key='redis.mode' value=standalone"
          echo "nezha.properties add properties. key='redis.url' value=$redis_url"
        fi
	fi	
fi
