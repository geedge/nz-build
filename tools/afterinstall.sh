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
	fi	
fi
