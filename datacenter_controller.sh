#!/bin/bash

ADD="false"
DELETE="false"

#Input Parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -a|--add)
    DATACENTER_NAME="$2"
    ADD="true"
    shift # past argument
    shift # past value
    ;;
    -d|--delete)
    DATACENTER_NAME="$2"
    DELETE="true"
    shift # past argument
    shift # past value
    ;;
    -r|--region)
    DATACENTER_REGION="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--url)
    DATACENTER_URL="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--path)
    SCRIPT_PATH="$2"
    shift # past argument
    shift # past value
    ;;
    -i|--interval)
    INTERVAL="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ $ADD == "true" ]; then

    echo "[+] Adding ${DATACENTER_NAME} to CP Watchdog"

    #Add Datacenter Monitoring to CPWD
    cpwd_admin start -name "${DATACENTER_NAME}_${DATACENTER_REGION}" -path "${SCRIPT_PATH}" -command "${SCRIPT_PATH} -r ${DATACENTER_REGION} -t ${INTERVAL} -o ${DATACENTER_URL}" -retry_limit u
    sleep 30s

    echo "[+] Adding ${DATACENTER_NAME} Cloud Datacenter Object In Management Database"
    #Add New Datacenter Object
    mgmt_cli -r true add data-center-server name "${DATACENTER_NAME}_${DATACENTER_REGION}" type "generic" url "${DATACENTER_URL}" interval "${INTERVAL}" --format json | jq .

fi


if [ $DELETE == "true" ]; then

    echo "[-] Removing ${DATACENTER_NAME} from CP Watchdog"
    #Remove CPWD Monitoring
    cpwd_admin detach -name ${DATACENTER_NAME}_${DATACENTER_REGION}

    echo "[-] Removing ${DATACENTER_NAME} Cloud Datacenter Object In Management Database"
    #REmove Datacenter Object
    mgmt_cli -r true delete data-center-server name "${DATACENTER_NAME}_${DATACENTER_REGION}" --format json | jq .

    echo "[-] Removing ${DATACENTER_NAME} JSON Data"
    rm ${DATACENTER_URL}

fi
