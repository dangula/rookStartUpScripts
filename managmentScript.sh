#!/usr/bin/env bash

if [ "$#" -ne 1 ]; then
	echo "illegal paramaters - script takes only one paramater - block,file or object"
	exit 1
fi

case $1 in
	[Bb][Ll][Oo][Cc][Kk])
             ;;
    [Ff][Ii][Ll][Ee])
             ;;
    [Oo][Bb][Jj][Ee][Cc][Tt])
             ;;
    *)
		echo "invalid paramater - only block,file and object are allowed"
        exit 1
esac


# tag rook images - add '-ci' prefix to all of them
docker tag quay.io/rook/rookd rookd-ci
docker tag quay.io/rook/rook-operator rook-operator-ci
docker tag quay.io/rook/rook-client rook-client-ci

mkdir /to-host

# tar ad zip all rook-ci images into a folder
sudo docker save rookd-ci |gzip >/to-host/rookd-ci.tar.gz
sudo docker save rook-operator-ci |gzip >/to-host/rook-operator-ci.tar.gz
sudo docker save rook-client-ci |gzip >/to-host/rook-client-ci.tar.gz

# update docker in docker contianer with the rook-ci images folder mounted
#docker run -it --net=host -e "container=docker" --privileged -d --security-opt seccomp:unconfined --cap-add=SYS_ADMIN -v /sys/fs/cgroup:/sys/fs/cgroup -v /sbin/modprobe:/sbin/modprobe -v /lib/modules:/lib/modules:rw -v /to-host:/from-#host -p 5000:5000 -p 8080:8080 rook-infra /sbin/init
docker run -it -e "container=docker" --privileged -d --security-opt seccomp:unconfined --cap-add=SYS_ADMIN -v /dev:/dev -v /sys:/sys -v /sys/fs/cgroup:/sys/fs/cgroup -v /sbin/modprobe:/sbin/modprobe -v /lib/modules:/lib/modules:rw -v /to-rook:/from-host -p 5000:5000 -p 8080:8080 rook_infra /sbin/init

INFRA_DOCKER_ID=$(docker ps |grep rook-infra| awk '{ print $1}')

sleep 20

echo $INFRA_DOCKER_ID

# do docker exec to start kubeadm and rook -TODO?
#eg  docker docker exec $INFRA_DOCKER_ID /path/to/start.sh

#tail journalctl and check if rook is started successfully
docker exec $INFRA_DOCKER_ID -- /usr/bin/setup-rook-test-infra
x=1
while [ $x -le 20 ]
do
    lastline=$(docker exec $INFRA_DOCKER_ID journalctl -u setup-rook-infra|tail -2)
    echo $lastline
    if [[ "$lastline" == *"Rook Test infrastructure setup is complete"* ]]; then
	break
    fi
    x=$(( $x + 1 ))
    sleep 30
done

if [ $x -gt 15 ]; then
    echo "Rook Test infrasructure failed to start up"
    exit 1ls

fi



#TODO-set up storage for test pod and start test pod
docker exec $INFRA_DOCKER_ID chmod +x /usr/bin/rookStartUpScripts/setup_and_run_rook_test.sh
docker exec $INFRA_DOCKER_ID /usr/bin/rookStartUpScripts/setup_and_run_rook_test.sh $1

res = $?
if [ $res == 0 ]; then
    echo "Integration test for $1 passed"
    exit 0
else
   echo "Integration test for $1 Failed"
   exit 1






