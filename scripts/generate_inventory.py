#!/usr/bin/env python3
"""
Generate Ansible inventory from Terraform outputs.

This script reads Terraform outputs and generates an Ansible inventory file
that synchronizes with the infrastructure defined in Terraform.
"""

import json
import subprocess
import sys
import os
import yaml
from pathlib import Path
from typing import Dict, Any


def run_terraform_output(terraform_dir: str) -> Dict[str, Any]:
    """Run terraform output and return the JSON data."""
    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running terraform output: {e}")
        print(f"stderr: {e.stderr}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error parsing terraform output JSON: {e}")
        sys.exit(1)


def extract_inventory_data(terraform_output: Dict[str, Any]) -> Dict[str, Any]:
    """Extract ansible inventory data from terraform output."""
    if "ansible_inventory_data" not in terraform_output:
        print("Error: ansible_inventory_data output not found in terraform output")
        sys.exit(1)
    
    return terraform_output["ansible_inventory_data"]["value"]


def generate_inventory(inventory_data: Dict[str, Any]) -> Dict[str, Any]:
    """Generate Ansible inventory structure from terraform data."""
    inventory = {
        "all": {
            "children": {}
        }
    }
    
    env = inventory_data["env"]
    hosts = inventory_data["hosts"]
    groups = inventory_data["groups"]
    
    # Create environment group
    env_group = {
        "children": {},
        "hosts": {},
        "vars": {
            "region": inventory_data["region"],
            "env": env
        }
    }
    
    # Add hosts to environment group
    for host_name, host_data in hosts.items():
        env_group["hosts"][host_name] = {
            "ansible_host": host_data["ansible_host"]
        }
    
    # Create node group children
    for group_name, group_data in groups.items():
        group_hosts = {}
        for host_name in group_data["hosts"]:
            if host_name in hosts:
                group_hosts[host_name] = env_group["hosts"][host_name]
        
        if group_hosts:
            env_group["children"][group_name] = {
                "hosts": group_hosts,
                "vars": group_data["vars"]
            }
    
    inventory["all"]["children"][env] = env_group
    
    return inventory

def write_inventory(inventory: Dict[str, Any], output_path: Path) -> None:
    """Write inventory to YAML file."""
    with open(output_path, 'w') as f:
        yaml.dump(inventory, f, default_flow_style=False, sort_keys=False)
    print(f"Generated inventory written to {output_path}")


def main():
    """Main function."""
    if len(sys.argv) != 2:
        print("Usage: generate_inventory.py <terraform_environment_dir>")
        print("Example: generate_inventory.py terraform/environments/development")
        sys.exit(1)
    
    terraform_dir = sys.argv[1]
    
    # Validate terraform directory
    if not os.path.isdir(terraform_dir):
        print(f"Error: {terraform_dir} is not a directory")
        sys.exit(1)
    
    terraform_main = os.path.join(terraform_dir, "main.tf")
    if not os.path.isfile(terraform_main):
        print(f"Error: {terraform_main} not found")
        sys.exit(1)
    
    # Get terraform output
    print(f"Reading terraform output from {terraform_dir}")
    terraform_output = run_terraform_output(terraform_dir)
    
    # Extract inventory data
    inventory_data = extract_inventory_data(terraform_output)
    
    # Generate inventory
    inventory = generate_inventory(inventory_data)
    
    # Determine output path
    repo_root = Path(__file__).parent.parent
    inventory_path = repo_root / "inventory" / "hosts.yml"

    # Write new inventory
    write_inventory(inventory, inventory_path)
    
    print("Inventory generation completed successfully!")


if __name__ == "__main__":
    main()
