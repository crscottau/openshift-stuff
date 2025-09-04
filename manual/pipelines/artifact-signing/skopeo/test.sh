#!/bin/sh

declare -x USE_SIGSTORE_ATTACHMENTS="\ \ use-sigstore-attachments: true"

sed -i "/^default-docker:/a\
  ${USE_SIGSTORE_ATTACHMENTS}" test.yaml

