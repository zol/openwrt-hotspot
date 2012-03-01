# Description

openwrt-hotspot is a commercial wifi hotspot application running on openwrt flashed linksys routers I wrote with tmeasday back in 2006. It is written in ruby, runs under linux and manipulates the routing tables using iptables.

# Operation

1. A user enters the hotspot area and logs onto the open network.
2. The user tries to browse the web, they are blocked by iptables and redirected to a screen indicating that they must pay and presenting them with a dictionary word based token.
3. They approach the operator and add some time by paying. The operator adds time to their 'token'.
4. As the user tries to browse again, this time iptables allows their request to go through and they happily use the internet.
5. When their time runs out and they try to browse to a site, they must restart again from step 1.

# Caveats

We use mac addresses to identify users. A hacker can fairly trivially masquerade as having a paid user's I.P address and hence gain free internet usage. We dismissed this scenario

# Installation on an ASUS WL-500G Deluxe

Note: OpenWRT Whiterussian is quite old now so use this section as a rough guide for more modern distributions.

## Prepare router for flashing

1. Turn on a plug laptop into LAN port.
2. Browse to 192.168.1.1 (admin/admin)
3. Follow basic steps to configure router (i.e. setup wan, wlan etc.)

## Flash the router

(see http://wiki.openwrt.org/OpenWrt/Docs/Hardware/Asus/WL500GD)

1. Download latest whiterussian image e.g. openwrt-brcm-2.4-squashfs.trx
2. Make sure plugged in by LAN
3. Set router to FAILSAFE mode by removing power, press hold reset whilst
returing power, when power led starts flashing slowly, release reset.
4. Check you can ping router on 192.168.1.1
5. enter the following:
  tftp 192.168.1.1
  tftp>binary
  tftp>trace
  tftp>put openwrt-b...
6. Wait for it to reboot (wait for AIR light to come on)

## Connect to router

1. telnet 192.168.1.1
2. Set the the password (lithium) -- this disables telnet
3. logout and ssh in

## Get dnsmasq working

1. If dhcp is not working, log into the machine however you can
2. Check /etc/dnsmasq.conf
3. Check if it is running in a ps aux
4. run dnsmasq

## Copy & install

1. Run site_deploy.sh <ip> 
2. Ssh to router, change to /tmp/hotspot, run ./site_install.sh
