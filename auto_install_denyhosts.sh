#!/bin/bash
 
##### Scripts Name: auto_install_denyhosts.sh
##### My Blog：http://laowang.me
##### Written：2015-12－09

packname="DenyHosts-2.6.tar.gz"

######  统计时间    ######
begin_time()
{
    begin_year_month_day=`date +%-Y年%-m月%-d日`
    begin_hours=`date +%-H`
    begin_minute=`date +%-M`
    begin_second=`date +%-S`
}

######  下载&安装&运行denyhosts ######
okay()
{
	wget http://longshanren.net/$packname
	tar xf $packname
	cd DenyHosts-2.6
	/usr/bin/python2 setup.py install
	cd /usr/share/denyhosts/
	cp denyhosts.cfg-dist denyhosts.cfg
	cp daemon-control-dist daemon-control
	chmod 700 daemon-control
	ln -sf /usr/share/denyhosts/daemon-control /etc/init.d/denyhosts
	/etc/init.d/denyhosts start
	chkconfig denyhosts on
    echo "service denyhosts start">> /etc/rc.local
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

begin_time;okay&&end_time&&exit
 
