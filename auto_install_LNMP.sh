#!/bin/bash
 
######  统计时间    ######
begin_time()
{
begin_year_month_day=`date +%-Y年%-m月%-d日`
begin_hours=`date +%-H`
begin_minute=`date +%-M`
begin_second=`date +%-S`
}
#####   mysql php nginx download address
 
mysql='https://downloads.mariadb.com/archives/mysql-5.1/mysql-5.1.40-linux-i686-icc-glibc23.tar.gz'
php='http://cn2.php.net/distributions/php-5.4.36.tar.bz2'
nginx='http://nginx.org/download/nginx-1.6.2.tar.gz'
 
 
#####   local address mysql php Nginx
 
mysql_local='mysql-5.1.40-linux-i686-icc-glibc23.tar.gz'
php_local='php-5.4.36.tar.bz2'
nginx_local='nginx-1.6.2.tar.gz'
 
 
####    rely
 
rely=(epel-release.noarch gcc.$(uname -m) gcc-c++.$(uname -m) pcre.$(uname -m) pcre-devel.$(uname -m)   zlib-devel.$(uname -m) libxml2-devel.$(uname -m) openssl openssl-devel.$(uname -m) bzip2 bzip2-devel.$(uname -m) libjpeg-turbo.$(uname -m) libjpeg-turbo-static.$(uname -m) libjpeg-turbo-devel.$(uname -m) freetype-demos.$(uname -m) freetype-devel.$(uname -m) freetype.$(uname -m) libpng.$(uname -m) libpng-devel.$(uname -m) libmcrypt-devel.$(uname -m) libcurl-devel.$(uname -m))
 
#####   Check the local directory exists Mysql Php Nginx
 
checkfile()
{
if [ -e $mysql_local ]; then
        echo -e "\033[32m Mysql Installation package already exists, do not download directly installed!\033[0m"
else
        echo -e "\033[31m Mysql Installation package does not exist, you need to re-download, please wait ......\033[0m"
        wget $mysql
fi
 
 
if [ -e $php_local ]; then
        echo -e "\033[32m Php Installation package already exists, do not download directly installed!\033[0m"
else
        echo -e "\033[31m Php Installation package does not exist, you need to re-download, please wait ......\033[0m"
        wget $php
 
fi
 
if [ -e $nginx_local ]; then
        echo -e "\033[32m Nginx Installation package already exists, do not download directly installed!\033[0m"
else
        echo -e "\033[31m Nginx Installation package does not exist, you need to re-download, please wait ......\033[0m"
        wget $nginx
fi
 
for i in ${rely[*]}; do
    if ! rpm -q "$i">/dev/null ; then
        yum -y install $i
    fi
done
} 
 
#-----------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------
 
#########       Install Mysql PHp Nginx Functions
 
#####   Install Mysql Functions
 
install_mysql()
 
{
        tar -zxf $mysql_local && mv /usr/local/mysql /usr/local/mysql_old 2>/dev/null || mkdir -p /usr/local/mysql
        mkdir -p /usr/local/mysql && mv mysql-5.1.40-linux-i686-icc-glibc23/* /usr/local/mysql/
        useradd -s /sbin/nologin mysql 2>/dev/null || userdel -r mysql && useradd -s /sbin/nologin mysql 2>/dev/null
        mv /data/mysql /data/mysql_back 2>/dev/null;mkdir -p /data/mysql
        chown -R mysql:mysql /data/mysql
        /usr/local/mysql/scripts/mysql_install_db --user=mysql --datadir=/data/mysql 2>/dev/null || /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
        \cp /usr/local/mysql/support-files/my-large.cnf /etc/my.cnf
        \cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
        chmod 755 /etc/init.d/mysqld
        sed -i ':a $!N;$!ba;{s/\(datadir=[^\n]*\)\n/\1\/data\/mysql\n/}' /etc/init.d/mysqld
        chkconfig --add mysqld
        chkconfig mysqld on
        service mysqld start &&  echo -e "\033[32m Mysql has been successfully installed \033[0m"
}
 
 
#####   Install Php Functions
 
install_php()
 
{
        tar jxf $php_local
        cd php-5.4.36
        useradd -s /sbin/nologin php-fpm
        ./configure \
        --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --enable-fpm \
        --with-fpm-user=php-fpm \
        --with-fpm-group=php-fpm \
        --with-mysql=/usr/local/mysql \
        --with-mysql-sock=/tmp/mysql.sock \
        --with-libxml-dir \
        --with-gd \
        --with-jpeg-dir \
        --with-png-dir \
        --with-freetype-dir \
        --with-iconv-dir \
        --with-zlib-dir \
        --with-mcrypt \
        --enable-soap \
        --enable-gd-native-ttf \
        --enable-ftp \
        --enable-mbstring \
        --enable-exif \
        --disable-ipv6 \
        --with-curl
        make
        make install &&  echo -e "\033[32m Php has been successfully installed \033[0m" || make install &&  echo -e "\033[32m Php has been successfully installed \033[0m"
        \cp php.ini-production /usr/local/php/etc/php.ini
        \cp /usr/local/src/php-5.4.36/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
        \mv /usr/local/php/etc/php-fpm.conf.default  /usr/local/php/etc/php-fpm.conf
        chmod 755 /etc/init.d/php-fpm
        chkconfig --add php-fpm
        service php-fpm start
        chkconfig php-fpm on
         
}
 
#####   Install Nginx Functions
 
install_nginx()
 
{       cd ..
        tar -zxf $nginx_local
        cd nginx-1.6.2
        ./configure \
        --prefix=/usr/local/nginx \
        --with-pcre
        make
        make install &&  echo -e "\033[32m Nginx has been successfully installed \033[0m"
}
 
#####   Nginx Combine Php
 
ncp()
 
{
        sed -i 's/index  index\.html index\.htm\;/index  index\.html index\.htm index\.php\;/' /usr/local/nginx/conf/nginx.conf
        sed -i 's/\#    fastcgi\_param  SCRIPT_FILENAME  \/scripts$fastcgi_script_name;/\#    fastcgi\_param  SCRIPT_FILENAME  \/usr\/local\/nginx\/html$fastcgi_script_name;/g' /usr/local/nginx/conf/nginx.conf
        sed -i '65,71s/^        \#/        /g' /usr/local/nginx/conf/nginx.conf
        /usr/local/nginx/sbin/nginx -s  reload
        echo -e "<?php\n  echo 'php script successfully tested';\n?>" >/usr/local/nginx/html/test.php
        /usr/local/nginx/sbin/nginx -t >/dev/null && echo -e "\033[32m Nginx Syntax OK \033[0m"
        /usr/local/nginx/sbin/nginx >/dev/null && echo -e "\033[32m Nginx Successful start \033[0m"
        result=$(curl -s localhost/test.php)
        echo -e "\033[31m $result \033[0m"
 
}
 
 
#-----------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------
 
##########  Remove Mysql Php Nginx
 
#####   Remove Mysql
 
remove_mysql()
 
{
        service mysqld stop && echo -e "\033[31m service mysqld stop OK \033[0m"
        chkconfig --del mysqld && echo -e "\033[31m service mysqld delete OK \033[0m"
        killall -9 mysqld && echo -e "\033[31m Process mysqld kill OK\033[0m"
        rm -rf /etc/init.d/mysqld && echo -e "\033[31m /etc/init.d/mysqld Deleted OK\033[0m"
        rm -rf /etc/my.cnf && echo -e "\033[31m /etc/my.cnf Deleted OK\033[0m"
        rm -rf /data/mysql && echo -e "\033[31m /data/mysql Deleted OK\033[0m"
        rm -rf /usr/local/mysql && echo -e "\033[31m /usr/local/mysql Deleted OK\033[0m"
        rm -rf /var/lock/subsys/mysql && echo -e "\033[31m /var/lock/subsys/mysql Deleted OK\033[0m"
        userdel -r mysql && echo -e "\033[31m Mysqluser Deleted OK\033[0m"
         
}
 
#####   Remove Nginx
 
remove_nginx()
 
{       
        killall -9 nginx && echo -e "\033[31m Process nginx kill OK\033[0m"
        rm -rf /usr/local/nginx && echo -e "\033[31m /usr/local/nginx Deleted OK\033[0m"
}
 
 
#####   Remove Php
 
remove_php()
 
{
        service php-fpm stop && echo -e "\033[31m Service php-fpm stop OK\033[0m"
        chkconfig --del php-fpm && echo -e "\033[31m Service php-fpm delete OK\033[0m"
        killall -9 php-fpm && echo -e "\033[31m Process php-fpm kill OK\033[0m"
        userdel -r php-fpm && echo -e "\033[31m Php-fpm user Deleted OK\033[0m"
        rm -rf /usr/local/php && echo -e "\033[31m /usr/local/php Deleted OK\033[0m"
        rm -rf /usr/local/php/etc/php.ini && echo -e "\033[31m /usr/local/php/etc/php.ini Deleted OK\033[0m"
        rm -rf /etc/init.d/php-fpm && echo -e "\033[31m /etc/init.d/php-fpm Deleted OK\033[0m"
        rm -rf /usr/local/php/etc/php-fpm.conf && echo -e "\033[31m /usr/local/php/etc/php-fpm.conf Deleted OK\033[0m"
 
}
 
#-----------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------------------------
 
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
#####   Select Menu
 
selection=""
while [ "$selection" != "0" ]; do
        echo "
        Scripts Name：auto_install_LAMP.sh
        Version：1.0 
        By：iansiu
        My Blog：http://laowang.me
        support & Feedback：youweixiao@163.com
    "
        echo "
         
        PROGRAM MENU
 
 
        1 - Install Mysql、Php、Nginx
        2 - Remove  Mysql、Php、Nginx
         
        0 - exit program "
        echo ""
        read -n1 -p " Enter selection: " selection
        echo ""
        case $selection in
                1 ) clear; begin_time;checkfile&&install_mysql&&install_php&&install_nginx&&ncp;end_time;exit ;;
                2 ) clear; if [ -e /etc/init.d/mysqld ]; then remove_mysql&&remove_nginx&&remove_php; else echo -e "\033[31m No installation can not be uninstalled \033[0m"; fi ;;
                0 ) exit ;;
                * ) clear; echo "Please enter 1, 2, or 0"
        esac
done
