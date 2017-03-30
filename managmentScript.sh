docker tag quay.io/rook/rookd rookd-ci                                       
docker tag quay.io/rook/rook-operator rook-operator-ci                        
docker tag quay.io/rook/rook-client rook-client-ci

mkdir /to-host

sudo docker save rookd-ci |gzip >/to-host/rookd-ci.tar.gz
sudo docker save rook-operator-ci |gzip >/to-host/rook-operator-ci.tar.gz
sudo docker save rook-client-ci |gzip >/to-host/rook-client-ci.tar.gz

# update docker to run right dind container
docker run -it --net=host -e "container=docker" --privileged -d --security-opt seccomp:unconfined --cap-add=SYS_ADMIN -v /sys/fs/cgroup:/sys/fs/cgroup -v /sbin/modprobe:/sbin/modprobe -v /lib/modules:/lib/modules:rw -v /to-host:/from-host -p 5000:5000 -p 8080:8080 rook-infra /sbin/init

INFRA_DOCKER_ID=$(docker ps |grep rook-infra| awk '{ print $1}')

sleep 20

echo $INFRA_DOCKER_ID

# do docker exec to start kubeadm and rook -TODO?
#eg  docker docker exec $INFRA_DOCKER_ID /path/to/start.sh

#tail journalctl and check if rook is started successfully
x=1
while [ $x -le 15 ]
do
    lastline=$(docker exec $INFRA_DOCKER_ID journalctl -u setup-rook-infra|tail -2)
    echo $lastline
    if [[ "$lastline" == *"Rook Test infrastructure setup is complete"* ]]; then
	break
    fi
    x=$(( $x + 1 ))
    sleep 20
done

if [ $x -gt 15 ]; then
    echo "Rook Test infrasructure failed to start up"
    exit 1
fi


#TODO -Start rook operator,cluster and pool 

#TODO-set up storage for test pod and start test pod
#eg  docker docker exec $INFRA_DOCKER_ID /path/to/teststart.sh testparam

#TODO- tail test pod for results
#docker docker exec $INFRA_DOCKER_ID kubectl logs block-test|tail -2


	 


