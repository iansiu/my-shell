#!/bin/bash

######  统计时间    ######

begin_time()
{
    begin_year_month_day=`date +%-Y年%-m月%-d日`
    begin_hours=`date +%-H`
    begin_minute=`date +%-M`
    begin_second=`date +%-S`
}

##### 安装依赖和manyusershadowsocks #####

install_ss()
{
	yum install epel-release python-setuptools m2crypto supervisor git -y
	easy_install pip
	pip install cymysql
	git clone -b manyuser https://github.com/iansiu/shadowsocks.git
	wget http://longshanren.net/auto_install_denyhosts.sh -O ~/auto_install_denyhosts.sh
	sh ~/auto_install_denyhosts.sh

##### 开启Pro  #####

	sed -i "s/FROM user/FROM user WHERE plan = 'pro'/" ~/shadowsocks/shadowsocks/db_transfer.py


##### 开启udp  #####

	sed -i 's/#self.udp/self.udp/' ~/shadowsocks/shadowsocks/server_pool.py
	sed -i 's/#udp_server/udp_server/' ~/shadowsocks/shadowsocks/server_pool.py

##### 连接主服务器数据库 #####

	cat > ~/shadowsocks/shadowsocks/Config.py<<-EOF
	MYSQL_HOST = ''
	MYSQL_PORT = 3306
	MYSQL_USER = 'ss'
	MYSQL_PASS = 'ss'
	MYSQL_DB = 'shadowsocks'

	MANAGE_PASS = 'ss233333333'
	#if you want manage in other server you should set this value to global ip
	MANAGE_BIND_IP = '127.0.0.1'
	#make sure this port is idle
	MANAGE_PORT = 23333
	EOF


##### 设置加密方式  #####

	cat > ~/shadowsocks/shadowsocks/config.json<<-EOF
	{
	    "server":"0.0.0.0",
	    "server_ipv6": "[::]",
	    "server_port":8358,
	    "local_address": "127.0.0.1",
	    "local_port":1080,
	    "password":"m",
	    "timeout":600,
	    "method":"rc4-md5"
	}
	EOF
}

configure_ss()
{
##### 调整ulimit值 #####

	ulimit -n 51200

	sed -i '41a \* soft nofile 51200' /etc/security/limits.conf
	sed -i '42a \* hard nofile 51200' /etc/security/limits.conf



##### 优化TCP连接  #####

	> /etc/sysctl.conf

echo '
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_congestion_control=hybla' >/etc/sysctl.conf

	sysctl -p

##### 添加iptables规则 ##### 

	iptables -F
	echo 1 > /proc/sys/net/ipv4/ip_forward

echo '
#!/bin/bash

iptables -A FORWARD -m string --string "GET /scrape?info_hash=" --algo bm --to 65535 -j DROP
iptables -A FORWARD -m string --string "GET /announce.php?info_hash=" --algo bm --to 65535 -j DROP
iptables -A FORWARD -m string --string "GET /scrape.php?info_hash=" --algo bm --to 65535 -j DROP
iptables -A FORWARD -m string --string "GET /scrape.php?passkey=" --algo bm --to 65535 -j DROP
iptables -A FORWARD -m string --hex-string "|13426974546f7272656e742070726f746f636f6c|" --algo bm --to 65535 -j DROP
iptables -A FORWARD -m string --string "www.360.com" --algo bm --to 65535 -j DROP
iptables -A FORWARD -m string --string "www.360.cn" --algo bm --to 65535 -j DROP
iptables -A OUTPUT -p tcp -m multiport --dport 24,25,50,57,105,106,109,110,143,158,209,218,220,465,587 -j REJECT --reject-with tcp-reset
iptables -A OUTPUT -p tcp -m multiport --dport 993,995,1109,24554,60177,60179 -j REJECT --reject-with tcp-reset
iptables -A OUTPUT -p udp -m multiport --dport 24,25,50,57,105,106,109,110,143,158,209,218,220,465,587 -j DROP
iptables -A OUTPUT -p udp -m multiport --dport 993,995,1109,24554,60177,60179 -j DROP' >~/iptables.sh
	

    iptables -F
    sh ~/iptables.sh
	service iptables save
	service iptables restart

##### 自动启动redenyhosts  #####


echo '
#!/bin/bash

while true; do
    num=`ps -ef|grep "denyhosts"|grep -v "grep"|grep -v "redenyhosts.sh"|wc -l`
    sleep 5
    if [ $num -eq 0 ]; then
        service denyhosts restart
        date=`date +%Y年%m月%d天%H时%M分%S秒`
        echo "$date">>~/redenyhosts.log
        sleep 5

    fi
done' >~/redenyhosts.sh

	service denyhosts start
	nohup sh ~/redenyhosts.sh >/dev/null 2>&1 &


##### 设置supervisor监控shadowsocks #####

	> /etc/supervisord.conf

echo '
[program:shadowsocks]

command=python /root/shadowsocks/shadowsocks/server.py -c /root/shadowsocks/shadowsocks/config.json
autostart=true
autorestart=true
startsecs=3
redirect_stderr=true
stdout_logfile=/var/log/shadowsocks.log

[supervisord]' >/etc/supervisord.conf

##### 自动重启锐速   #####

echo '
#!/bin/bash

status="sh /serverspeeder/bin/serverSpeeder.sh status"
findstr="ServerSpeeder is running\!"

while true ; do

if ! $status|grep "$findstr"; then
    sh /serverspeeder/bin/serverSpeeder.sh renewLic
    sh /serverspeeder/bin/serverSpeeder.sh start
    date=`date +%Y年%m月%d天%H时%M分%S秒`
    echo "$date">>~/serverspeed.log
fi

done'>~/reserverspeed.sh
	
	nohup sh ~/reserverspeed.sh > /dev/null 2>&1 &

##### 添加开启自启动 #####

echo '
service denyhosts start
nohup sh ~/reserverspeed.sh > /dev/null 2>&1 &
supervisord -c /etc/supervisord.conf
echo 1 > /proc/sys/net/ipv4/ip_forward
nohup sh ~/redenyhosts.sh > /dev/null 2>&1 &' >>/etc/rc.local


##### 启动shadowsocks   #####

	supervisord -c /etc/supervisord.conf

}
end_time()
{
    echo ""
    end_year_month_day=`date +%-Y年%-m月%-d日`
    end_hours=`date +%-H`
    end_minute=`date +%-M`
    end_second=`date +%-S`
 
    echo "从 $begin_year_month_day$begin_hours:$begin_minute:$begin_second 开始安装，到 $end_year_month_day$end_hours:$end_minute:$end_second 安装完成."
    echo ""
    echo 一共耗费了 $[$end_hours-begin_hours] 小时 $[$end_minute-begin_minute] 分钟 $[$end_second-$begin_second] 秒|sed 's/\-//'
    echo ""
}

begin_time;install_ss&&configure_ss;end_time;exit
