#!/bin/bash
set -ex

WORKSPACE=/opt/ServerStatus
mkdir -p ${WORKSPACE}
cd ${WORKSPACE}

# 下载, arm 机器替换 x86_64 为 aarch64
OS_ARCH="x86_64"
latest_version=$(curl -m 10 -sL "https://api.github.com/repos/zdz/ServerStatus-Rust/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

apt install unzip -y

wget --no-check-certificate -qO "client-${OS_ARCH}-unknown-linux-musl.zip"  "https://github.com/zdz/ServerStatus-Rust/releases/download/${latest_version}/client-${OS_ARCH}-unknown-linux-musl.zip"

unzip -o "client-${OS_ARCH}-unknown-linux-musl.zip"

if [ $# -eq 0 ]; then
    ip=$(curl -4 ip.sb)
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        echo $ip
    else
        echo "can not get ip"
        exit 1
    fi
else
    ip=$1
fi

sed -i "/ExecStart=\/opt\/ServerStatus\/stat_client/c\ExecStart=\/opt\/ServerStatus\/stat_client -a \"http://45.159.48.59:8090/report\" -g g1 -p pp --alias ${ip} --disable-ping" stat_client.service

# systemd service
mv -v stat_client.service /etc/systemd/system/stat_client.service

systemctl daemon-reload

systemctl enable stat_client

# 启动
systemctl start stat_client

# 状态查看
systemctl status stat_client

