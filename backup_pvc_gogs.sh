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
# */2  *  *  *  * root /home/sperezto/backup-rsync/ocp-tools/backup_pvc_gogs.sh -p gogs -d /var/nfsshare/backup-rsync
function usage(){
echo "Option -$OPTARG needs an argument." >&2
echo "Usage: $0 -p <Project-Name> -d </backup/path/> -l <label>(Optional|Default(deploymentconfig=gogs))" 
}

# Check if executed as OSE system:admin
if [[ "$(oc whoami)" != "admin" ]]; then
  echo -n "Trying to log in as system:admin... "
  #oc login -u system:admin > /dev/null && echo "done."
  oc login -u admin -predhat > /dev/null && echo "done."
fi

podlabel="deploymentconfig=gogs"
#No arguments
if [[ "$#" -eq 0 ]];then
        usage
else
	while getopts ":p:d:*:lh" option; do
	    case $option in
	        p)
	                PROJECT=$OPTARG
	                ;;
	
	        d)
	                DIRECTORY=$OPTARG
	                ;;
	        s)
	                podlabel=$OPTARG
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
	
	namespace=${PROJECT}
	pathbackup=${DIRECTORY}
	pvcNames=$(oc get pod ${POD} -n $namespace -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim)].name}')
	getpods=$(oc get pods -n $namespace -l ${podlabel} -o jsonpath='{range .items[*].metadata}{.name}{"\n"}{end}')
	ocproject=$(oc get project ${PROJECT} > /dev/null 2>&1)
	ocprojectresult=$?

	if [ ${ocprojectresult} -gt 0 ]; then
		echo "Option -p requires an existing OCP project."
	elif [[ -z ${DIRECTORY} ]];then
		echo "Option -d requires a directory."
	elif [[ -d ${DIRECTORY} ]];then
		if [ ${#pvcNames[@]} -eq 0 ]; then
			echo "Requires a pod with PVC"
		else
			if [[ -d ${pathbackup}/${namespace}/logs ]];then 
				# BACKUP log file
				exec > >(tee -ia ${pathbackup}/${namespace}/$(date +%Y%m%d)/logs/${namespace}-$(date +%Y-%m-%d_%H%M%S)-gogs_backup.log)
			else
				#BACKUP log file
				mkdir -p ${pathbackup}/${namespace}/$(date +%Y%m%d)/logs/
				exec > >(tee -ia ${pathbackup}/${namespace}/$(date +%Y%m%d)/logs/${namespace}-$(date +%Y-%m-%d_%H%M%S)-gogs_backup.log)
			fi
	        	for POD in ${getpods};do
				pathvolumeMounts=$(oc get pod ${POD} -n $namespace -o jsonpath='{ .spec.containers[].volumeMounts[*].mountPath }')
				namevolumeMounts=$(oc get pod ${POD} -n $namespace -o jsonpath='{ .spec.containers[].volumeMounts[*].name }')
				pvcNames=$(oc get pod ${POD} -n $namespace -o jsonpath='{.spec.volumes[?(@.persistentVolumeClaim)].name}')
				mountpoints=($pathvolumeMounts)
				volumenames=($namevolumeMounts)
				pvcs=($pvcNames)
				count=${#mountpoints[@]}
	        		for i in $(seq 1 $count);do
	        		    if [[ $pvcs == ${volumenames[$i-1]} ]];then
	        	    		echo "------------------------------------"
	        	    		echo "POD: ${POD}"
	        	    		echo "------------------------------------"
			    		if [[ -d ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD} ]];then
			    		    echo "Path: ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD} already exists"
			    		else
	        	    	   	    echo "mkdir -p ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}"
	        	    		    echo "------------------------------------"
			    		    echo "CREATING DIRECTORY: ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}"
	        	    		    echo "------------------------------------"
	        	    	   	    mkdir -p ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}
			    		fi
	        	    		echo "------------------------------------"
	        	    		echo "MOUNTPOINT: ${mountpoints[$i-1]} // VOLUMENAME: ${pvcs}"
	        	    		echo "------------------------------------"
					echo "Generating backup.zip from GOGS backup tool"
	        	    		echo "------------------------------------"
					echo "oc exec -it ${POD} -n $namespace -- mkdir -p ${mountpoints[$i-1]}/{zip,backups}"
					oc exec -it ${POD} -n $namespace -- mkdir -p ${mountpoints[$i-1]}/{zip,backups}
					echo "oc exec -it ${POD} -n $namespace -- /bin/bash -c '/opt/gogs/gogs backup --target /data/backups'"
					oc exec -it ${POD} -n $namespace -- /bin/bash -c '/opt/gogs/gogs backup --target /data/backups'
					#gogbackup=$(oc exec -it ${POD} -n $namespace -- /bin/bash -c '/opt/gogs/gogs backup --target /data/backups')
					#gogbackupresult=$?
        				#if [[ ${gogbackupresult} -gt 0 ]]; then
        				#        echo "[FATAL] Fail to dump database on ${POD}"
					#else
	        	    		echo "oc exec -it ${POD} -n $namespace -- /bin/bash -c 'tar cvfz /data/zip/$(date +%Y%m%d)-gogs-backup.tar.gz /data/backups'"
	        	    		oc exec -it ${POD} -n $namespace -- /bin/bash -c 'tar cvfz /data/zip/$(date +%Y%m%d)-gogs-backup.tar.gz /data/backups'
					#tarbackup=$(oc exec -it ${POD} -n $namespace -- /bin/bash -c 'tar cvfz /data/zip/$(date +%Y%m%d)-gogs-backup.tar.gz /data/backups')
					#tarbackupresult=$?
					#fi
        				#if [[ ${gogbackupresult} -eq 0 ]] && [[ ${tarbackupresult} -eq 0 ]]; then
	        	    		echo "oc rsync ${POD}:${mountpoints[$i-1]}/zip  ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}/ -n ${namespace}"
	        	    		oc rsync ${POD}:${mountpoints[$i-1]}/zip  ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}/ -n ${namespace}
	        	    		#copytarext=$(oc rsync ${POD}:${mountpoints[$i-1]}/zip  ${pathbackup}/${namespace}/$(date +%Y%m%d)/${POD}/ -n ${namespace})
					#copytarextresult=$?
					#fi
					#if [[ ${gogbackupresult} -eq 0 ]] && [[ ${tarbackupresult} -eq 0 ]] && [[ ${copytarextresult} -eq 0 ]]; then
					#	echo "Gog's Backup ended OK in ${POD}"
					#else
					#	echo "Gog's Backup ended Badly in ${POD}"
					#fi
				    fi
				done
	        	done
	        fi
	else
	  echo "Not a directory"
	fi
fi
