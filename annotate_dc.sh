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
getpods=$(oc get pods -n ${namespace} -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}' --field-selector=status.phase==Running)
getdcs=$(oc get dc -n ${namespace} -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}')
for DC in ${getdcs};do
	namevolumeMounts=$(oc get dc/${DC} -n ${namespace} -o jsonpath='{.spec.template.spec.volumes[?(@.persistentVolumeClaim)].name}')
	volumenames=($namevolumeMounts)
	count=${#volumenames[@]}
	if [[ ${#volumenames[@]} -eq 1 ]];then
	for i in $(seq 1 $count);do
	    echo "-------------------------------"
	    echo VolumeName: ${volumenames[$i-1]}
	    echo "oc patch dc/${DC} -n ${namespace} -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"backup.velero.io/backup-volumes\": \"${volumenames[$i-1]}\"}}}}}'"
	    oc patch dc/${DC} -n ${namespace} -p '{"spec":{"template":{"metadata":{"annotations":{"backup.velero.io/backup-volumes": "'${volumenames[$i-1]}'"}}}}}'
	    echo "-------------------------------"
	done
	elif [[ ${#volumenames[@]} -gt 1 ]];then
	for i in ${volumenames};do
	    echo "-------------------------------"
	    volumenamesmoreone=$(printf ",%s" "${volumenames[@]}")
	    volumenamesmoreone=${volumenamesmoreone:1}
	    echo VolumeNames: ${volumenamesmoreone}
	    echo "oc patch dc/${DC} -n ${namespace} -p '{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"backup.velero.io/backup-volumes\": \"${volumenamesmoreone}\"}}}}}'"
	    oc patch dc/${DC} -n ${namespace} -p '{"spec":{"template":{"metadata":{"annotations":{"backup.velero.io/backup-volumes": "'${volumenamesmoreone}'"}}}}}'
	    echo "-------------------------------"
	done
	fi
done
fi
else
	echo "Usage: $0 <Project-Name>"
fi
