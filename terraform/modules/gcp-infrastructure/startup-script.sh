#!/bin/bash
# Install Google Cloud Ops Agent only if script doesn't exist
if [ ! -f "add-google-cloud-ops-agent-repo.sh" ]; then
  curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
  sudo bash add-google-cloud-ops-agent-repo.sh --also-install
fi
