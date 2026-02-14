# Terraform Tests for CloudLab Infrastructure
# These tests validate the infrastructure configuration

# Test: Validate droplet configuration
run "validate_droplet_configuration" {
  command = plan

  variables {
    do_token             = "dop_v1_test_token_for_validation_only"
    do_region            = "fra1"
    ssh_port             = 1923
    droplet_size         = "s-1vcpu-2gb"
    droplet_name         = "test-cloudlab-swarm"
    ssh_public_key_path  = "./test_fixtures/test_key.pub"
    ssh_private_key_path = "./test_fixtures/test_key"
  }

  # Validate droplet is created with correct configuration
  assert {
    condition     = digitalocean_droplet.swarm_manager.image == "ubuntu-24-04-x64"
    error_message = "Droplet must use Ubuntu 24.04 LTS"
  }

  assert {
    condition     = digitalocean_droplet.swarm_manager.size == "s-1vcpu-2gb"
    error_message = "Droplet size must match the specified size"
  }

  assert {
    condition     = digitalocean_droplet.swarm_manager.region == "fra1"
    error_message = "Droplet must be in the specified region"
  }

  assert {
    condition     = digitalocean_droplet.swarm_manager.monitoring == true
    error_message = "Monitoring must be enabled"
  }
}

# Test: Validate firewall rules
run "validate_firewall_rules" {
  command = plan

  variables {
    do_token             = "dop_v1_test_token_for_validation_only"
    do_region            = "fra1"
    ssh_port             = 1923
    droplet_size         = "s-1vcpu-2gb"
    droplet_name         = "test-cloudlab-swarm"
    ssh_public_key_path  = "./test_fixtures/test_key.pub"
    ssh_private_key_path = "./test_fixtures/test_key"
  }

  # Validate SSH port is configurable
  assert {
    condition     = contains([for rule in digitalocean_firewall.swarm.inbound_rule : rule.port_range], "1923")
    error_message = "Firewall must allow configured SSH port"
  }

  # Validate HTTP port is open
  assert {
    condition     = contains([for rule in digitalocean_firewall.swarm.inbound_rule : rule.port_range], "80")
    error_message = "Firewall must allow HTTP (port 80)"
  }

  # Validate HTTPS port is open
  assert {
    condition     = contains([for rule in digitalocean_firewall.swarm.inbound_rule : rule.port_range], "443")
    error_message = "Firewall must allow HTTPS (port 443)"
  }
}

# Test: Validate SSH key configuration
run "validate_ssh_key" {
  command = plan

  variables {
    do_token             = "dop_v1_test_token_for_validation_only"
    do_region            = "fra1"
    ssh_port             = 1923
    droplet_size         = "s-1vcpu-2gb"
    droplet_name         = "test-cloudlab-swarm"
    ssh_public_key_path  = "./test_fixtures/test_key.pub"
    ssh_private_key_path = "./test_fixtures/test_key"
  }

  assert {
    condition     = digitalocean_ssh_key.default.name == "cloudlab-swarm-key"
    error_message = "SSH key must have correct name"
  }
}

# Test: Validate tags are applied
run "validate_tags" {
  command = plan

  variables {
    do_token             = "dop_v1_test_token_for_validation_only"
    do_region            = "fra1"
    ssh_port             = 1923
    droplet_size         = "s-1vcpu-2gb"
    droplet_name         = "test-cloudlab-swarm"
    ssh_public_key_path  = "./test_fixtures/test_key.pub"
    ssh_private_key_path = "./test_fixtures/test_key"
    tags                 = ["cloudlab", "swarm", "test"]
  }

  assert {
    condition     = length(digitalocean_droplet.swarm_manager.tags) > 0
    error_message = "Droplet must have tags applied"
  }
}

# Test: Validate different regions
run "validate_region_nyc3" {
  command = plan

  variables {
    do_token             = "dop_v1_test_token_for_validation_only"
    do_region            = "nyc3"
    ssh_port             = 1923
    droplet_size         = "s-1vcpu-2gb"
    droplet_name         = "test-cloudlab-swarm"
    ssh_public_key_path  = "./test_fixtures/test_key.pub"
    ssh_private_key_path = "./test_fixtures/test_key"
  }

  assert {
    condition     = digitalocean_droplet.swarm_manager.region == "nyc3"
    error_message = "Droplet must be created in the specified region"
  }
}

# Test: Validate different droplet sizes
run "validate_larger_droplet" {
  command = plan

  variables {
    do_token             = "dop_v1_test_token_for_validation_only"
    do_region            = "fra1"
    ssh_port             = 1923
    droplet_size         = "s-2vcpu-4gb"
    droplet_name         = "test-cloudlab-swarm"
    ssh_public_key_path  = "./test_fixtures/test_key.pub"
    ssh_private_key_path = "./test_fixtures/test_key"
  }

  assert {
    condition     = digitalocean_droplet.swarm_manager.size == "s-2vcpu-4gb"
    error_message = "Droplet size must be configurable"
  }
}

# Test: Validate SSH port configuration
run "validate_custom_ssh_port" {
  command = plan

  variables {
    do_token             = "dop_v1_test_token_for_validation_only"
    do_region            = "fra1"
    ssh_port             = 2222
    droplet_size         = "s-1vcpu-2gb"
    droplet_name         = "test-cloudlab-swarm"
    ssh_public_key_path  = "./test_fixtures/test_key.pub"
    ssh_private_key_path = "./test_fixtures/test_key"
  }

  assert {
    condition     = contains([for rule in digitalocean_firewall.swarm.inbound_rule : rule.port_range], "2222")
    error_message = "Firewall must allow custom SSH port"
  }
}
