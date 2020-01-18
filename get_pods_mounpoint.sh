#############################################################################
## Copyleft (.) Jan 2020                                                   ##
## silvinux7@gmail.com                                                     ##
#############################################################################
## This program is free software; you can redistribute it and/or modify    ##
## it under the terms of the GNU General Public License as published by    ##
## the Free Software Foundation; either version 3 of the License, or       ##
## (at your option) any later version.                                     ##
##                                                                         ##
## This program is distributed in the hope that it will be useful,         ##
## but WITHOUT ANY WARRANTY; without even the implied warranty of          ##
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           ##
## GNU General Public License for more details.                            ##
#############################################################################
#!/bin/bash
if [[ "$#" -gt 0 ]]  && [[ "$#" -lt 2 ]];then
namespace=$1
ocproject=$(oc get project ${namespace} > /dev/null 2>&1)
ocprojectresult=$?
if [ ${ocprojectresult} -gt 0 ]; then
        echo "Requires an existing OCP project."
else
getpods=$(oc get pods -n $namespace -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}' --field-selector=status.phase==Running)
for POD in ${getpods};do
	pathvolumeMounts=$(oc get pod ${POD} -o jsonpath='{ .spec.containers[].volumeMounts[*].mountPath }' -n $namespace)
	namevolumeMounts=$(oc get pod ${POD} -o jsonpath='{ .spec.containers[].volumeMounts[*].name }' -n $namespace)
	pvcNames=$(oc get pod ${POD} -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim)].name}' -n $namespace)
	mountpoints=($pathvolumeMounts)
	volumenames=($namevolumeMounts)
	pvcs=($pvcNames)
	count=${#mountpoints[@]}
	for i in $(seq 1 $count);do
	    if [[ $pvcs == ${volumenames[$i-1]} ]];then
	    	echo "-------------------------------"
	    	echo POD: ${POD}
	    	echo MountPoint: ${mountpoints[$i-1]} 
	    	echo VolumeName: ${volumenames[$i-1]}
	    	echo "oc rsync ${POD}:${mountpoints[$i-1]}"
	    	echo "-------------------------------"
	    fi
	done
done
fi
else
	echo "Usage: $0 <Project-Name>"
fi
