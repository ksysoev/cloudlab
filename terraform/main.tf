# Main Terraform configuration
# This file ties together all resources

# Local values for reuse
locals {
  common_tags = concat(var.tags, ["environment:production"])
  timestamp   = formatdate("YYYY-MM-DD-hhmm", timestamp())
}
