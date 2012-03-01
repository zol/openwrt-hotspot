CC=~/dl/OpenWrt-SDK-Linux-i686-1/staging_dir_mipsel/bin/mipsel-linux-gcc

iptables-wrapper: iptables-wrapper.c
	$(CC) -Wall -ansi -o iptables-wrapper iptables-wrapper.c
	@echo
	@echo "Dont forget the following two commands as root:"
	@echo "chown root:[www-data?] iptables-wrapper"
	@echo "chmod ug+srx,o-rxw iptables-wrapper"
