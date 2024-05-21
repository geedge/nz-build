#!/bin/bash

WORK_DIR=/opt/nezha/ipmi_exporter

fn_init_service(){
    cat > /usr/lib/systemd/system/nz-ipmi-exporter.service <<"EOF"
[Unit]
Description=nz-ipmi-exporter
After=network.target
[Service]
WorkingDirectory=/opt/nezha/ipmi_exporter
EnvironmentFile=-/opt/nezha/ipmi_exporter/config.conf
ExecStart=/opt/nezha/ipmi_exporter/ipmi_exporter $OPTION
RestartSec=10s
Restart=always
LimitNOFILE=524288
[Install]
WantedBy=multi-user.target
EOF
}

fn_init_config(){
    cat > /opt/nezha/ipmi_exporter/config.conf <<EOF
OPTION=" --web.listen-address='0.0.0.0:19290' --config.file='/opt/nezha/ipmi_exporter/ipmi_local.yml' "
EOF
}

# 初始化 rsyslog & logrotate 配置
fn_init_syslog_logrotate_config(){
  cat > /etc/rsyslog.d/nz-ipmi-exporter.conf << "EOF"
if $programname == 'ipmi_exporter' then {
    /var/log/nezha/nz-ipmi-exporter/nz-ipmi-exporter.log
    stop
}
EOF
  cat > /etc/logrotate.d/nz-ipmi-exporter << "EOF"
/var/log/nezha/nz-ipmi-exporter/*.log {
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
# $1 需要还原的文件目录 /opt/nezha/ipmi_exporter
# $2 备份文件目录       /tmp/nezha/ipmi_exporter
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

  # 检查命令是否存在，以此判断是否存在 freeipmi 依赖
  if ! command -v bmc-info &> /dev/null ||
     ! command -v ipmimonitoring &> /dev/null ||
     ! command -v ipmi-dcmi &> /dev/null ||
     ! command -v ipmi-sel &> /dev/null; then

    echo 'freeipmi not found, install freeipmi-1.5.7-3.el7.x86_64.rpm'
    (
      sleep 5s
      rpm -ivh /opt/nezha/ipmi_exporter/deps/freeipmi-1.5.7-3.el7.x86_64.rpm &> /dev/null
    ) &
  else
    echo 'freeipmi already exists'
  fi

  systemctl daemon-reload
  systemctl enable nz-ipmi-exporter && systemctl restart nz-ipmi-exporter
  systemctl enable crond && systemctl restart crond
  systemctl enable rsyslog && systemctl restart rsyslog
  echo 'install nz-ipmi-exporter success !'
fi

# update
if [ 2 -eq $1 ];then
  fn_init_config
  fn_init_service
  fn_init_syslog_logrotate_config

  # restore nz-ipmi-exporter config
  NZ_IPMI_EXPORTER_PATH=/opt/nezha/ipmi_exporter
  TMP_PATH=/tmp/nezha/ipmi_exporter
  echo 'move backup config file...'
  if [ -d $TMP_PATH ];then
    restoreComponentConfig $NZ_IPMI_EXPORTER_PATH $TMP_PATH
  fi

  # restart all components
  systemctl daemon-reload
  systemctl enable nz-ipmi-exporter && systemctl restart nz-ipmi-exporter
  systemctl enable crond && systemctl restart crond
  systemctl enable rsyslog && systemctl restart rsyslog
  echo 'update nz-ipmi-exporter success !'
fi
