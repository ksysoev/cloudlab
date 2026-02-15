#!/usr/bin/env python3
"""
Dynamic inventory script for Ansible that fetches droplet information from Terraform outputs.
"""
import json
import os
import subprocess
import sys


def get_terraform_outputs():
    """Fetch Terraform outputs from Terraform Cloud or local state."""
    # Try to get outputs from local terraform if available
    terraform_dir = os.path.join(os.path.dirname(__file__), '..', '..', 'terraform')
    
    try:
        result = subprocess.run(
            ['terraform', 'output', '-json'],
            cwd=terraform_dir,
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error fetching Terraform outputs: {e.stderr}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("Terraform binary not found in PATH", file=sys.stderr)
        sys.exit(1)


def build_inventory(terraform_outputs):
    """Build Ansible inventory from Terraform outputs."""
    # Extract values from Terraform outputs
    droplet_ip = terraform_outputs.get('droplet_ip', {}).get('value', '')
    ssh_port = terraform_outputs.get('ssh_port', {}).get('value', 1923)
    
    if not droplet_ip:
        print("Error: droplet_ip not found in Terraform outputs", file=sys.stderr)
        sys.exit(1)
    
    inventory = {
        '_meta': {
            'hostvars': {
                'swarm_manager': {
                    'ansible_host': droplet_ip,
                    'ansible_port': ssh_port,
                    'ansible_user': 'deployer',
                    'ansible_python_interpreter': '/usr/bin/python3'
                }
            }
        },
        'swarm': {
            'hosts': ['swarm_manager']
        },
        'all': {
            'children': ['swarm']
        }
    }
    
    return inventory


def main():
    """Main entry point."""
    if len(sys.argv) == 2 and sys.argv[1] == '--list':
        terraform_outputs = get_terraform_outputs()
        inventory = build_inventory(terraform_outputs)
        print(json.dumps(inventory, indent=2))
    elif len(sys.argv) == 3 and sys.argv[1] == '--host':
        # Return empty dict for host-specific vars (we use _meta)
        print(json.dumps({}))
    else:
        print("Usage: production.py --list or production.py --host <hostname>", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
