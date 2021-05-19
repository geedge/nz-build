#!/bin/sh

# install
if [ 1 -eq $1 ];then

	cd /usr/lib/systemd/system

	rm -rf nzweb.service

	java_home=`echo $JAVA_HOME`
	
	echo 'start registory service file...'


	echo '[Unit]' >> nzweb.service

	echo 'Description=nz-web' >> nzweb.service

	echo 'After=network.target' >> nzweb.service



	echo '[Service]' >> nzweb.service

	echo 'WorkingDirectory=/opt/nezha/nz-web' >> nzweb.service

	echo 'ExecStart=/opt/nezha/nz-web/xjar '${java_home}'/bin/java -jar /opt/nezha/nz-web/nz-admin.xjar -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/opt/nezha/nz-web/logs' >> nzweb.service

	echo 'ExecStop=/usr/bin/pgrep -f nz-admin |xargs kill -9' >> nzweb.service

	echo 'Restart=always' >> nzweb.service

	echo '[Install]' >> nzweb.service

	echo 'WantedBy=multi-user.target' >> nzweb.service



	chmod 777 nzweb.service

	systemctl daemon-reload

	systemctl enable nzweb

	systemctl start nzweb
	
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

	WEB_PATH=/opt/nezha/nz-web

	TMP_PATH=/tmp/nezha/nz-web
	echo 'move backup config file...'
	if [ -d $TMP_PATH ];then
		for i in $(ls $WEB_PATH/config);do
			if [ 1 -eq `compareMD5 $WEB_PATH/config/$i $TMP_PATH/config/$i` ];then
				echo 'return config file '${i}
				mv -f $WEB_PATH/config/$i $WEB_PATH/config/$i
				cp -f $TMP_PATH/config/$i $WEB_PATH/config/$i'.oldconfig'
			fi	
		done	
	fi
	
fi
