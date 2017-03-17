#!/bin/bash

kubectl delete pods block-test
kubectl delete pvc block-pv-claim
kubectl delete deployment rook-operator 
kubectl delete thirdpartyresources cluster.rook.io
kubectl delete namespace rook
kubectl delete storageclass rook-block
kubectl delete secret rook-rbd-user