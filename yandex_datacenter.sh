#!/bin/bash

#Yandex API Default Settings
APIKEY="" #OAuth Token
YANDEX_CLOUD=""
FOLDER_ID=""
TIMER="120"
DEBUG_LOG="/var/log/datacenter.log"
OUTPUT_FILE="yandex_${API_REGION}.json"

#Input Parameters
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -r|--region)
    API_REGION="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--time)
    TIMER="$2"
    shift # past argument
    shift # past value
    ;;
    -o|--output)
    OUTPUT_FILE="$2"
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

#Get Yandex Cloud ID From Name (Take first cloud)
CLOUD_ID=$(curl_cli -s -k -X GET "https://resource-manager.api.cloud.yandex.net/resource-manager/v1/clouds" -H "Authorization: Bearer ${APIKEY}" | jq .clouds[0].id -r)

#Get Yandex Folder (Region) Id
FOLDER_JSON=$(curl_cli -s -k -X GET "https://resource-manager.api.cloud.yandex.net/resource-manager/v1/folders" -d '{"cloud_id":"'"${CLOUD_ID}"'"}' -H "Authorization: Bearer ${APIKEY}")
FOLDER_NUMBER=$(echo ${FOLDER_JSON} | jq '.folders | length')

FOLDER_COUNT=0
until [ $FOLDER_COUNT -eq $FOLDER_NUMBER ]; do
    FOLDER_NAME=$(echo ${FOLDER_JSON} | jq .folders[${FOLDER_COUNT}].name -r)
    
    if [ "$FOLDER_NAME" == "$API_REGION" ]; then
        FOLDER_ID=$(echo ${FOLDER_JSON} | jq .folders[${FOLDER_COUNT}].id -r)
    fi

    (( FOLDER_COUNT++ ))

done


while true; do
 
    #Write JSON Header
    #-------------------------------------------------------------------------------------------
    echo '{' > $OUTPUT_FILE
    echo '     "version": "1.0",' >> $OUTPUT_FILE
    echo '     "description": "Yandex Cloud",' >> $OUTPUT_FILE
    echo '     "objects": [' >> $OUTPUT_FILE
    #-------------------------------------------------------------------------------------------

    INSTANCE_JSON=$(curl_cli -s -k -X GET "https://compute.api.cloud.yandex.net/compute/v1/instances" -d '{"folderId":"'"${FOLDER_ID}"'"}' -H "Authorization: Bearer ${APIKEY}")
    INSTANCE_NUMBER=$(echo ${INSTANCE_JSON} | jq '.instances | length' )
    COUNT=0

    until [ $COUNT -eq $INSTANCE_NUMBER ]; do

        INSTANCE_NAME=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].name -r)
        INSTANCE_ID=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].id -r)
        INSTANCE_IF_NUMBER=$(echo ${INSTANCE_JSON} | jq '.instances['${COUNT}'].networkInterfaces | length')
        INSTANCE_VPC=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].zoneId -r)

        #Print
        echo " - Name: ${INSTANCE_NAME}"
        echo "   ID: ${INSTANCE_ID}"
        echo "   Profile: ${INSTANCE_PROFILE}"
        echo "   Region: ${INSTANCE_VPC}"
        echo "   Interfaces:"

        #Write JSON Instance Entry
        #-------------------------------------------------------------------------------------------
        echo '                          {' >> $OUTPUT_FILE
        echo '                               "name": "'${INSTANCE_NAME}'",' >> $OUTPUT_FILE
        echo '                               "id": "'${INSTANCE_ID}'",' >> $OUTPUT_FILE
        echo '                               "description": "Region: '${INSTANCE_VPC}', Profile: '${INSTANCE_PROFILE}'",' >> $OUTPUT_FILE
        echo '                               "ranges": [' >> $OUTPUT_FILE
        #-------------------------------------------------------------------------------------------

        INTERFACE_COUNT=0
        until [ "$INTERFACE_COUNT" == "$INSTANCE_IF_NUMBER" ]; do

            INSTANCE_IF_IP=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].networkInterfaces[${INTERFACE_COUNT}].primaryV4Address.address -r)
            INSTANCE_IF_PUBLIC_IP=$(echo ${INSTANCE_JSON} | jq .instances[${COUNT}].networkInterfaces[${INTERFACE_COUNT}].primaryV4Address.oneToOneNat.address -r)

            if [ "${INSTANCE_IF_PUBLIC_IP}" != "null" ]; then
                #Public IP attached to same interface
                echo '                                                 "'${INSTANCE_IF_PUBLIC_IP}'",' >> $OUTPUT_FILE
            fi

            #Print
            echo "   - ${INSTANCE_IF_IP}"
            (( INTERFACE_COUNT++ ))

            #Write JSON Instance Interface Entries
            #-------------------------------------------------------------------------------------------
            if [ $INTERFACE_COUNT == $INSTANCE_IF_NUMBER ]; then
                #Last interface
                echo '                                                 "'${INSTANCE_IF_IP}'"' >> $OUTPUT_FILE
            else
                echo '                                                 "'${INSTANCE_IF_IP}'",' >> $OUTPUT_FILE
            fi
            #-------------------------------------------------------------------------------------------
            
        done

        #Close JSON Instance Interface Entries
        #-------------------------------------------------------------------------------------------
        echo '                               ]' >> $OUTPUT_FILE
        #-------------------------------------------------------------------------------------------

        (( COUNT++ ))

        #Close JSON Instance Entry
        #-------------------------------------------------------------------------------------------
        if [ $COUNT == $INSTANCE_NUMBER ]; then
            #Last Instance
            echo "                          }" >> $OUTPUT_FILE
        else
            echo "                          }," >> $OUTPUT_FILE
        fi
        #-------------------------------------------------------------------------------------------

    done

    #JSON Footer
    #-------------------------------------------------------------------------------------------
    echo '     ]' >> $OUTPUT_FILE
    echo '}' >> $OUTPUT_FILE
    #-------------------------------------------------------------------------------------------

echo "[ Yandex Cloud: ${API_REGION} $(date +"%T")] Update Complete: ${INSTANCE_NUMBER} instances in ${API_REGION} region" >> $DEBUG_LOG

sleep ${TIMER}s
done
