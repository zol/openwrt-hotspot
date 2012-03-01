#!/bin/bash -

IP=192.168.1.1

if [ "$1a" != "a" ] 
then
  IP="$1"
fi

find hotspot -not \( -regex ".*svn.*" \) -exec cp --parents '{}' /tmp  \;
scp -r /tmp/hotspot root@$IP:/tmp

#scp -r ../hotspot root@$IP:/tmp

