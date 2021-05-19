#!/bin/sh

# install
if [ 1 -eq $1 ];then
  cat > /usr/lib/systemd/system/nz-agent.service <<EOF
[Unit]
Description=nz-agent
After=network.target
[Service]
WorkingDirectory=/opt/nezha/nz-agent
ExecStart=/usr/bin/nohup /opt/nezha/nz-agent/xjar ${JAVA_HOME}/bin/java -Dnz-agent.dir=/opt/nezha/nz-agent -jar /opt/nezha/nz-agent/nz-agent.xjar &
ExecStop=/usr/bin/pgrep -f nz-agent |xargs kill -9
Restart=always
[Install]
WantedBy=multi-user.target
EOF

  cat > /usr/lib/systemd/system/prometheus.service <<"EOF"
[Unit]
Description=prometheus
After=network.target
[Service]
WorkingDirectory=/opt/nezha/nz-agent/prometheus
EnvironmentFile=/opt/nezha/nz-agent/prometheus/config.conf
ExecStart=/opt/nezha/nz-agent/prometheus/prometheus $OPTION
Restart=always
[Install]
WantedBy=multi-user.target
EOF
  cat > /opt/nezha/nz-agent/prometheus/config.conf <<EOF
OPTION=" --config.file='/opt/nezha/nz-agent/prometheus/prometheus.yml' --web.listen-address='127.0.0.1:10091' --web.enable-admin-api --web.enable-lifecycle --storage.tsdb.retention.time=15d "
EOF
  cat > /usr/lib/systemd/system/snmp-exporter.service <<"EOF"
[Unit]
Description=snmp-exporter
After=network.target
[Service]
EnvironmentFile=/opt/nezha/nz-agent/snmp_exporter/config.conf
ExecStart=/opt/nezha/nz-agent/snmp_exporter/snmp_exporter $OPTION
Restart=always
[Install]
WantedBy=multi-user.target
EOF
  cat >/opt/nezha/nz-agent/snmp_exporter/config.conf <<EOF
OPTION="--web.listen-address='127.0.0.1:19116' --config.file='/opt/nezha/nz-agent/snmp_exporter/snmp.yml' "
EOF


  cat > /usr/lib/systemd/system/blackbox-exporter.service <<"EOF"
[Unit]
Description=blackbox_exporter
After=network.target
[Service]
WorkingDirectory=/opt/nezha/nz-agent/blackbox_exporter
EnvironmentFile=/opt/nezha/nz-agent/blackbox_exporter/config.conf
ExecStart=/opt/nezha/nz-agent/blackbox_exporter/blackbox_exporter $OPTION
Restart=always
[Install]
WantedBy=multi-user.target
EOF
cat >/opt/nezha/nz-agent/blackbox_exporter/config.conf <<EOF
OPTION="--web.listen-address='127.0.0.1:19115' --config.file='/opt/nezha/nz-agent/blackbox_exporter/blackbox.yml' "
EOF

	systemctl daemon-reload
	systemctl enable nz-agent && systemctl restart nz-agent
	systemctl enable prometheus && systemctl restart prometheus
	systemctl enable snmp-exporter && systemctl restart snmp-exporter
  systemctl enable blackbox-exporter && systemctl restart blackbox-exporter

	echo 'install nz-agent success !'
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

	AGENT_PATH=/opt/nezha/nz-agent

	TMP_PATH=/tmp/nezha/nz-agent
	echo 'move backup config file...'
	if [ -d $TMP_PATH ];then
		for i in $(ls AGENT_PATH/config);do
			if [ 1 -eq `compareMD5 $WEB_PATH/config/$i $TMP_PATH/config/$i` ];then
				echo 'return config file '${i}
				mv -f $AGENT_PATH/config/$i $AGENT_PATH/config/$i
				cp -f $TMP_PATH/config/$i $AGENT_PATH/config/$i'.oldconfig'
				cat $AGENT_PATH/config/token.auth'.oldconfig' > $AGENT_PATH/config/token.auth && rm -f $AGENT_PATH/config/token.auth'.oldconfig'
			fi	
		done	
	fi
	systemctl restart nz-agent
fi
