#!/bin/bash

WORK_DIR=/opt/nezha/node_exporter

fn_init_service(){
    cat > /usr/lib/systemd/system/nz-node-exporter.service <<"EOF"
[Unit]
Description=nz-node-exporter
After=network.target
[Service]
WorkingDirectory=/opt/nezha/node_exporter
EnvironmentFile=-/opt/nezha/node_exporter/config.conf
ExecStart=/opt/nezha/node_exporter/node_exporter $OPTION
RestartSec=10s
Restart=always
LimitNOFILE=524288
[Install]
WantedBy=multi-user.target
EOF
}

fn_init_config(){
    cat > /opt/nezha/node_exporter/config.conf <<EOF
OPTION=" --web.listen-address='0.0.0.0:19100' --collector.textfile.directory='/opt/nezha/node_exporter/prom' --collector.os --collector.cpu.info --collector.meminfo --collector.diskstats --collector.filesystem --collector.netdev --collector.netdev.address-info "
EOF
}

# 初始化 rsyslog & logrotate 配置
fn_init_syslog_logrotate_config(){
  cat > /etc/rsyslog.d/nz-node-exporter.conf << "EOF"
if $programname == 'node_exporter' then {
    /var/log/nezha/nz-node-exporter/nz-node-exporter.log
    stop
}
EOF
  cat > /etc/logrotate.d/nz-node-exporter << "EOF"
/var/log/nezha/nz-node-exporter/*.log {
    daily
    missingok
    maxsize 100M
    rotate 7
    copytruncate
    compress
}
EOF
}

compareMD5(){
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

# 还原配置文件
# $1 需要还原的文件目录 /opt/nezha/node_exporter
# $2 备份文件目录       /tmp/nezha/node_exporter
restoreComponentConfig(){
  if [ ! -d $1 ] || [ ! -d $2 ];then
    echo "Directory does not exist"
    return 1
  fi

  for i in $(ls $2);do
    if [ 1 -eq `compareMD5 $1/$i $2/$i` ];then
      echo 'return config file '$1/${i}
      cp -f $2/$i $1/$i
    fi
  done
}

# install
if [ 1 -eq $1 ];then
  fn_init_config
  fn_init_service
  fn_init_syslog_logrotate_config

  systemctl daemon-reload
  systemctl enable nz-node-exporter && systemctl restart nz-node-exporter
  systemctl enable crond && systemctl restart crond
  systemctl enable rsyslog && systemctl restart rsyslog
  echo 'install nz-node-exporter success !'
fi

# update
if [ 2 -eq $1 ];then
  fn_init_config
  fn_init_service
  fn_init_syslog_logrotate_config

  # restore nz-node-exporter config
  NZ_NODE_EXPORTER_PATH=/opt/nezha/node_exporter
  TMP_PATH=/tmp/nezha/node_exporter
  echo 'move backup config file...'
  if [ -d $TMP_PATH ];then
    restoreComponentConfig $NZ_NODE_EXPORTER_PATH $TMP_PATH
  fi

  # restart all components
  systemctl daemon-reload
  systemctl enable nz-node-exporter && systemctl restart nz-node-exporter
  systemctl enable crond && systemctl restart crond
  systemctl enable rsyslog && systemctl restart rsyslog
  echo 'update nz-node-exporter success !'
fi
