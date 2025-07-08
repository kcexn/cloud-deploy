#!/bin/bash
# Install Google Cloud Ops Agent only if script doesn't exist
if [ ! -f "add-google-cloud-ops-agent-repo.sh" ]; then
  echo "Downloading the Google Cloud Ops Agent."
  curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
  echo "Installing the Google Cloud Ops Agent."
  sudo bash add-google-cloud-ops-agent-repo.sh --also-install
  echo "Installed the Google Cloud Ops Agent."
fi