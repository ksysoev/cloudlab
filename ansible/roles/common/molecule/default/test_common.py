"""
Testinfra tests for common role
"""
import pytest


def test_base_packages_installed(host):
    """Test that all base packages are installed."""
    packages = [
        "apt-transport-https",
        "ca-certificates",
        "curl",
        "gnupg",
        "lsb-release",
        "unattended-upgrades",
        "fail2ban",
        "ufw",
        "jq",
    ]
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed, f"Package {package} should be installed"


def test_auto_upgrades_configured(host):
    """Test that automatic security updates are configured."""
    config_file = host.file("/etc/apt/apt.conf.d/20auto-upgrades")
    assert config_file.exists, "Auto-upgrades config should exist"
    assert config_file.contains('APT::Periodic::Update-Package-Lists "1"')
    assert config_file.contains('APT::Periodic::Unattended-Upgrade "1"')


def test_cloudlab_directories_exist(host):
    """Test that cloudlab directory structure is created."""
    directories = [
        "/opt/cloudlab",
        "/opt/cloudlab/scripts",
        "/opt/cloudlab/stacks",
    ]
    for directory in directories:
        dir_obj = host.file(directory)
        assert dir_obj.exists, f"Directory {directory} should exist"
        assert dir_obj.is_directory, f"{directory} should be a directory"
        assert dir_obj.user == "deployer", f"{directory} should be owned by deployer"
        assert dir_obj.group == "deployer", f"{directory} should be group deployer"
        assert dir_obj.mode == 0o755, f"{directory} should have mode 755"


def test_deployer_user_exists(host):
    """Test that deployer user exists."""
    user = host.user("deployer")
    assert user.exists, "Deployer user should exist"
    assert user.shell == "/bin/bash", "Deployer should have bash shell"
