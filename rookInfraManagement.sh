#!/usr/bin/env bash

if [ "$#" == 0 ]; then
	echo "illegal parameters - valid parameters : start,install or run"
	exit 1
fi

case $1 in
    # Start Docker in Docker container
	[Ss][Tt][Aa][Rr][Tt])
	    if [ "$#" -ne 1 ]; then
	        echo "illegal parameters"
	        exit 1
	    fi
	    sudo docker tag quay.io/rook/rookd rookd-ci
        sudo docker tag quay.io/rook/rook-operator rook-operator-ci
        sudo docker tag quay.io/rook/rook-client rook-client-ci

        sudo mkdir /to-host

        # tar ad zip all rook-ci images into a folder
        sudo docker save rookd-ci |gzip >/to-host/rookd-ci.tar.gz
        sudo docker save rook-operator-ci |gzip >/to-host/rook-operator-ci.tar.gz
        sudo docker save rook-client-ci |gzip >/to-host/rook-client-ci.tar.gz

        return docker run -it -e "container=docker" --privileged -d --security-opt seccomp:unconfined --cap-add=SYS_ADMIN -v /dev:/dev -v /sys:/sys -v /sys/fs/cgroup:/sys/fs/cgroup -v /sbin/modprobe:/sbin/modprobe -v /lib/modules:/lib/modules:rw -v /to-rook:/from-host -p 5000:5000 -p 8080:8080 rook_infra /sbin/init
        ;;
    # Install K8s and Rook
    [Ii][Nn][Ss][Tt][Aa][Ll])
        if [ "$#" -ne 2 ]; then
            echo "illegal parameters - expected install <validDockerId>"
            exit1
        fi
        docker exec $2 /usr/bin/setup-rook-test-infra
        exit 0
        ;;
    #Run integration Test
    [Rr][Uu][Nn])
        if [ "$#" -ne 3 ]; then
            echo "illegal parameters - expected run <validDockerId> <test type>"
            exit1
        fi
        docker exec $2 chmod +x /rookStartUpScripts/setup_and_run_rook_test.sh
        docker exec $2 /rookStartUpScripts/setup_and_run_rook_test.sh $3
        res=$?
        if [ $res -ne 0 ]; then
           echo "Integration Test for $3 Failed"
           exit 1
        fi
        echo "Integration Test for $3 Passed"
        exit 0
        ;;
    *)
		echo "invalid parameters - valid parameters, start,install <dockerId>,run <dockerId> <test type>"
        exit 1
esac






