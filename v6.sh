#!/bin/bash

#检测root账户
[ $(id -u) != "0" ] && { echo "请切换至root账户执行此脚本."; exit 1; }

#全局变量
server_ip=`curl -s https://app.52ll.win/ip/api.php`
separate_lines="####################################################################"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"
Libsodiumr_file="/usr/local/lib/libsodium.so"

#开始菜单
start_menu(){
clear
echo && echo -e "####################################################################
# 版本：V.2.3.5 2018-12-16                                         #
####################################################################
# [1] PM2管理后端                                                  #
# [2] Supervisor管理后端                                           #
# [3] 修改ssr节点配置                                              #
# [4] 安装ssr节点（肥羊）                                          #
# [5] 后端更多选项                                                 #
# [6] 一键安装加速                                                 #
# [7] 一键服务器测速                                               #
# [8] 更多功能                                                     #
####################################################################
# [a]卸载各类云盾 [b]查看回程路由 [c]简易测速 [d]检测BBR安装状态   #
# [e]配置防火墙 [f]列出开放端口 [g]更换默认源                      #
####################################################################
# [x]刷新脚本 [y]更新脚本 [z]退出脚本                              #
# 此服务器IP信息：${server_ip_info}
####################################################################"

read -e -p "请选择安装项[1-8]/[a-g]:" num
clear
case "$num" in
	1)
	pm2_list;;
	2)
	supervisor_list;;
	3)
	modify_node_info;;
	4)
	install_node;;
	5)
	python_more;;
	6)
	serverspeeder;;
	7)
    speedtest;;
	8)
	system_more;;
	a)
	uninstall_ali_cloud_shield;;
	b)
    detect_backhaul_routing;;
	c)
	superspeed;;
	d)
	check_bbr_installation;;
	e)
	configure_firewall;;
	f)
	yum install -y net-tools;netstat -lnp;;
	g)
	replacement_of_installation_source;;
	x)
	rm -rf /usr/bin/v6 && cp /root/v6.sh /usr/bin/v6 && chmod +x /usr/bin/v6
	v3;;
	y)
	update_the_shell;;
	z)
	echo "已退出.";exit 0;;
	*)
	clear
	echo -e "${Error}:请输入正确指令"
	sleep 2s
	start_menu
	;;
esac
}

keep_loop(){
#继续还是中止
echo ${separate_lines};echo -n "继续(y)还是中止(n)? [y/n]:"
	read -e -p "(默认: n):" yn
	[[ -z ${yn} ]] && yn="n"
	if [[ ${yn} == [Nn] ]]; then
	echo "已取消..." && exit 1
	else
		clear
		sleep 2s
		start_menu
	fi
}

reboot_system(){
	read -e -p "需重启服务器使配置生效,现在重启? [y/n]" is_reboot
	if [ ${is_reboot} = 'y' ]; then
		reboot
	else
		echo "需重启服务器使配置生效,稍后请务必手动重启服务器.";exit
	fi
}

#检查系统版本
check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	        fi
}

#PM2-[1]
pm2_list(){
	echo "选项：[1]安装PM2 [2]配置PM2 [3]更新PM2 [4]卸载PM2"
	read pm2_option
	if [ ${pm2_option} = '1' ]; then
        install_pm2
    elif [ ${pm2_option} = '2' ]; then
        check_sys
        echo "$release"
        if [ ${release} = 'centos' ]; then
			use_centos_pm2
		else
			use_debian_pm2
		fi
    elif [ ${pm2_option} = '3' ]; then
        if [ ! -f /usr/bin/pm2 ]; then
            install_pm2
        else
            update_pm2
        fi
    elif [ ${pm2_option} = '4' ]; then
            if [ ! -f /usr/bin/pm2 ]; then
            echo "已经卸载pm2"
        else
            remove_pm2
        fi
	else
	echo "选项不在范围,操作中止.";exit 0
	fi
}

install_pm2(){
        #检查系统版本
        check_sys

	#判断/usr/bin/pm2文件是否存在
	if [ ! -f /usr/bin/pm2 ]; then
        echo "检查到您未安装pm2,脚本将先进行安装"
        #安装Node.js
        if [[ ${release} = "centos" ]]; then
            yum -y install xz
            yum -y install wget
            wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc && /usr/bin/chattr +i /etc/resolv.conf
        else
            apt -y install xz
            apt -y install wget
        fi
	    #编译Node.js
        wget -N https://nodejs.org/dist/v9.11.2/node-v9.11.2-linux-x64.tar.xz
        tar -xvf node-v9.11.2-linux-x64.tar.xz
        #设置权限
        chmod +x /root/node-v9.11.2-linux-x64/bin/node
        chmod +x /root/node-v9.11.2-linux-x64/bin/npm
        #创建软连接
        rm -rf "/usr/bin/node"
        rm -rf "/usr/bin/npm"
        ln -s /root/node-v9.11.2-linux-x64/bin/node /usr/bin/node
        ln -s /root/node-v9.11.2-linux-x64/bin/npm /usr/bin/npm
        #升级Node
        npm i -g npm
        npm install -g npm
        #安装PM2
        npm install -g pm2 --unsafe-perm
    	 #创建软连接x2
    	if [ ! -f /usr/bin/pm2 ]; then
    		ln -s /root/node-v9.11.2-linux-x64/bin/pm2 /usr/bin/pm2
        else
    	    rm -rf "/usr/bin/pm2"
    	    ln -s /root/node-v9.11.2-linux-x64/bin/pm2 /usr/bin/pm2
        fi
        rm -rf /root/*.tar.xz
	else
		echo "已经安装pm2，请配置pm2"
	fi
}

use_centos_pm2(){
    if [ ! -f /usr/bin/killall ]; then
	    echo "检查到您未安装psmisc,脚本将先进行安装"
	    yum -y update
	    yum -y install psmisc
    fi

    #清空
    pm2 delete all

    #判断内存
    all=`free -m | awk 'NR==2' | awk '{print $2}'`
    used=`free -m | awk 'NR==2' | awk '{print $3}'`
    free=`free -m | awk 'NR==2' | awk '{print $4}'`

    echo "Memory usage | [All：${all}MB] | [Use：${used}MB] | [Free：${free}MB]"
    sleep 2s
    #判断几个后端
    ssr_dirs=()
    while IFS=  read -r -d $'\0'; do
        ssr_dirs+=("$REPLY")
    done < <(find /root/  -maxdepth 1 -name "shadowsocks*" -print0)

    ssr_names=()
    for ssr_dir in "${ssr_dirs[@]}"
    do
        ssr_names+=($(basename "$ssr_dir"))
    done

    max_memory_limit=512
    if [ $all -le 256 ] ; then
        max_memory_limit=192
    elif [ $all -le 512 ] ; then
        max_memory_limit=320
    fi

    for ssr_name in "${ssr_names[@]}"
    do
        pm2 start /root/${ssr_name}/server.py --name $(echo ${ssr_name} | sed 's/shadowsocks-//') --max-memory-restart ${max_memory_limit}M  -o /dev/null/out-${ssr_name}.log -e /dev/null/error-${ssr_name}.log
    done


    sleep 2s
    #创建快捷方式
    rm -rf "/usr/bin/srs"
    echo "#!/bin/bash" >> /usr/bin/srs
	echo "pm2 restart all" >> /usr/bin/srs
	chmod +x /usr/bin/srs

	rm -rf "/usr/bin/ssrr"
	echo "#!/bin/bash" >> /usr/bin/ssrr
	for ssr_name in "${ssr_names[@]}"
	do
	    echo "pm2 start /root/${ssr_name}/server.py --name $(echo ${ssr_name} | sed 's/shadowsocks-//') --max-memory-restart ${max_memory_limit}M  -o /dev/null/out-${ssr_name}.log -e /dev/null/error-${ssr_name}.log" >> /usr/bin/ssrr
    done
	chmod +x /usr/bin/ssrr

    #创建pm2日志清理
    cp "/var/spool/cron/root" "/var/spool/cron/root.bak"
    rm -rf "/var/spool/cron/root"
    if [ ! -f /root/ddns/nc-ddns.sh ] ; then
        echo "未检测到nc-ddns.sh"
    else
	    echo "添加DDNS定时启动"
        sleep 2s
        echo '###DDNS' >> /var/spool/cron/root
        echo '*/10 * * * * bash /root/ddns/nc-ddns.sh >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    fi
    if [ ! -f /root/Application/telegram-socks/server.js ] ; then
        echo "未检测到socks5"
    else
	    echo "添加socks5定时启动"
        sleep 2s
        echo '###Socks5' >> /var/spool/cron/root
        echo '* */1 * * * systemctl restart telegram >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    fi
    if [ ! -f /usr/local/gost/gostproxy ] ; then
        echo "未检测到gost"
    else
	    echo "添加gost定时启动"
        sleep 2s
        echo '###Gost' >> /var/spool/cron/root
        echo '0 3 * * * gost start >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    fi
    #PM2定时重启
    echo '#DaliyJob' >> /var/spool/cron/root
    echo '1 */6 * * * pm2 flush >> /dev/null/cron_log.txt' >> /var/spool/cron/root
	echo '2 3 * * 1 srs >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    #清理缓存
    echo '5 3 * * * sync && echo 1 > /proc/sys/vm/drop_caches >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    echo '10 3 * * * sync && echo 2 > /proc/sys/vm/drop_caches >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    echo '15 3 * * * sync && echo 3 > /proc/sys/vm/drop_caches >> /dev/null/cron_log.txt' >> /var/spool/cron/root
	#重启cron并备份
    /sbin/service crond restart
    cp /var/spool/cron/root /var/spool/cron/v3root.bak
    #查看cron进程
    crontab -l
    sleep 2s
    #创建开机自启动
	pm2 save
	pm2 startup
	#完成提示
	clear;echo "########################################
# SS NODE 已安装完成                   #
########################################
# 启动SSR：pm2 start ssr               #
# 停止SSR：pm2 stop ssr                #
# 重启SSR：pm2 restart ssr             #
# 或：srs                              #
########################################"
}

use_debian_pm2(){
    if [ ! -f /usr/bin/killall ]; then
	    echo "检查到您未安装psmisc,脚本将先进行安装"
	    apt-get install psmisc
    fi
	#清空
    pm2 delete all
    #判断内存
    all=`free -m | awk 'NR==2' | awk '{print $2}'`
    used=`free -m | awk 'NR==2' | awk '{print $3}'`
    free=`free -m | awk 'NR==2' | awk '{print $4}'`
    echo "Memory usage | [All：${all}MB] | [Use：${used}MB] | [Free：${free}MB]"
    sleep 2s
    #判断几个后端
    ssr_dirs=()
    while IFS=  read -r -d $'\0'; do
        ssr_dirs+=("$REPLY")
    done < <(find /root/  -maxdepth 1 -name "shadowsocks*" -print0)
    ssr_names=()
    for ssr_dir in "${ssr_dirs[@]}"
    do
        ssr_names+=($(basename "$ssr_dir"))
    done

	max_memory_limit=320
    if [ $all -le 256 ] ; then
        max_memory_limit=192
    elif [ $all -le 512 ] ; then
        max_memory_limit=300
    fi

    for ssr_name in "${ssr_names[@]}"
    do
        pm2 start /root/${ssr_name}/server.py --name $(echo ${ssr_name} | sed 's/shadowsocks-//') --max-memory-restart ${max_memory_limit}M  -o /dev/null/out-${ssr_name}.log -e /dev/null/error-${ssr_name}.log
    done
    sleep 2s
    #创建快捷方式
    rm -rf "/usr/bin/srs"
    echo "#!/bin/bash" >> /usr/bin/srs
    for ssr_name in "${ssr_names[@]}"
    do
	    echo "pm2 restart all" >> /usr/bin/srs
    done
	chmod +x /usr/bin/srs

	rm -rf "/usr/bin/ssrr"
	echo "#!/bin/bash" >> /usr/bin/ssrr
	for ssr_name in "${ssr_names[@]}"
	do
	    echo "pm2 start /root/${ssr_name}/server.py --name $(echo ${ssr_name} | sed 's/shadowsocks-//') --max-memory-restart ${max_memory_limit}M  -o /dev/null/out-${ssr_name}.log -e /dev/null/error-${ssr_name}.log" >> /usr/bin/ssrr
    done
	chmod +x /usr/bin/ssrr
    #创建pm2日志清理
    rm -rf "/var/spool/cron/crontabs/root"
    if [ ! -f /root/ddns/nc-ddns.sh ] ; then
            echo "未检测到nc-ddns.sh"
    else
	    echo "添加DDNS定时启动"
        sleep 2s
        echo '###DDNS' >> /var/spool/cron/crontabs/root
        echo '*/10 * * * * bash /root/ddns/nc-ddns.sh >> /dev/null/cron_log.txt' >> /var/spool/cron/crontabs/root
    fi

    if [ ! -f /usr/local/gost/gostproxy ] ; then
        echo "未检测到gost"
    else
    	#Gost定时重启
	    echo "添加gost定时启动"
        sleep 2s
        echo '###Gost' >> /var/spool/cron/crontabs/root
        echo '0 1 * * * gost start >> /dev/null/cron_log.txt' >> /var/spool/cron/crontabs/root
    fi
    #PM2定时重启
    echo '#DaliyJob' >> /var/spool/cron/root
    echo '1 */6 * * * pm2 flush >> /dev/null/cron_log.txt' >> /var/spool/cron/root
	echo '2 3 * * 1 srs >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    #清理缓存
    echo '5 3 * * * sync && echo 1 > /proc/sys/vm/drop_caches >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    echo '10 3 * * * sync && echo 2 > /proc/sys/vm/drop_caches >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    echo '15 3 * * * sync && echo 3 > /proc/sys/vm/drop_caches >> /dev/null/cron_log.txt' >> /var/spool/cron/root
    #cron重启
    service cron restart
    service cron reload
    #查看cron进程
    crontab -l
    sleep 2s
    #创建开机自启动
	pm2 save
	pm2 startup
	#完成提示
	clear;echo "########################################
# SS NODE 已安装完成                   #
########################################
# 启动SSR：pm2 start ssr               #
# 停止SSR：pm2 stop ssr                #
# 重启SSR：pm2 restart ssr             #
# 或：srs                              #
########################################"
}

update_pm2(){
    #更新node.js
	npm i -g npm
	npm install -g npm
    #更新PM2
    npm install pm2@latest -g
    #PM2 update
    sleep 1s
    pm2 save
    pm2 update
    pm2 startup
}

remove_pm2(){
	if [ ! -f /usr/bin/pm2 ]; then
		echo "PM2已卸载"
	else
		npm uninstall -g pm2
		sleep 1s
		npm uninstall -g npm
		sleep 1s
		#卸载Node.js
		rm -rf "/usr/bin/node"
	    rm -rf "/usr/bin/npm"
	    rm -rf "/root/.npm"
        #卸载PM2
		rm -rf "/usr/bin/pm2"
		rm -rf "/root/.pm2"
		rm -rf /root/node*
		sleep 1s
		echo "PM2完成卸载"
		fi
}

#supervisor-[2]
supervisor_list(){
	#检查 Root账户
	[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
        #检查系统版本
        check_sys

	echo "选项：[1]安装supervisor [2]卸载supervisor [3]强制重启supervisor"
	read super_option
	if [ ${super_option} = '1' ]; then
           install_supervisor_for_each
        elif [ ${super_option} = '2' ]; then
    	   remove_supervisor_for_each
	elif [ ${super_option} = '3' ]; then
    	   kill_supervisor
	else
           echo "选项不在范围,操作中止.";exit 0
	fi
}

install_supervisor_for_each(){
    #检查系统版本
    check_sys
	if [[ ${release} = "centos" ]]; then
		install_centos_supervisor
	else
		echo "暂时只完美支持Centos,请更换PM2管理";exit 0
	fi
}

remove_supervisor_for_each(){
	#检查系统版本
    check_sys
	if [[ ${release} = "centos" ]]; then
		remove_centos_supervisor
	else
		remove_debian_supervisor
	fi
}

install_centos_supervisor(){
	#判断/usr/bin/supervisord文件是否存在
	if [ ! -f /usr/bin/supervisord ]; then
		#判断/usr/bin/killall文件是否存在
	    if [ ! -f /usr/bin/killall ]; then
	        echo "检查到您未安装psmisc,脚本将先进行安装"
	        yum -y update
	        yum -y install psmisc
	    fi
	    echo "开始卸载supervisor"
        yum -y remove supervisor
        rm -rf "/etc/supervisord.conf"
        rm -rf "/usr/bin/srs"
        yum -y install supervisor
        #启用supervisord
        echo_supervisord_conf > /etc/supervisord.conf
        sed -i '$a [program:ssr]\ncommand = python /root/shadowsocks/server.py\nuser = root\nautostart = true\nautorestart = true' /etc/supervisord.conf
        supervisord
        #iptables
        iptables -F
        iptables -X
        iptables -I INPUT -p tcp -m tcp —dport 104 -j ACCEPT
        iptables -I INPUT -p udp -m udp —dport 104 -j ACCEPT
        iptables -I INPUT -p tcp -m tcp —dport 1024: -j ACCEPT
        iptables -I INPUT -p udp -m udp —dport 1024: -j ACCEPT
        iptables-save >/etc/sysconfig/iptables
        echo 'iptables-restore /etc/sysconfig/iptables' » /etc/rc.local
        echo "/usr/bin/supervisord -c /etc/supervisord.conf" » /etc/rc.local
        #创建快捷重启命令
        echo "#!/bin/bash" » /usr/bin/srs
        echo "supervisorctl restart ssr" » /usr/bin/srs
        chmod +x /usr/bin/srs
        #最后配置
        #/usr/bin/supervisord -c /etc/supervisord.conf
        srs
        #开机自启
        curl https://raw.githubusercontent.com/Supervisor/initscripts/master/centos-systemd-etcs > supervisord.service
        mv supervisord.service /etc/systemd/system
        chmod 644 /etc/systemd/system/supervisord.service
        systemctl daemon-reload
        systemctl start supervisord.service
        systemctl enable supervisord
        systemctl is-enabled supervisord
	else
	    echo "已经安装supervisor";exit 0
    fi
}

remove_debian_supervisor(){
	#判断/usr/bin/supervisord文件是否存在
	if [ ! -f /usr/bin/supervisord ]; then
		echo "已经卸载supervisor";exit 0
	else
	    if [ ! -f /usr/bin/killall ]; then
	        echo "检查到您未安装psmisc,脚本将先进行安装"
	        apt-get install psmisc
        else
	        echo "现在开始卸载supervisor"
            killall supervisord
	        killall supervisord
	        killall supervisord
	        killall supervisord
	        apt-get remove --purge supervisor -y
            rm -rf "/etc/supervisord.conf"
            rm -rf "/usr/bin/srs"
        fi
	fi
}

remove_centos_supervisor(){
	#判断/usr/bin/supervisord文件是否存在
	if [ ! -f /usr/bin/supervisord ]; then
	    echo "已经卸载supervisor";exit 0
	else
	    if [ ! -f /usr/bin/killall ]; then
	        echo "检查到您未安装psmisc,脚本将先进行安装"
            yum -y update
	        yum -y install psmisc
        fi
	    echo "现在开始卸载supervisor"
        killall supervisord
	    killall supervisord
	    killall supervisord
	    killall supervisord
	    yum -y remove supervisor
        rm -rf "/etc/supervisord.conf"
        rm -rf "/usr/bin/srs"
	fi
}

kill_supervisor(){
    #检查系统版本
    check_sys
	#判断/usr/bin/killall文件是否存在
	if [ ! -f /usr/bin/killall ]; then
	    echo "检查到您未安装psmisc,脚本将先进行安装..."
	    if [[ ${release} = "centos" ]]; then
	        yum -y update
	        yum -y install psmisc
	    else
	        apt-get -y update
            apt-get -y install psmisc
	    fi
        killall supervisord
	    killall supervisord
	    killall supervisord
	    killall supervisord
	    supervisord
	else
	    killall supervisord
	    killall supervisord
	    killall supervisord
	    killall supervisord
	    supervisord
	fi
}


#节点-[3]
modify_node_info(){
	#检测
	if [ ! -f /root/shadowsocks/userapiconfig.py ]; then
		echo "ssr服务端未安装,不能执行该选项.";exit
	else
		#清屏
		clear
		#输出当前节点配置
		echo "当前节点配置如下:"
		echo "------------------------------------"
		sed -n '3p' /root/shadowsocks/userapiconfig.py
		sed -n '17,18p' /root/shadowsocks/userapiconfig.py
		echo "------------------------------------"
		#获取新节点配置信息
		read -e -p "新的前端地址是:" Userdomain
		read -e -p "新的节点ID是:" UserNODE_ID
		read -e -p "新的MuKey是:" Usermukey

		#检查
		if [ ! -f /root/shadowsocks/userapiconfig.py.bak ]; then
			wget https://github.com/Super-box/v3/raw/master/userapiconfig.py
		else
			#还原
			rm -rf /root/shadowsocks/userapiconfig.py
			cp /root/shadowsocks/userapiconfig.py.bak /root/shadowsocks/userapiconfig.py
		fi

		#修改
		Userdomain=${Userdomain:-"http://${server_ip}"}
		sed -i "s#http://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
		Usermukey=${Usermukey:-"mupass"}
		sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
		UserNODE_ID=${UserNODE_ID:-"3"}
		sed -i '2d' /root/shadowsocks/userapiconfig.py
		sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	fi
}

#安装后端-[4]
Libtest(){
	#自动选择下载节点
	GIT='raw.githubusercontent.com'
	LIB='download.libsodium.org'
	GIT_PING=`ping -c 1 -w 1 $GIT|grep time=|awk '{print $7}'|sed "s/time=//"`
	LIB_PING=`ping -c 1 -w 1 $LIB|grep time=|awk '{print $7}'|sed "s/time=//"`
	echo "$GIT_PING $GIT" > ping.pl
	echo "$LIB_PING $LIB" >> ping.pl
	libAddr=`sort -V ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$libAddr" == "$GIT" ]; then
		libAddr='https://github.com/Super-box/v3/raw/master/libsodium-1.0.16.tar.gz'
	else
		libAddr='https://download.libsodium.org/libsodium/releases/libsodium-1.0.16.tar.gz'
	fi
	rm -f ping.pl
}

Get_Dist_Version()
{
    if [ -s /usr/bin/python3 ]; then
        Version=`/usr/bin/python3 -c 'import platform; print(platform.linux_distribution()[1][0])'`
    elif [ -s /usr/bin/python2 ]; then
        Version=`/usr/bin/python2 -c 'import platform; print platform.linux_distribution()[1][0]'`
    fi
}


install_centos_ssr(){
    read -e -p "后端名字是:(默认: idou):" Username
	[[ -z ${Username} ]] && Username="idou"

	git clone -b 456Dev "https://github.com/old-boys/shadowsocks.git" "/root/shadowsocks-${Username}"

	read -e -p "节点ID是:" UserNodeId
	read -e -p "数据库地址是:" UserDbHost
	read -e -p "数据库名称:" UserDbName
	read -e -p "数据库用户:" UserDbUser
	read -e -p "数据库密码:" UserDbPass

    sed -i "2s#1#${UserNodeId}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "27s#127.0.0.1#${UserDbHost}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "29s#ss#${UserDbUser}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "30s#ss#${UserDbPass}#" /root/shadowsocks-${Username}/userapiconfig.py
    sed -i "31s#shadowsocks#${UserDbName}#" /root/shadowsocks-${Username}/userapiconfig.py

	#更换DNS至8888/1001
    if grep -Fq "8.8.8.8" "/etc/resolv.conf"
    then
        echo "已经update resolv.conf"
    else
	    /usr/bin/chattr -i /etc/resolv.conf && wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc && /usr/bin/chattr +i /etc/resolv.conf
    fi

	cd /root
	Get_Dist_Version

	if [ ! -f /root/.update ]; then
		yum -y update --exclude=kernel*
		yum -y install git gcc python-setuptools lsof lrzsz python-devel libffi-devel openssl-devel iptables iptables-services
		yum -y groupinstall "Development Tools"
		yum -y install python-pip
		#第二次pip supervisor是否安装成功
		if [ -z "`pip`" ]; then
		curl -O https://bootstrap.pypa.io/get-pip.py
			python get-pip.py
			rm -rf *.py
		fi
		#第三次检测pip supervisor是否安装成功
		if [ -z "`pip`" ]; then
			if [ -z "`easy_install`"]; then
				wget http://peak.telecommunity.com/dist/ez_setup.py
				python ez_setup.py
			fi
			easy_install pip
		fi

		python -m pip install --upgrade pip

		pip install -I requests==2.9

		touch /root/.update
	fi


    if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "libsodium 已安装"
	else
		echo -e "libsodium 未安装，开始安装..."
        wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.13.tar.gz
	    tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	    ./configure && make -j2 && make install
	    echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
        ldconfig
    fi

	cd /root/shadowsocks-${Username}

	#第一次安装
	pip install -r requirements.txt

	#第二次检测是否成功
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
		mkdir python && cd python
		git clone https://github.com/shazow/urllib3.git && cd urllib3
		python setup.py install && cd ..
		git clone https://github.com/nakagami/CyMySQL.git && cd CyMySQL
		python setup.py install && cd ..
		git clone https://github.com/requests/requests.git && cd requests
		python setup.py install && cd ..
		git clone https://github.com/pyca/pyopenssl.git && cd pyopenssl
		python setup.py install && cd ..
		git clone https://github.com/cedadev/ndg_httpsclient.git && cd ndg_httpsclient
		python setup.py install && cd ..
		git clone https://github.com/etingof/pyasn1.git && cd pyasn1
		python setup.py install && cd ..
		rm -rf python
	fi
	systemctl stop firewalld.service
	systemctl disable firewalld.service
}

install_ubuntu_ssr(){
    read -e -p "后端名字是:(默认: idou):" Username
	[[ -z ${Username} ]] && Username="idou"

	git clone -b 456Dev "https://github.com/old-boys/shadowsocks.git" "/root/shadowsocks-${Username}"

	if [ ! -f /root/.update ]; then
		apt-get -y update
		apt-get -y install build-essential wget iptables git supervisor lsof python-pip
		pip install -I requests==2.9

		touch /root/.update
	fi

	#更换DNS至8888/1001
    if grep -Fq "8.8.8.8" "/etc/resolv.conf"
    then
        echo "已经update resolv.conf"
    else
	    /usr/bin/chattr -i /etc/resolv.conf && wget -N https://github.com/Super-box/v3/raw/master/resolv.conf -P /etc && /usr/bin/chattr +i /etc/resolv.conf
    fi

	#编译安装libsodium
    if [[ -e ${Libsodiumr_file} ]]; then
		echo -e "libsodium 已安装"
	else
		echo -e "libsodium 未安装，开始安装..."
        wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.13.tar.gz
	    tar xf libsodium-1.0.13.tar.gz && cd libsodium-1.0.13
	    ./configure && make -j2 && make install
	    echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
        ldconfig
    fi

	pip install cymysql -i https://pypi.org/simple/

	#clone shadowsocks

	cd /root
	cd /root/shadowsocks-${Username}

	#第一次安装
	pip install -r requirements.txt
	#第二次检测是否成功
	if [ -z "`python -c 'import requests;print(requests)'`" ]; then
		mkdir python && cd python
		git clone https://github.com/shazow/urllib3.git && cd urllib3
		python setup.py install && cd ..
		git clone https://github.com/nakagami/CyMySQL.git && cd CyMySQL
		python setup.py install && cd ..
		git clone https://github.com/requests/requests.git && cd requests
		python setup.py install && cd ..
		git clone https://github.com/pyca/pyopenssl.git && cd pyopenssl
		python setup.py install && cd ..
		git clone https://github.com/cedadev/ndg_httpsclient.git && cd ndg_httpsclient
		python setup.py install && cd ..
		git clone https://github.com/etingof/pyasn1.git && cd pyasn1
		python setup.py install && cd ..
		rm -rf python
	fi
	chmod +x *.sh
}


install_node(){
	#check os version
	check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	    fi
		bit=`uname -m`
	}
	install_ssr_for_each(){
		check_sys
		if [[ ${release} = "centos" ]]; then
			install_pm2
			install_centos_ssr
			use_centos_pm2
		else
			install_pm2
			install_ubuntu_ssr
			use_debian_pm2
		fi
	}

    install_ssr_for_each
	# 取消文件数量限制
	sed -i '$a * hard nofile 512000\n* soft nofile 512000' /etc/security/limits.conf
    iptables -P INPUT ACCEPT
    iptables -F
    iptables -X


#########################################################################################"
	clear;echo "########################################
# SS NODE 已安装完成                   #
########################################
# 启动SSR：pm2 start ssr               #
# 停止SSR：pm2 stop ssr                #
# 重启SSR：pm2 restart ssr             #
# 或：srs                              #
########################################"
}

#More-[5]
python_more(){
    echo "选项：[1]安装Gost服务器 [2]Git更新后端 [3]安装ocserv"
	read more_option
	if [ ${more_option} = '1' ]; then
		install_gost
	elif [ ${more_option} = '2' ]; then
		git_update
	elif [ ${more_option} = '3' ]; then
		install_ocserv
	else
		echo "选项不在范围,操作中止.";exit 0
	fi
}

install_gost(){
           #检查文件gost.sh是否存在,若不存在,则下载该文件
		if [ ! -f /root/gost.sh ]; then
		   wget -N --no-check-certificate https://code.aliyun.com/supppig/gost/raw/master/gost.sh
            chmod +x gost.sh
            fi
            bash gost.sh
	    }

git_update(){
                if [ ! -f /root/shadowsocks/userapiconfig.py ]; then
		        echo "Tan90°"
                else
	         	git clone -b manyuser https://github.com/Super-box/p3.git
                        \cp -r -f /root/p3/* /root/shadowsocks
			rm -rf /root/p3
                fi
        }
install_ocserv(){
        check_sys
        echo "$release"
        if [ ${release} = 'centos' ]; then
        	yum update -y
	        yum install ocserv radiusclient-ng unzip -y

                if ! wget -N --no-check-certificate https://github.com/Super-box/a5/raw/master/ocserv.zip -O /etc/ocserv.zip; then
		    echo -e "${Error} ocserv 服务 配置文件下载失败 !" && exit
	        fi
            unzip -o /etc/ocserv.zip -d /etc

                if ! wget -N --no-check-certificate https://github.com/Super-box/a5/raw/master/radiusclient-ng.zip -O /etc/radiusclient-ng.zip; then
		    echo -e "${Error} radius 服务 配置文件下载失败 !" && exiy
	        fi
                unzip -o /etc/radiusclient-ng.zip -d /etc

                if ! wget -N --no-check-certificate https://github.com/Super-box/v3/raw/master/setiptables.sh -O /root/setiptables.sh; then
                echo -e "${Error} iptables文件下载失败 !" && exit
	        fi
	            chmod +x /root/setiptables.sh
                bash /root/setiptables.sh
                rm -rf /root/setiptables.sh

                if ! wget --no-check-certificate https://raw.githubusercontent.com/ToyoDAdoubi/doubi/master/service/ocserv_debian -O /etc/init.d/ocserv; then
		        echo -e "${Error} ocserv 服务 管理脚本下载失败 !" && exit
	        fi
	            chmod +x /etc/init.d/ocserv
	            echo -e "${Info} ocserv 服务 管理脚本下载完成 !"
                /etc/rc.d/init.d/ocserv stop
	            chkconfig --add /etc/rc.d/init.d/ocserv
	            chkconfig /etc/rc.d/init.d/ocserv on
	            systemctl enable ocserv.service
	            systemctl restart ocserv.service
	            systemctl status ocserv.service
		else
			echo "懒得写了"

		fi
        }

#一键安装加速-[6]
serverspeeder(){
	echo "选项：[1]KVM安装 [2]OVZ安装"
	read serverspeeder_option
	if [ ${serverspeeder_option} = '1' ]; then
		#检查文件tcp.sh是否存在,若不存在,则下载该文件
	    if [ ! -f /root/tcp.sh ]; then
		wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
		chmod +x tcp.sh
	    fi
	    #执行
		./tcp.sh
	elif [ ${serverspeeder_option} = '2' ]; then
		#检查文件tcp.sh是否存在,若不存在,则下载该文件
		check_sys
		echo "$release"
		if [ ${release} = 'centos' ]; then
			wget -N --no-check-certificate "https://github.com/tcp-nanqinlang/lkl-rinetd/releases/download/1.1.0/tcp_nanqinlang-rinetd-centos.sh"
            chmod +x tcp_nanqinlang-rinetd-centos.sh
            ./tcp_nanqinlang-rinetd-centos.sh
		else
			wget -N --no-check-certificate "https://github.com/tcp-nanqinlang/lkl-rinetd/releases/download/1.1.0/tcp_nanqinlang-rinetd-debianorubuntu.sh"
            chmod +x tcp_nanqinlang-rinetd-debianorubuntu.sh
            ./tcp_nanqinlang-rinetd-debianorubuntu.sh
		fi
	fi
}

#一键全面测速-[7]
speedtest(){
	#检查文件ZBench-CN.sh是否存在,若不存在,则下载该文件
	if [ ! -f /root/ZBench-CN.sh ]; then
		wget https://raw.githubusercontent.com/FunctionClub/ZBench/master/ZBench-CN.sh
		chmod +x ZBench-CN.sh
	fi
	   #执行测试
	   bash /root/ZBench-CN.sh
}

#More-[8]
system_more(){
    echo "选项：[1]添加SWAP [2]更改SSH端口 [3]DDNS动态脚本"
	read more_option
        if [ ${more_option} = '1' ]; then
            swap
	    elif [ ${more_option} = '2' ]; then
		    install_ssh_port
	    elif [ ${more_option} = '3' ]; then
	        ddns
	    else
		    echo "选项不在范围,操作中止.";exit 0
	    fi
}

swap(){
	echo "选项：[1]500M [2]1G [3]删除SWAP"
		read swap
	if [ ${swap} = '1' ]; then
		#判断/var/swapfile1文件是否存在
		if [ ! -f /var/swapfile1 ]; then
			#增加500Mb的Swap分区
			dd if=/dev/zero of=/var/swapfile1 bs=1024 count=512000
			mkswap /var/swapfile1;chmod 0644 /var/swapfile1;swapon /var/swapfile1
			echo "/var/swapfile1 swap swap defaults 0 0" >> /etc/fstab
			echo "已经成功添加SWAP"
		else
			echo "检查到您已经添加SWAP,无需重复添加"
		fi

	elif [ ${swap} = '2' ]; then
		#判断/var/swapfile1文件是否存在
		if [ ! -f /var/swapfile1 ]; then
		dd if=/dev/zero of=/var/swapfile1 bs=1024 count=1048576
	        mkswap /var/swapfile1;chmod 0644 /var/swapfile1;swapon /var/swapfile1
	        echo '/var/swapfile1 swap swap default 0 0' >> /etc/fstab
	        echo "已经成功添加SWAP"
		else
			echo "检查到您已经添加SWAP,无需重复添加"
		fi

	elif [ ${swap} = '3' ]; then
		#判断/var/swapfile1文件是否存在
		if [ ! -f /var/swapfile1 ]; then
 		    echo "检查到您未添加SWAP"
		else
	        swapoff /var/swapfile1
                sed -i "/swapfile1/d" /etc/fstab
                rm -rf /var/swapfile1
		fi
	else
		echo "选项不在范围.";exit 0
	fi
}

install_ssh_port(){
	#检查文件sshport.sh是否存在,若不存在,则下载该文件
	if [ ! -f /root/sshport.sh ]; then
		wget -N —no-check-certificate https://www.moerats.com/usr/down/sshport.sh
	    chmod +x sshport.sh
	fi
	    ./sshport.sh
        service restart sshd
}

ddns(){
    echo "选项：[1]安装 [2]配置 [3]运行"
	read ddns
	if [ ${ddns} = '1' ]; then
	    if [ ! -f /root/ddns/nc-ddns.sh ]; then
	    	echo "DDNS未配置，开始下载";
            wget -N —no-check-certificate "https://raw.githubusercontent.com/whut-share/v6/master/nc-ddns.sh" -P /root/ddns
            chmod +x /root/ddns/nc-ddns.sh
	    fi
	    #清屏
		clear
		#获取新配置信息
		read -e -p "新的Domain地址是:" NCRECORD_NAME
		#获取新配置信息
		read -e -p "新的subDomain地址是:" NCRECORD_SUB_NAME

		read -e -p "新的pass是:" NCRECORD_PASS
		#修改
        NCRECORD_NAME=${NCRECORD_NAME}
        NCRECORD_SUB_NAME=${NCRECORD_SUB_NAME}
        NCRECORD_PASS=${NCRECORD_PASS}
        sed -i "3s#cat.cc#${NCRECORD_NAME}#" /root/ddns/nc-ddns.sh
        sed -i "4s#sub.cat.cc#${NCRECORD_SUB_NAME}#" /root/ddns/nc-ddns.sh
        sed -i "5s#ncdomainpasswd#${NCRECORD_PASS}#" /root/ddns/nc-ddns.sh

		#运行
		bash /root/ddns/nc-ddns.sh

    elif [ ${ddns} = '2' ]; then
		#清屏
		clear
		#输出当前配置
		echo "当前DDNS配置如下:"
		echo "------------------------------------"
		sed -n '3p' /root/ddns/nc-ddns.sh
		sed -n '4p' /root/ddns/nc-ddns.sh
		sed -n '5p' /root/ddns/nc-ddns.sh
		echo "------------------------------------"
		#获取新配置信息
        read -e -p "新的DDNS地址是:" CFRECORD_NAME
        read -e -p "新的subDomain地址是:" NCRECORD_SUB_NAME

        rm -rf /root/ddns
        wget -N —no-check-certificate "https://raw.githubusercontent.com/whut-share/v6/master/nc-ddns.sh" -P /root/ddns
		#修改
        NCRECORD_NAME=${NCRECORD_NAME}
        NCRECORD_SUB_NAME=${NCRECORD_SUB_NAME}
        NCRECORD_PASS=${NCRECORD_PASS}
        sed -i "3s#cat.cc#${NCRECORD_NAME}#" /root/ddns/nc-ddns.sh
        sed -i "4s#sub.cat.cc#${NCRECORD_SUB_NAME}#" /root/ddns/nc-ddns.sh
        sed -i "5s#ncdomainpasswd#${NCRECORD_PASS}#" /root/ddns/nc-ddns.sh

        bash /root/ddns/nc-ddns.sh
    elif [ ${ddns} = '3' ]; then
		if [ ! -f /root/ddns/nc-ddns.sh ]; then
 		    echo "检查到您未安装ddns"
		else
	        echo "当前DDNS配置如下:"
		    echo "------------------------------------"
            sed -n '3p' /root/ddns/nc-ddns.sh
		    sed -n '4p' /root/ddns/nc-ddns.sh
		    sed -n '5p' /root/ddns/nc-ddns.sh
		    echo "------------------------------------"
		fi
		    #运行
		    bash /root/ddns/nc-ddns.sh
	else
		echo "选项不在范围.";exit 0
	fi
}

#卸载各类云盾-[a]
uninstall_ali_cloud_shield(){
	echo "请选择：[1]卸载阿里云盾 [2]卸载腾讯云盾";read uninstall_ali_cloud_shield

	if [ ${uninstall_ali_cloud_shield} = '1' ]; then
    yum -y install redhat-lsb
       var=`lsb_release -a | grep Gentoo`
    if [ -z "${var}" ]; then
	   var=`cat /etc/issue | grep Gentoo`
    fi

    if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
	   LINUX_RELEASE="GENTOO"
    else
	   LINUX_RELEASE="OTHER"
    fi

    stop_aegis(){
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 aegis_update >/dev/null 2>&1
	killall -9 aegis_cli >/dev/null 2>&1
	killall -9 AliYunDun >/dev/null 2>&1
	killall -9 AliHids >/dev/null 2>&1
	killall -9 AliYunDunUpdate >/dev/null 2>&1
    printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
    }

    remove_aegis(){
    if [ -d /usr/local/aegis ]; then
       rm -rf /usr/local/aegis/aegis_client
       rm -rf /usr/local/aegis/aegis_update
	   rm -rf /usr/local/aegis/alihids
    fi
    }

   uninstall_service() {

   if [ -f "/etc/init.d/aegis" ]; then
		/etc/init.d/aegis stop  >/dev/null 2>&1
		rm -f /etc/init.d/aegis
   fi

	if [ $LINUX_RELEASE = "GENTOO" ]; then
		rc-update del aegis default 2>/dev/null
		if [ -f "/etc/runlevels/default/aegis" ]; then
			rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
		fi
    elif [ -f /etc/init.d/aegis ]; then
         /etc/init.d/aegis  uninstall
	    for ((var=2; var<=5; var++)) do
			if [ -d "/etc/rc${var}.d/" ]; then
				 rm -f "/etc/rc${var}.d/S80aegis"
		    elif [ -d "/etc/rc.d/rc${var}.d" ]; then
				rm -f "/etc/rc.d/rc${var}.d/S80aegis"
			fi
		done
    fi

    }

    stop_aegis
    uninstall_service
    remove_aegis

    printf "%-40s %40s\n" "Uninstalling aegis"  "[  OK  ]"

    var=`lsb_release -a | grep Gentoo`
    if [ -z "${var}" ]; then
    	var=`cat /etc/issue | grep Gentoo`
    fi

    if [ -d "/etc/runlevels/default" -a -n "${var}" ]; then
    	LINUX_RELEASE="GENTOO"
    else
    	LINUX_RELEASE="OTHER"
    fi

    stop_aegis(){
    	killall -9 aegis_cli >/dev/null 2>&1
    	killall -9 aegis_update >/dev/null 2>&1
    	killall -9 aegis_cli >/dev/null 2>&1
        printf "%-40s %40s\n" "Stopping aegis" "[  OK  ]"
    }

    stop_quartz(){
    	killall -9 aegis_quartz >/dev/null 2>&1
            printf "%-40s %40s\n" "Stopping quartz" "[  OK  ]"
    }

    remove_aegis(){
    if [ -d /usr/local/aegis ]; then
        rm -rf /usr/local/aegis/aegis_client
        rm -rf /usr/local/aegis/aegis_update
    fi
    }

    remove_quartz(){
    if [ -d /usr/local/aegis ]; then
    	rm -rf /usr/local/aegis/aegis_quartz
    fi
    }


    uninstall_service() {

       if [ -f "/etc/init.d/aegis" ]; then
    		/etc/init.d/aegis stop  >/dev/null 2>&1
    		rm -f /etc/init.d/aegis
       fi

    	if [ $LINUX_RELEASE = "GENTOO" ]; then
    		rc-update del aegis default 2>/dev/null
    		if [ -f "/etc/runlevels/default/aegis" ]; then
    			rm -f "/etc/runlevels/default/aegis" >/dev/null 2>&1;
    		fi
        elif [ -f /etc/init.d/aegis ]; then
             /etc/init.d/aegis  uninstall
    	    for ((var=2; var<=5; var++)) do
    			if [ -d "/etc/rc${var}.d/" ]; then
    				 rm -f "/etc/rc${var}.d/S80aegis"
    		    elif [ -d "/etc/rc.d/rc${var}.d" ]; then
    				rm -f "/etc/rc.d/rc${var}.d/S80aegis"
    			fi
    		done
        fi

    }
            stop_aegis
            stop_quartz
            uninstall_service
            remove_aegis
            remove_quartz
            printf "%-40s %40s\n" "Uninstalling aegis_quartz"  "[  OK  ]"
            pkill aliyun-service
            rm -fr /etc/init.d/agentwatch /usr/sbin/aliyun-service
            rm -rf /usr/local/aegis*
            iptables -I INPUT -s 140.205.201.0/28 -j DROP
            iptables -I INPUT -s 140.205.201.16/29 -j DROP
            iptables -I INPUT -s 140.205.201.32/28 -j DROP
            iptables -I INPUT -s 140.205.225.192/29 -j DROP
            iptables -I INPUT -s 140.205.225.200/30 -j DROP
            iptables -I INPUT -s 140.205.225.184/29 -j DROP
            iptables -I INPUT -s 140.205.225.183/32 -j DROP
            iptables -I INPUT -s 140.205.225.206/32 -j DROP
            iptables -I INPUT -s 140.205.225.205/32 -j DROP
            iptables -I INPUT -s 140.205.225.195/32 -j DROP
            iptables -I INPUT -s 140.205.225.204/32 -j DROP
        elif [ ${uninstall_ali_cloud_shield} = '2' ]; then
        	#检查文件uninstal_qcloud.sh是否存在,若不存在,则下载该文件
	    if [ ! -f /root/uninstal_qcloud.sh ]; then
	    	curl -sSL https://down.oldking.net/Script/uninstal_qcloud.sh
	    	chmod +x uninstal_qcloud.sh
	    fi
            sudo bash uninstal_qcloud.sh
    	else
    		echo "选项不在范围内,更新中止.";exit 0
    	fi
}

#回程路由测试-[b]
nali_test(){
	echo "请输入目标IP：";read purpose_ip
	nali-traceroute -q 1 ${purpose_ip}
}

besttrace_test(){
	echo "请输入目标IP：";read purpose_ip
	cd /root/besttrace
	./besttrace -q 1 ${purpose_ip}
}

mtr_test(){
	echo "请输入目标IP：";read purpose_ip
	echo "请输入测试次数："
	read MTR_Number_of_tests
	mtr -c ${MTR_Number_of_tests} --report ${purpose_ip}
}

detect_backhaul_routing(){
	echo "选项：[1]Nali [2]BestTrace [3]MTR"
	read detect_backhaul_routing_version
	if [ ${detect_backhaul_routing_version} = '1' ]; then
		#判断/root/nali-ipip/configure文件是否存在
		if [ ! -f /root/nali-ipip/configure ]; then
			echo "检查到您未安装,脚本将先进行安装..."
			yum -y update;yum -y install traceroute git gcc make
			git clone https://github.com/dzxx36gyy/nali-ipip.git
			cd nali-ipip
			./configure && make && make install
			clear;nali_test
		else
			nali_test
		fi
	elif [ ${detect_backhaul_routing_version} = '2' ]; then
		#判断/root/besttrace/besttrace文件是否存在
		if [ ! -f /root/besttrace/besttrace ]; then
			echo "检查到您未安装,脚本将先进行安装..."
			yum update -y
			yum install traceroute unzip -y
			wget -N --no-check-certificate "https://cdn.ipip.net/17mon/besttrace4linux.zip"
			unzip besttrace4linux.zip -d besttrace && cd besttrace && chmod +x *
			clear;
            rm -rf /root/*.zip
            besttrace_test
		else
			besttrace_test
		fi
	elif [ ${detect_backhaul_routing_version} = '3' ]; then
		#判断/usr/sbin/mtr文件是否存在
		if [ ! -f /usr/sbin/mtr ]; then
			echo "检查到您未安装,脚本将先进行安装..."
			yum update -y;yum install mtr -y
			clear;mtr_test
		else
			mtr_test
		fi
	else
		echo "选项不在范围.";exit 0
	fi
}

#简易测速-[c]
superspeed(){
	#检查文件superspeed.sh是否存在,若不存在,则下载该文件
	if [ ! -f /root/superspeed.sh ]; then
		wget -N --no-check-certificate "https://github.com/Super-box/v3/raw/master/superspeed.sh" /root/superspeed.sh
		chmod +x /root/superspeed.sh
	fi
	#执行测试
    ./superspeed.sh
}

#检测BBR安装状态-[d]
check_bbr_installation(){
	echo "查看内核版本,含有4.12即可";uname -r
	echo "------------------------------------------------------------"
	echo "返回：net.ipv4.tcp_available_congestion_control = bbr cubic reno 即可";sysctl net.ipv4.tcp_available_congestion_control
	echo "------------------------------------------------------------"
	echo "返回：net.ipv4.tcp_congestion_control = bbr 即可";sysctl net.ipv4.tcp_congestion_control
	echo "------------------------------------------------------------"
	echo "返回：net.core.default_qdisc = fq 即可";sysctl net.core.default_qdisc
	echo "------------------------------------------------------------"
	echo "返回值有 tcp_bbr 模块即说明bbr已启动";lsmod | grep bbr
}

#更换默认源-[g]
replacement_of_installation_source(){
	echo "请选择更换目标源： [1]网易163 [2]阿里云 [3]自定义 [4]恢复默认源"
	read change_target_source

	#备份
	mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak

	#执行
	if [ ${change_target_source} = '1' ]; then
		echo "更换目标源:网易163,请选择操作系统版本： [1]Centos 5 [2]Centos 6 [3]Centos 7"
		read operating_system_version
		if [ ${operating_system_version} = '1' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS5-Base-163.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '2' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '3' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo;yum clean all;yum makecache
		fi
	elif [ ${change_target_source} = '2' ]; then
		echo "更换目标源:阿里云,请选择操作系统版本： [1]Centos 5 [2]Centos 6 [3]Centos 7"
		read operating_system_version
		if [ ${operating_system_version} = '1' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-5.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '2' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo;yum clean all;yum makecache
		elif [ ${operating_system_version} = '3' ]; then
			wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo;yum clean all;yum makecache
		fi
	elif [ ${change_target_source} = '3' ]; then
		echo "更换目标源:自定义,请确定您需使用的自定义的源与您的操作系统相符！";echo "请输入自定义源地址："
		read customize_the_source_address
		wget -O /etc/yum.repos.d/CentOS-Base.repo ${customize_the_source_address};yum clean all;yum makecache
	elif [ ${change_target_source} = '4' ]; then
		rm -rf /etc/yum.repos.d/CentOS-Base.repo
		mv /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
		yum clean all;yum makecache
	fi
}

#配置防火墙-[e]
configure_firewall(){
	echo "请选择操作： [1]关闭firewall"
	read firewall_operation

	if [ ${firewall_operation} = '1' ]; then
		echo "停止firewall..."
		systemctl stop firewalld.service
		echo "禁止firewall开机启动"
		systemctl disable firewalld.service
		echo "查看默认防火墙状态,关闭后显示notrunning,开启后显示running"
		firewall-cmd --state
	else
		echo "选项不在范围,操作中止.";exit 0
	fi
}

update_the_shell(){
	rm -rf /root/v6.sh v6.sh.*
	wget -N "https://raw.githubusercontent.com/whut-share/v6/master/v6.sh " /root/v6.sh

	#将脚本作为命令放置在/usr/bin目录内,最后执行
	rm -rf /usr/bin/v6;cp /root/v6.sh /usr/bin/v6;chmod +x /usr/bin/v6
	v6
}

###待更新
safe_dog(){
	#判断/usr/bin/sdui文件是否存在
	if [ ! -f /usr/bin/sdui ]; then
		echo "检查到您未安装,脚本将先进行安装..."
		wget -N —no-check-certificate  "http://sspanel-1252089354.coshk.myqcloud.com/safedog_linux64.tar.gz"
		tar xzvf safedog_linux64.tar.gz
		mv safedog_an_linux64_2.8.19005 safedog
		cd safedog;chmod +x *.py
		yum -y install mlocate lsof psmisc net-tools
		./install.py
		echo "安装完成,请您重新执行脚本."
	else
		sdui
	fi
}

install_fail2ban(){
	echo "脚本来自:http://www.vpsps.com/225.html";echo "使用简介:https://linux.cn/article-5067-1.html";echo "感谢上述贡献者."
	echo "选择选项: [1]安装fail2ban [2]卸载fail2ban [3]查看封禁列表 [4]为指定IP解锁";read fail2ban_option
	if [ ${fail2ban_option} = '1' ]; then
		wget -N —no-check-certificate"http://sspanel-1252089354.coshk.myqcloud.com/fail2ban.sh";bash fail2ban.sh
	elif [ ${fail2ban_option} = '2' ]; then
		wget -N —no-check-certificate"https://raw.githubusercontent.com/FunctionClub/Fail2ban/master/uninstall.sh";bash uninstall.sh
	elif [ ${fail2ban_option} = '3' ]; then
		echo ${separate_lines};fail2ban-client ping;echo -e "\033[31m[↑]正常返回值:Server replied: pong\033[0m"
		#iptables --list -n;echo -e "\033[31m#当前iptables禁止规则\033[0m"
		fail2ban-client status;echo -e "\033[31m[↑]当前封禁列表\033[0m"
		fail2ban-client status ssh-iptables;echo -e "\033[31m[↑]当前被封禁的IP列表\033[0m"
		sed -n '12,14p' /etc/fail2ban/jail.local;echo -e "\033[31m[↑]当前fail2ban配置\033[0m"
	elif [ ${fail2ban_option} = '4' ]; then
		echo "请输入需要解锁的IP地址:";read need_to_unlock_the_ip_address
		fail2ban-client set ssh-iptables unbanip ${need_to_unlock_the_ip_address}
		echo "已为${need_to_unlock_the_ip_address}解除封禁."
	else
		echo "选项不在范围.";exit 0
	fi
}

install_shell(){
	if [ ! -f /usr/bin/v6 ]; then
		cp /root/v6.sh /usr/bin/v6 && chmod +x /usr/bin/v6
	else
		rm -rf /usr/bin/v6
		cp /root/v6.sh /usr/bin/v6 && chmod +x /usr/bin/v6
		clear;echo "Tips:您可通过命令[v6]快速启动本脚本!"
	fi
}

get_server_ip_info(){
	if [ ! -f /root/.server_ip_info.txt ]; then
		curl -s myip.ipip.net > /root/.server_ip_info.txt
	else
		rm -rf /root/.server_ip_info.txt
		curl -s myip.ipip.net > /root/.server_ip_info.txt
	fi
	read server_ip_info < /root/.server_ip_info.txt
}

#安装本脚本,获取服务器IP信息
install_shell
get_server_ip_info
start_menu

i=1
while((i <= 100))
do
keep_loop
done

#END 2018年12月16日
