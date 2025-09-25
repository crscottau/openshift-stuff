#!/bin/bash

# Nested loop program
# Outer loop: iterate from ${START_VER} to ${END_VER}
# Inner loop: iterate from 1 to 99
# Usage: ./test.sh <START_VER> <END_VER>

# Check if correct number of arguments provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <START_VER> <END_VER>"
    echo "Example: $0 15 19"
    exit 1
fi

# Assign command line arguments to variables
START_VER=$1
END_VER=$2

# Validate that arguments are numbers
if ! [[ "$START_VER" =~ ^[0-9]+$ ]] || ! [[ "$END_VER" =~ ^[0-9]+$ ]]; then
    echo "Error: Both START_VER and END_VER must be positive integers"
    echo "Usage: $0 <START_VER> <END_VER>"
    exit 1
fi

# Validate that START_VER is not greater than END_VER
if [ "$START_VER" -gt "$END_VER" ]; then
    echo "Error: START_VER ($START_VER) cannot be greater than END_VER ($END_VER)"
    exit 1
fi

echo "Processing OpenShift versions 4.$START_VER to 4.$END_VER"

for MINOR in $(seq ${START_VER} ${END_VER}); do
    echo "4.${MINOR}"
    
    for PATCH in {1..99}; do

        echo "Downloading signatures for patch: 4.${MINOR}.${PATCH}"
        OCP_RELEASE=4.${MINOR}.${PATCH}
        ARCHITECTURE=x86_64

        if [ -f checksum-${OCP_RELEASE}.yaml ]; then
            echo "Skipping ${OCP_RELEASE}, already downloaded"
        else
            DIGEST="$(oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE}-${ARCHITECTURE} | sed -n 's/Pull From: .*@//p')"
            echo ${DIGEST}
            # Check if the DIGEST output starts with "error:"
            if [ -z "$DIGEST" ]; then
                echo "  Error getting release info for version $OCP_RELEASE - breaking inner loop"
                break
            fi
            DIGEST_ALGO="${DIGEST%%:*}"
            DIGEST_ENCODED="${DIGEST#*:}"
            HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/signature_temp "https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/${DIGEST_ALGO}=${DIGEST_ENCODED}/signature-1")
            if [ "$HTTP_CODE" = "404" ]; then
                echo "404 Signature Not Found for version $OCP_RELEASE - breaking inner loop"
            fi
            SIGNATURE_BASE64=$(cat /tmp/signature_temp | base64 -w0 && echo)
cat >checksum-${OCP_RELEASE}.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-image-${OCP_RELEASE}
  namespace: openshift-config-managed
  labels:
    release.openshift.io/verification-signatures: ""
binaryData:
  ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64}
EOF
      fi
    done
done
