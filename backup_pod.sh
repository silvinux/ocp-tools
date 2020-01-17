#!/bin/bash
function usage(){
echo "Option -$OPTARG needs an argument." >&2
echo "Usage: $0 -p <Project-Name> -d </backup/path/> -s <status.phase><Succeeded> (Optional|Default(Running))" 
}

statusphase=Running
#No arguments
if [[ "$#" -eq 0 ]];then
        usage
else
while getopts ":p:d:*:sh" option; do
    case $option in
        p)
                PROJECT=$OPTARG
                ;;

        d)
                DIRECTORY=$OPTARG
                ;;
        s)
                statusphase=Succeeded
                ;;
        h)
                usage
		exit 0
                ;;
        \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
        :)
                echo "Option -$OPTARG requires an argument." >&2
                exit 1
                ;;
esac
done

ocproject=$(oc get project ${PROJECT} > /dev/null 2>&1)
ocprojectresult=$?
if [ ${ocprojectresult} -gt 0 ]; then
	echo "Option -p requires an existing OCP project."
elif [[ -z ${DIRECTORY} ]];then
	echo "Option -d requires a directory."
elif [[ -d ${DIRECTORY} ]];then
	namespace=${PROJECT}
	pathbackup=${DIRECTORY}

	# BACKUP log file
	exec > >(tee -ia ${pathbackup}/${namespace}-$(date +%Y%m%d)-ocp_backup.log)
	# BACKUP log file

        getpods=$(oc get pods -n $namespace -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}' --field-selector=status.phase==${statusphase})
        for POD in ${getpods};do
            mountpoints=$(oc get pod ${POD} -o jsonpath='{ .spec.containers[].volumeMounts[*].mountPath }' -n ${namespace})
            volumename=$(oc get pod ${POD} -o jsonpath='{ .spec.containers[].volumeMounts[*].name }' -n ${namespace})
            echo "------------------------------------"
            echo "POD: ${POD}"
            echo "------------------------------------"
	    if [[ -d ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD} ]];then
            	echo "mkdir -p ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}"
            	#mkdir -p ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}
	    else
		echo "Path: ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD} already exists"
	    fi
            echo "------------------------------------"
            for mountpoint in ${mountpoints};do
            	    echo "------------------------------------"
                    echo "MOUNTPOINT: ${mountpoint}"
            	    echo "------------------------------------"
                    echo "oc rsync ${POD}:${mountpoint} ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}/ -n ${namespace}"
                    #oc rsync ${POD}:${mountpoint} ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}/ -n ${namespace}
            done
        done

else
  echo "Not a directory"
fi
fi
