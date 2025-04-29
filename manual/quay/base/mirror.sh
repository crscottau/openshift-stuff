#!/bin/bash
#
# Use the ubi:95 image for the pod
# Need to use python instead of jq
#
# The TAG_GLOB parameter is an array of regex patterns to match tags to mirror, eg: '[ "*" ]'
#
# The UPDATE_SOURCE_PASSWORD parameter allows for the script to be run manually if the password on the 
# service account needs to be updated in the mirror configurations, it leads to all exsting mirror 
# configurations being replaced.
#
#set -euo pipefail

# Start date for any mirror config is now (UTC)
NOW=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# Environmental variables
echo "Source registry: ${SOURCE_REGISTRY}"
#echo "Source API token: ${SOURCE_API_TOKEN}"
echo "Source username: ${SOURCE_USERNAME}"
#echo "Source password: ${SOURCE_PASSWORD}"
echo "Destination registry: ${DESTINATION_REGISTRY}"
#echo "Destination API token: ${DESTINATION_API_TOKEN}"
echo "Destination robot name: ${DESTINATION_ROBOT}"
echo "Namespace: ${NAMESPACE}"
echo "Tag glob regex array: ${TAG_GLOB}"
echo "Sync interval: ${SYNC_INTERVAL}"
echo "Recreate mirror configuration: ${RECREATE_MIRROR_CONFIG}"
echo "Dry run: ${DRY_RUN}"
echo "Debug logging: ${DEBUG}"
echo ""

# Run the command or skip execution for a DRY_RUN
dry_run_or_execute () {
  # echo the command for debugging purposes
  if [[ ${DEBUG}  == true ]]; then
    echo ">>>> API command: '$*'"
  fi

  local RESULT=0
  if [[ ${DRY_RUN} == true ]]; then
    echo "DRY RUN MODE! Skipping execution..."
  else
    echo "Executing command..."
    eval " $*"
    RESULT=$?
  fi
  echo "API Result: ${RESULT}"
  return ${RESULT}
}

 # Create a repository
create_repo() {
  echo "Creating destination repository: $1/$2"
  COMMAND="curl -s -X POST -H \"Authorization: Bearer ${DESTINATION_API_TOKEN}\" -H \"Content-Type: application/json\" --data '{\"namespace\":\"$1\",\"repository\":\"$2\",\"visibility\":\"private\",\"description\":\"Mirrored from ${SOURCE_REGISTRY}\",\"repo_kind\":\"image\"}' https://${DESTINATION_REGISTRY}/api/v1/repository"

  dry_run_or_execute $COMMAND
  RESULT=$?

  if [ ${RESULT} -ne 0 ]; then
    echo "ERROR: Create repo failed with return code: ${RESULT}"
  fi
}

# Setup mirroring on a repositoy
mirror_repo() {
  if [[ $3 == UPDATE ]]; then
    echo "Overwriting existing mirror config on destination repository: $1/$2"
    METHOD="PUT"
  else
    echo "Setting up mirror config on destination repository: $1/$2"
    METHOD="POST"
  fi
  COMMAND="curl -s -X ${METHOD} -H \"Authorization: Bearer ${DESTINATION_API_TOKEN}\" -H \"Content-Type: application/json\" --data '{\"external_reference\":\"${SOURCE_REGISTRY}/$1/$2\",\"external_registry_username\":\"${SOURCE_USERNAME}\",\"external_registry_password\":\"${SOURCE_PASSWORD}\",\"sync_interval\":${SYNC_INTERVAL},\"sync_start_date\":\"${NOW}\",\"root_rule\":{\"rule_kind\":\"tag_glob_csv\",\"rule_value\":${TAG_GLOB}},\"robot_username\":\"${DESTINATION_ROBOT}\"}' https://${DESTINATION_REGISTRY}/api/v1/repository/$1/$2/mirror"

  dry_run_or_execute $COMMAND
  RESULT=$?

  if [ ${RESULT} -ne 0 ]; then
    echo "ERROR: Enabling mirroring on repo failed with return code: ${RESULT}"
  fi
}

echo "Returning the list of repositories in the ${NAMESPACE} organisation/namespace"
# Return the lost of repos within the organisation to be mirrored
REPO_LIST=$(curl -s -X GET -H "Authorization: Bearer ${SOURCE_API_TOKEN}" https://${SOURCE_REGISTRY}/api/v1/repository?namespace=${NAMESPACE}|python3 -c "import sys, json; result =json.load(sys.stdin); print([repo['name'] for repo in result['repositories']])"|sort)

for REPO in ${REPO_LIST[@]//[\[\]\'\,]/}
do
  echo ""
  echo Checking for mirror in destination repository: ${NAMESPACE}/${REPO}
  REPO_DETAILS=$(curl -s -X GET -H "Authorization: Bearer ${DESTINATION_API_TOKEN}" https://${DESTINATION_REGISTRY}/api/v1/repository/${NAMESPACE}/${REPO})
  REPO_STATE=$(echo $REPO_DETAILS|python3 -c "import sys, json; result = json.load(sys.stdin); print(result['state'])" 2> /dev/null)
  if [[ ${DEBUG} == true ]]; then
    echo ">>>> REPO_STATE: '${REPO_STATE}'"
  fi 

  if [[ ${REPO_STATE} == MIRROR ]]
  then
    if [[ ${RECREATE_MIRROR_CONFIG} == true ]]
    then
      echo "Destination repository is mirrored, but RECREATE_MIRROR_CONFIG flag is set"
      mirror_repo ${NAMESPACE} ${REPO} "UPDATE"
    else
      echo "Destination repository is mirrored, nothing to do"
    fi
  elif [[ ${REPO_STATE} == NORMAL ]]
  then
    echo "Destination repository exists, but is not a mirror"
    mirror_repo ${NAMESPACE} ${REPO}
  else
    echo "Destination repository does not exist"
    create_repo ${NAMESPACE} ${REPO}
    mirror_repo ${NAMESPACE} ${REPO}
  fi
done
