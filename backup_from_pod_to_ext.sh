#!/bin/bash
function usage(){
echo "Usage: $0 <Project-Name> </backup/path/>"
exit 0
}

if [[ "$#" -eq 1 ]];then
	usage;

elif [[ "$#" -eq 2 ]];then
namespace=$1
pathbackup=$2
getpods=$(oc get pods -n $namespace -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}' --field-selector=status.phase==Running)

for POD in ${getpods};do
	mountpoints=$(oc get pod ${POD} -o jsonpath='{ .spec.containers[].volumeMounts[*].mountPath }' -n ${namespace})
	volumename=$(oc get pod ${POD} -o jsonpath='{ .spec.containers[].volumeMounts[*].name }' -n ${namespace})
	echo "------------------------------------"
	echo "POD: ${POD}"
	echo "------------------------------------"
	echo "mkdir -p ${pathbackup}/${namespace}/$(date +%Y-%m-%d_%H%M%S)/${POD}"
	#mkdir -p ${pathbackup}/${namespace}/$(date +%Y-%m-%d_%H%M%S)/${POD}
	echo "------------------------------------"
	for mountpoint in ${mountpoints};do
		echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+"
		echo "MOUNTPOINT: ${mountpoint}"
		echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+"
		echo "oc rsync ${POD}:${mountpoint} ${pathbackup}/${namespace}/$(date +%Y-%m-%d_%H%M%S)/${POD}/ -n ${namespace}"
		#oc rsync ${POD}:${mountpoint} ${pathbackup}/${namespace}/$(date +%Y-%m-%d_%H%M%S)/${POD}/ -n ${namespace}
	done
done
else
	usage;
fi
