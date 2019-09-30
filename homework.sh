#!/bin/bash

# disable selinux so it won't get in the way
setenforce 0

## Task 1
yum -y install httpd

cat <<EOF >/var/www/html/index.html
<h2>Hello from httpd</h2>
<hr/>
<p>Created by Kiryl Rusetski</p>
EOF

rm /etc/httpd/conf.d/vhosts.conf

pgrep httpd && systemctl restart httpd || systemctl start httpd
httpd -S
echo ------
echo Test webpage request for httpd
echo ------
curl 127.0.0.1/index.html
systemctl stop httpd


## Task 2
# skip building apache2 if its dir already exists
if [ ! -d /opt/apache2 ]
then
  curl http://ftp.byfly.by/pub/apache.org//httpd/httpd-2.4.41.tar.gz | tar xz -C /opt
  yum -y install centos-release-scl 
  yum -y install devtoolset-6-gcc apr apr-devel apr-util apr-util-devel pcre-devel
  . scl_source enable devtoolset-6
  cd /opt/httpd-2.4.41
  ./configure --prefix=/opt/apache2
  make -j4
  make install
fi

cd /opt/apache2/htdocs/
cat <<EOF > index.html
<h2>Hello from Apache2</h2>
<hr />
<p>Created by Kiryl Rusetski</p>
EOF

cd ../bin
./apachectl start
./apachectl -S
echo ------
echo Test webpage request for Apache2
echo ------
curl 127.0.0.1/index.html
./apachectl stop
sleep 2s # so that apache2 will shutdown properly and free up port 80

cat <<EOF >/etc/httpd/conf.d/vhosts.conf
<VirtualHost *>
ServerName www.kiryl.rusetski
ServerAlias kiryl.rusetski
DocumentRoot /var/www/html
RewriteEngine On
RewriteRule ^/$ index.html [R,L]
RewriteRule ^/index.html$ ping.html [R,L]
RewriteRule !^/ping.html$ - [R=403,L]
</VirtualHost>
EOF
echo "127.0.0.2 www.kiryl.rusetski kiryl.rusetski" >> /etc/hosts
cat <<EOF >/var/www/html/ping.html
<h2>This is ping.html</h2>
<hr />
<p>Created by Kiryl Rusetski</p>
EOF
systemctl start httpd
httpd -S

echo ------
echo Test webpage request for RewriteEngine redirection
echo ------
curl -iL kiryl.rusetski/
echo ------

## Task 3
yum -y install epel-release
yum -y install cronolog tree

cat <<EOF >/etc/httpd/conf.d/vhosts.conf
<VirtualHost *>
ServerName www.kiryl.rusetski
ServerAlias kiryl.rusetski
DocumentRoot /var/www/html

ErrorLog "| /usr/sbin/cronolog /var/log/Kiryl_Rusetski/apache/%Y/%b/%d/error.log"
CustomLog "| /usr/sbin/cronolog /var/log/Kiryl_Rusetski/apache/%Y/%b/%d/access.log" common

RewriteEngine On
RewriteRule ^/$ index.html [R,L]
RewriteRule ^/index.html$ ping.html [R,L]
RewriteRule !^/ping.html$ - [R=403,L]
</VirtualHost>
EOF
mkdir -p /var/log/Kiryl_Rusetski
systemctl restart httpd
httpd -S

echo ------
echo Test webpage request for cronolog config
echo ------
curl -iL kiryl.rusetski/
echo ------

tree /var/log/Kiryl_Rusetski
find /var/log/Kiryl_Rusetski -name *.log | xargs cat

## Task 4

echo "local1.* /var/log/Kiryl_Rusetski/apache.log" >> /etc/rsyslog.conf
systemctl restart rsyslog

cat <<EOF >/etc/httpd/conf.d/vhosts.conf
<VirtualHost *>
ServerName www.kiryl.rusetski
ServerAlias kiryl.rusetski
DocumentRoot /var/www/html

ErrorLog "| /usr/bin/logger -t httpd -p local1.err"
CustomLog "| /usr/bin/logger -t httpd -p local1.info" common

RewriteEngine On
RewriteRule ^/$ index.html [R,L]
RewriteRule ^/index.html$ ping.html [R,L]
RewriteRule !^/ping.html$ - [R=403,L]
</VirtualHost>
EOF
systemctl restart httpd

curl -iL kiryl.rusetski/
tail /var/log/Kiryl_Rusetski/apache.log

systemctl restart httpd
tail /var/log/Kiryl_Rusetski/apache.log






