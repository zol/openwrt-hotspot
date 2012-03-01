#!/bin/sh -

# first install relevant packages
ipkg update

ipkg install bin/lighttpd_1.3.14-1_mipsel.ipk
ipkg install bin/lighttpd-mod-fastcgi_1.3.14-1_mipsel.ipk
ipkg install bin/lighttpd-mod-auth_1.3.14-1_mipsel.ipk

ipkg install iptables-mod-extra
ipkg install iptables-mod-ipopt

ipkg install ntpclient

ipkg install libgcc
ipkg install libpthread

# copy ruby over
cp bin/ruby /usr/bin/ruby

# next install configs

cp -f "./etc/*.conf" /etc
cp -f "./etc/init.d/S*" /etc/init.d

cp -f "./etc/init.d/firewall" /etc/init.d
ln -fs /etc/init.d/firewall /etc/init.d/S45firewall

# now copy over the hotspot
mkdir -p /opt/hotspot/www/templates
mkdir /opt/hotspot/lib

cp *.rb /opt/hotspot
cp hotspotd.conf /opt/hotspot

cp www/*.rb www/*.css www/*.js /opt/hotspot/www
cp www/templates/*.html /opt/hotspot/www/templates

cp lib/siki-template.rb /opt/hotspot/lib
cp lib/ruby-fcgi-dispatcher /usr/bin
cp iptables/iptables-wrapper /usr/bin

#copy ruby
mkdir -p /usr/lib/ruby
mv site_ruby /usr/lib/ruby

#fix init.d
cd /etc/init.d
mv S50telnet S42telnet
mv S50dropbear S42dropbear
rm S50httpd

# TODO
# ntpclient

echo "Install finished! reboot and cross fingers"
