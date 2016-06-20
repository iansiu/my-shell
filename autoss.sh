#!/bin/bash

######  auto_install shadowsocks and denyhosts    ######
######  By:gebilaowang                            ######
######  Written:Thu 29 Jan 2015 08:52:21 PM CST   ######
######  Feedback: xiaoxiong54@gmail.com           ######


#####   配置参数       #####

yumrely=(epel-release git python-setuptools make libevent libevent-devel m2crypto unzip wget gcc gcc-c++ python-devel iptables)
aptrely=(python-setuptools make git python-m2crypto unzip wget gcc g++ python-dev) #zlib1g-dev libssl-dev
piprely=(greenlet gevent ipaddr)
serverip=`ifconfig |grep -v inet6|grep inet |grep -v 127.0.0.1|awk '{ print $2}'|sed 's/addr://g'`
port='443'
passwd='hello123'
method='chacha20'
os=(CentOS Ubuntu Debian)
ver=`cat /etc/issue.net|sed -n '1'p |cut -d ' ' -f 1`
set -u
nodebug='' # 2>&1"
#set -e

function print_good () {
    echo -e "\x1B[01;32m[✔]\x1B[0m $1"
}

function print_error () {
    echo -e "\x1B[01;31m[✘]\x1B[0m $1"
}

################### judge ###################

function judge() {

if [ $UID -ne 0 ]
then
    print_error "Please use the root user"
    exit 1
fi

if [ -e /etc/shadowsocks.json ]
then
    print_error "Shadowsocks already installed"
    exit 1
fi

############# install centos rely ###############

if [ -e /etc/redhat-release ]
then
     for i in ${yumrely[*]}
     do
         if ! rpm -q "$i">/dev/null 2>&1
         then
            yum -y install "$i"
         fi
     done
############# install ubuntu or debain rely ###############

elif [ $ver = ${os[1]} -o $ver = ${os[2]} ]
then
    for s in ${aptrely[*]}
    do
        if ! dpkg -s "$s">/dev/null 2>&1
        then
            apt-get -y install $s
        fi
    done
else
    exit 1
    print_error "This system does not support"
    print_error "Only supports ${os[*]}"

fi
}

function install() {

############# install pip rely ###############
     easy_install pip

     for p in ${piprely[*]}
     do
         if ! pip show "$p">/dev/null 2>&1
         then
             pip install "$p"
         fi
     done

cat >/etc/shadowsocks.json <<-EOF
{
     "server": "0.0.0.0",
     "server_ipv6": "::",
     "server_port": $port,
     "local_address": "127.0.0.1",
     "local_port": 1080,
     "password": "$passwd",
     "timeout": 300,
     "method": "$method",
     "protocol": "auth_sha1_compatible",
     "protocol_param": "",
     "obfs": "tls1.0_session_auth_compatible",
     "obfs_param": "",
     "redirect": "",
     "dns_ipv6": false,
     "fast_open": false,
     "workers": 1
 }
EOF

##### iptables 放行端口  #####

    iptables -I INPUT -p tcp --dport $port -j ACCEPT
    iptables -I INPUT -p udp --dport $port -j ACCEPT
    if [ -e /etc/apt/sources.list ]
    then
        ufw disable && systemctl disable ufw
        iptables-save >/etc/iptables.rules
        echo 'pre-up iptables-restore < /etc/iptables.rules' >> /etc/network/interfaces
    else
        service iptables save || {
            systemctl stop firewalld.service
	    systemctl disable firewalld.service
	    yum -y install iptables-services
	    iptables-save >/etc/sysconfig/iptables
	    systemctl enable iptables.services
	    ystemctl start iptables.service
        } >/dev/null 2>&1

    fi

##### 优化TCP连接  #####

    #rm -f /sbin/modprobe
    #ln -s /bin/true /sbin/modprobe
    #rm -f /sbin/sysctl
    #ln -s /bin/true /sbin/sysctl
    #默认关闭，OpenVZ VPS用得上。

    echo 'net.ipv4.tcp_syncookies = 1
    fs.file-max = 51200
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
    net.ipv4.tcp_mtu_probing=1 ' >/etc/sysctl.conf
    #net.ipv4.tcp_congestion_control=hybla' >/etc/sysctl.conf ## 内核支持才可以

    sed -i 's/^    //g' /etc/sysctl.conf
    sysctl -p
##### 下载 shadowsocksR-python #####
cd ~ && git clone -b manyuser https://github.com/breakwa11/shadowsocks.git &

##### 安装libsodium开启chacah20加密  #####

    wget https://download.libsodium.org/libsodium/releases/libsodium-1.0.8.tar.gz &
    wait
    tar xf libsodium-1.0.8.tar.gz && cd libsodium-1.0.8
    ./configure && make && make install
    echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
    ldconfig

##### 安装Denyhosts防止SSH暴力破解和supervisor用于守护进程 #####

    wget http://jaist.dl.sourceforge.net/project/denyhost/denyhost-3.1/denyhosts-3.1.tar.gz &
    wait
    tar xf denyhosts-3.1.tar.gz
    cd denyhosts && python setup.py install
    \cp /usr/local/bin/daemon-control-dist /etc/init.d/denyhosts || \cp /usr/bin/daemon-control-dist /etc/init.d/denyhosts
    chmod 755 /etc/init.d/denyhosts
    ln -sf /usr/local/bin/denyhosts.py /usr/sbin/denyhosts || ln -sf /usr/bin/denyhosts.py /usr/sbin/denyhosts
    /etc/init.d/denyhosts start
    chmod +x /etc/rc.local
    sed -i 's/exit 0//g' /etc/rc.local
    echo '/etc/init.d/denyhosts start' >> /etc/rc.local
    echo 'python ~/shadowsocks/shadowsocks/server.py -c /etc/shadowsocks.json -d start' >>/etc/rc.local
    echo 'exit 0' >>/etc/rc.local
    wait
    cd ~ && rm -rf denyhosts* libsodium*
    python ~/shadowsocks/shadowsocks/server.py -c /etc/shadowsocks.json -d start
}

function showinfo() {
    echo ""
    print_good "*******************************************************************************************************"
    print_good ""
    print_good "                Shadowsocks successful installation"
    print_good ""
    print_good "                Server IP:  $serverip"
    print_good "                Port:       $port"
    print_good "                Password:   $passwd"
    print_good "                Method:     $method"
    print_good "                Local IP:   127.0.0.1"
    print_good "                Local port: 1080"
    print_good ""
    print_good "                一共耗费了 $SECONDS 秒"
    print_good ""
    print_good "*******************************************************************************************************"
    echo ""
}
    judge&&install&&showinfo&&rm -rf $0
