#!/bin/bash


isPodUp(){
  	x=1
	while [ $x -le 15 ]
	do
	  if [ "$#" -eq 3 ]; then
	  	declare -i y=$(kubectl get pods -n $3 2>/dev/null  | grep $2 | wc -l )
	  else
	  	declare -i y=$(kubectl get pods 2>/dev/null  | grep $1 | wc -l )
	  fi	
	  if [ $y -ge $2 ]
		then
			break
	 fi
	  x=$(( $x + 1 ))
	  sleep 10  
	done

	if [ $x -gt 15 ]; then
		retval=1
	else
		retval=0
	fi

	return $retval

}

isPodRunning(){
  	x=1
	while [ $x -le 15 ]
	do
	  if [ "$#" -eq 3 ]; then
	  	declare -i y=$(kubectl get pods -n $3 2>/dev/null | grep $1 | awk '{print $3}' | grep Running | wc -l)
	  else
	  	declare -i y=$(kubectl get pod 2>/dev/null  | grep $1 | awk '{print $3}' | grep Running | wc -l)
	  fi
	  if [ $y -ge $2 ]
		then
			break
	 fi
	  x=$(( $x + 1 ))
	  sleep 10 
	done

	if [ $x -gt 15 ]; then
		retval=1
	else
		retval=0
	fi

	return $retval
}


checkTestResult(){
	pod=$1
	x=1
	while [ $x -le 8 ]
	do
	  res=$(kubectl logs $pod|tail -2| head -1)
	  if [ "$res" == "PASS" ]
		then
			return 0
	 fi
	  x=$(( $x + 1 ))
	  sleep 20 
	done
	return 1
}

isRookOperatorUp(){

	isPodUp rook-operator 1
	iretval=$?
	if [ "$retval" == 0 ]
	then
    	echo "rook-operator Started"
	else
     	echo "rook-operator Not Started"
     	return 1
	fi 

	isPodRunning rook-operator 1
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "rook-operator Running"
	else
	     echo "rook-operator Not Running"
	     return 1
	fi 

	return 0
}

isRookClusterUp(){
	isPodUp mon 3 rook
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "rook-cluster monitors Started"
	else
	     echo "rook-cluster monitors Not Started"
	     return 1
	fi 

	isPodRunning mon 3 rook
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "rook-cluster monitors Running"
	else
	     echo "rook-cluster monitors Not Running"
	     return 1
	fi 


	isPodUp rook-api 1 rook
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "rook-cluster rook-api Started"
	else
	     echo "rook-cluster rook-api Not Started"
	     return 1
	fi 

	isPodRunning rook-api 1 rook
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "rook-cluster rook-api Running"
	else
	     echo "rook-cluster rook-api Not Running"
	     return 1
	fi 

	isPodUp osd 1 rook
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "rook-cluster osd Started"
	else
	     echo "rook-cluster rook-api Not Started"
	     return 1
	fi 

	isPodRunning osd 1 rook
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "rook-cluster osd Running"
	else
	     echo "rook-cluster osd Not Running"
	     return 1
	fi 

	return 0
}

isTestPodUp(){
	TestPodName=$1

	isPodUp $TestPodName 1
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "$TestPodName Pod Started"
	else
	     echo "$TestPodName Pod Not Started"
	     return 1
	fi 

	isPodRunning $TestPodName 1
	iretval=$?
	if [ "$retval" == 0 ]
	then
	     echo "$TestPodName Running"
	else
	     echo "$TestPodName Not Running"
	     return 1
	fi 


	return 0
}


if [[ $1 == *"block"* ]]; then
  yaml="block_test.yaml"
else
	echo " Invalid argument - only block allowed, file and object storage tests are not yet implemented"
	exit 1
fi


echo "Start rook-operator Deploy"

kubectl create -f rook/rook-operator.yaml
rookOp=$?
if [ $rookOp -ne 0 ]; then
	echo "Could'nt start rook-operator deployment"
	exit 1
fi

isRookOperatorUp
isRookOpUp=$?
if [ $isRookOpUp -ne 0 ]; then
	echo "Couldn't start rook-operator"
	exit 1
fi
sleep 3
##
##
echo "Start rook-cluster Deploy"

kubectl create -f rook/rook-cluster.yaml
rookCluster=$?
if [ $rookCluster -ne 0 ]; then
	echo "Could'nt start rook-cluster deployment"
	exit 1
fi

isRookClusterUp
rookClusterUp=$?
if [ $rookClusterUp -ne 0 ]; then
	echo "Couldn't start rook-cluster"
	exit 1 
fi
sleep 3
##
##
echo "Create rook-storageclass"
sleep 5
export MONS=$(kubectl -n rook get pod mon0 mon1 mon2 -o json|jq ".items[].status.podIP"|tr -d "\""|sed -e 's/$/:6790/'|paste -s -d, -)
sed 's#INSERT_HERE#'$MONS'#' rook/rook-storageclass.yaml | kubectl create -f -
sleep 10

##
##

case $1 in

    #Run Block Tests
    [Bb][Ll][Oo][Cc][Kk])
		  echo "Starting Test Pod"
		  sed 's#INSERT_TEST_TYPE#'block'#' rook/block_test.yaml | kubectl create -f -
          ;;
    *) echo "Invalid Test Flag used"
		exit 1
         ;;

esac  

testPod=$?
if [ $testPod -ne 0 ]; then
	echo "Could'nt start testPod"
	exit 1
fi

isTestPodUp block-test
TestPodUp=$?
if [ $TestPodUp -ne 0 ]; then
	echo "Couldn't start Pod"
	exit 1
fi

checkTestResult block-test
testRes=$?
if [ $testRes == 0 ]
	then
	  echo "End 2 End Test Passed"
	  exit 0
else
	echo "End 2 End Test Failed"
	exit 1
fi


##
##

