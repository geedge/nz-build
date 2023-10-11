#!/bin/sh

WORK_DIR=/opt/nezha/nz-web

fn_init_nz_web_service(){
  cat > /usr/lib/systemd/system/nz-web.service <<EOF
[Unit]
Description=nz-web
After=network.target
[Service]
WorkingDirectory=/opt/nezha/nz-web
EnvironmentFile=-/opt/nezha/nz-web/config/config.conf
ExecStart=/opt/nezha/nz-web/xjar ${JAVA_EXE} -jar /opt/nezha/nz-web/nz-admin.xjar -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/nezha/nz-web/logs \$OPTION
RestartSec=10s
Restart=always
[Install]
WantedBy=multi-user.target
EOF
chmod 755 /usr/lib/systemd/system/nz-web.service
}

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
    fn_init_nz_web_service

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
    fn_init_nz_web_service

	echo 'move backup config file...'
	if [ -d $TMP_PATH ];then
		for i in $(ls $TMP_PATH/config);do
			if [ 1 -eq `compareMD5 $WEB_PATH/config/$i $TMP_PATH/config/$i` ];then
				echo 'return config file '${i}
				cp -f $TMP_PATH/config/$i $WEB_PATH/config/$i
			fi	
		done	
	fi

    systemctl daemon-reload
    systemctl enable nz-web.service
    echo 'update nz-web success !'
fi
