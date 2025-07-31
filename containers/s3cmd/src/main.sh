#!/bin/sh -e

#
# main entry point to run s3cmd
#
S3CMD_PATH=/usr/bin/s3cmd

#
# Check for required parameters
#
echo ${HOST}
if [ -z "${HOST}" ]; then
    echo "ERROR: The HOST environment variable is not set."
    exit 1
fi

if [ -z "${ACCESS_KEY}" ]; then
    echo "ERROR: The ACCESS_KEY environment variable is not set."
    exit 1
fi

if [ -z "${SECRET_KEY}" ]; then
    echo "ERROR: The SECRET_KEY environment variable secret is not set."
    exit 1
fi

if [ -z "${CMD}" ]; then
    echo "ERROR: The CMD environment variable cmd is not set."
    exit 1
fi

if [ -z "${HOST_BUCKET}" ]; then
    HOST_BUCKET='%{bucket}'
fi

#
# Replace key and secret in the /tmp/.s3cfg file with the one the user provided
#
echo "[default]" > /tmp/.s3cfg
echo "access_key=${ACCESS_KEY}" >> /tmp/.s3cfg
echo "secret_key=${SECRET_KEY}" >> /tmp/.s3cfg
echo "host_base=${HOST}" >> /tmp/.s3cfg
echo "host_bucket=${HOST_BUCKET}" >> /tmp/.s3cfg
if [[ ${DEBUG} ]]; then
  cat /tmp/.s3cfg
fi

#
# ls-s3
#
if [ "${CMD}" = "ls" ]; then
    echo "ls ${BUCKET}"
    ${S3CMD_PATH} ${NO_SSL} --config=/tmp/.s3cfg  ls ${BUCKET} 
fi
#
# sync-s3-to-local - copy from s3 to local
#
if [ "${CMD}" = "get" ]; then
    echo "get from ${BUCKET}"
    ${S3CMD_PATH} ${NO_SSL}  --config=/tmp/.s3cfg  get ${BUCKET}/${FILE} /opt/data/
fi
#
# sync-local-to-s3 - copy from local to s3
#
if [ "${CMD}" = "put" ]; then
    echo "put ${FILE} to ${BUCKET}"
    ${S3CMD_PATH} ${NO_SSL}  --config=/tmp/.s3cfg put /opt/data/${FILE} ${BUCKET}
fi
#
# sync-local-to-s3 - copy from local to s3
#
if [ "${CMD}" = "put-all-dir" ]; then
    echo "upload all files from /opt/data to ${BUCKET}"

    FILELIST=( $(ls /opt/data) )
    for FILE in "${FILELIST[@]}"; do
        if [ -d /opt/data/${FILE} ];then
            echo "skipping dir: ${FILE}"
        else
            echo "uploading: ${FILE}"
            ${S3CMD_PATH} ${NO_SSL}  --config=/tmp/.s3cfg put /opt/data/${FILE} ${BUCKET}
        fi
    done

fi
#
# clean up old files from a bucket
#
if [ "${CMD}" = "cleanup" ]; then
    echo "clean files older than ${AGE_THRESHOLD} from ${BUCKET}"

    ${S3CMD_PATH} ${NO_SSL} --config=/tmp/.s3cfg ls ${BUCKET}/ | while read -r line; do
        CREATE_DATE_STR=$(echo "$line" | awk '{print $1" "$2}')
        CREATE_DATE_EPOCH=$(date -d"$CREATE_DATE_STR" +%s)
        OLDER_THAN_EPOCH=$(date -d"-${AGE_THRESHOLD} days" +%s)
    
        if [[ $CREATE_DATE_EPOCH -lt $OLDER_THAN_EPOCH ]]; then
            FILE_NAME=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//')
            if [[ "$FILE_NAME" != "" ]]; then
                echo "Deleting ${FILE_NAME}"
                ${S3CMD_PATH} ${NO_SSL} --config=/tmp/.s3cfg del "${FILE_NAME}"
            fi
        fi
    done

fi
#
# Finished operations
#
echo "Finished s3cmd operations"