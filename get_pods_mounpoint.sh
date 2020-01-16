#!/bin/bash
if [[ "$#" -gt 0 ]]  && [[ "$#" -lt 2 ]];then
namespace=$1
getpods=$(oc get pods -n $namespace -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}')
for POD in ${getpods};do
	mountpoints=$(oc get pod ${POD} -o jsonpath='{ .spec.containers[].volumeMounts[*].mountPath }' -n $namespace)
	for mountpoint in ${mountpoints};do
		echo "${POD}:${mountpoint}"
	done
done
else
	echo "Usage: $0 <Project-Name>"
fi
