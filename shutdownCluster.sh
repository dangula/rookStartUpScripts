#!/bin/bash

kubectl delete pods block-test
kubectl delete pvc block-pv-claim
kubectl delete deployment rook-operator
kubectl delete thirdpartyresources rookcluster.rook.io rookpool.rook.io
kubectl delete storageclass rook-block
kubectl delete secret rook-rbd-user
kubectl delete namespace rook