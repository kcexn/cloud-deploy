#!/bin/bash

# Cluster deployment automation system
# Copyright 2025 Kevin Exton
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Function to display usage
usage() {
    echo "Usage: $0 <environment>"
    echo "Example: $0 development"
    echo "         $0 production"
    exit 1
}

# Check if environment is provided
if [ $# -ne 1 ]; then
    usage
fi

ENVIRONMENT="$1"
TERRAFORM_DIR="${REPO_ROOT}/terraform/environments/${ENVIRONMENT}"

# Validate environment directory
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Terraform environment directory not found: $TERRAFORM_DIR"
    exit 1
fi

# Check if terraform is initialized
if [ ! -d "$TERRAFORM_DIR/.terraform" ]; then
    echo "Error: Terraform not initialized in $TERRAFORM_DIR"
    echo "Run: cd $TERRAFORM_DIR && terraform init"
    exit 1
fi

echo "Synchronizing Ansible inventory for environment: $ENVIRONMENT"
echo "Terraform directory: $TERRAFORM_DIR"
