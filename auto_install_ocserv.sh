#!/bin/bash

######  统计时间    ######

begin_time()
{
    begin_year_month_day=`date +%-Y年%-m月%-d日`
    begin_hours=`date +%-H`
    begin_minute=`date +%-M`
    begin_second=`date +%-S`
}

##### 安装依赖  #####

install()
{
	yum install -y pam-devel readline-devel http-parser-devel unbound gmp-devel tar gzip xz wget gcc make autoconf

##### install_nettle #####

	wget ftp://ftp.gnu.org/gnu/nettle/nettle-2.7.1.tar.gz
	tar zxvf nettle-2.7.1.tar.gz 
	cd nettle-2.7.1/
	./configure --prefix=/usr/local/nettle
	make && make install
	echo '/usr/local/nettle/lib64/' > /etc/ld.so.conf.d/nettle.conf
	ldconfig 

##### install_gnutls #####

	export NETTLE_CFLAGS="-I/usr/local/nettle/include/"
	export NETTLE_LIBS="-L/usr/local/nettle/lib64/ -lnettle"
	export HOGWEED_LIBS="-L/usr/local/nettle/lib64/ -lhogweed"
	export HOGWEED_CFLAGS="-I/usr/local/nettle/include"
	wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.9.tar.xz
	tar xvf gnutls-3.3.9.tar.xz 
	cd gnutls-3.3.9/
	./configure --prefix=/usr/local/gnutls
	make && make install
	ln -sf /usr/local/gnutls/bin/certtool /usr/bin/certtool
	echo '/usr/local/gnutls/lib/' > /etc/ld.so.conf.d/gnutls.conf
	ldconfig

##### install_libnl #####

	yum install -y bison flex
	wget http://www.carisma.slowglass.com/~tgr/libnl/files/libnl-3.2.24.tar.gz
	tar xvf libnl-3.2.24.tar.gz
	cd libnl-3.2.24
	./configure --prefix=/usr/local/libnl
	make && make install
	echo '/usr/local/libnl/lib/' > /etc/ld.so.conf.d/libnl.conf
	ldconfig

##### install_ocserv #####

	export LIBNL3_CFLAGS="-I/usr/local/libnl/include/libnl3"
	export LIBNL3_LIBS="-L//usr/local/libnl/lib/ -lnl-3 -lnl-route-3"
	export LIBGNUTLS_LIBS="-L/usr/local/gnutls/lib/ -lgnutls"
	export LIBGNUTLS_CFLAGS="-I/usr/local/gnutls/include/"
	wget ftp://ftp.infradead.org/pub/ocserv/ocserv-0.10.10.tar.xz
	tar xvf ocserv-0.10.10.tar.xz
	cd ocserv-0.10.10
	./configure --prefix=/usr/local/ocserv
	make && make install
	echo 'export PATH=$PATH://usr/local/ocserv/sbin/:/usr/local/ocserv/bin/' >> $HOME/.bashrc 
	source $HOME/.bashrc 

	mkdir -p /etc/ssl/private/
	cd /etc/ssl/private

	wget http://longshanren.net/soft/my-ca-cert.pem
	wget http://longshanren.net/soft/my-server-cert.pem
	wget http://longshanren.net/soft/my-server-key.pem
	chmod 600 my-server-key.pem


echo '
[program:ocserv]

command=ocserv -f -d 1
autostart=true
autorestart=true
startsecs=3
redirect_stderr=true
stdout_logfile=/var/log/ocserv.log' >>/etc/supervisord.conf
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

begin_time
install
end_time
exit
