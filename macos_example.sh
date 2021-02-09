#!/bin/sh

# You should install Docker desktop for mac first.
docker images
if [ $? != 0 ]
then
    open /Applications/Docker.app
fi
docker images
STATUS=$?
while [ $STATUS != 0 ]
do
    echo "WAIT FOR DOCKER RUNNING..."
    sleep 5
    docker images
    STATUS=$?
done
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 hagb/docker-easyconnect
# Then you can connect with vnc client