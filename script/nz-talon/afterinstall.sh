#!/bin/sh

# install
if [ 1 -eq $1 ];then
  cat > /usr/lib/systemd/system/nz-talon.service <<EOF
[Unit]
Description=nz-talon
After=network.target
[Service]
WorkingDirectory=/opt/nezha/nz-talon
ExecStart=/usr/bin/nohup ${JAVA_HOME}/bin/java -jar /opt/nezha/nz-talon/nz-talon.jar &
ExecStop=/usr/bin/pgrep -f nz-talon |xargs kill -9
Restart=always
[Install]
WantedBy=multi-user.target
EOF

	systemctl daemon-reload
	systemctl enable nz-talon && systemctl restart nz-talon
	

	echo 'install nz-talon success !'
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

	TALON_PATH=/opt/nezha/nz-talon

	TMP_PATH=/tmp/nezha/nz-talon
	echo 'move backup config file...'
	if [ -d $TMP_PATH ];then
		for i in $(ls TALON_PATH/config);do
			if [ 1 -eq `compareMD5 $WEB_PATH/config/$i $TMP_PATH/config/$i` ];then
				echo 'return config file '${i}
				mv -f $TALON_PATH/config/$i $TALON_PATH/config/$i
				cp -f $TMP_PATH/config/$i $TALON_PATH/config/$i'.oldconfig'
				cat $TALON_PATH/config/token.auth'.oldconfig' > $TALON_PATH/config/token.auth && rm -f $TALON_PATH/config/token.auth'.oldconfig'
			fi	
		done	
	fi
	systemctl restart nz-talon
fi
