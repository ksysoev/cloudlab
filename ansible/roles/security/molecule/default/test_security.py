"""
Testinfra tests for security role
"""
import pytest


def test_ufw_is_enabled(host):
    """Test that UFW firewall is enabled."""
    ufw_status = host.run("ufw status")
    assert ufw_status.rc == 0, "UFW should be running"
    assert "Status: active" in ufw_status.stdout, "UFW should be active"


def test_ufw_default_policies(host):
    """Test UFW default policies are set correctly."""
    ufw_status = host.run("ufw status verbose")
    assert "Default: deny (incoming)" in ufw_status.stdout
    assert "Default: allow (outgoing)" in ufw_status.stdout


def test_ufw_rules_configured(host):
    """Test that UFW rules are properly configured."""
    ufw_status = host.run("ufw status numbered")
    
    # Check SSH port rule
    assert "1923" in ufw_status.stdout, "SSH port 1923 should be allowed"
    
    # Check web ports
    assert "80" in ufw_status.stdout, "HTTP port 80 should be allowed"
    assert "443" in ufw_status.stdout, "HTTPS port 443 should be allowed"


def test_fail2ban_installed_and_running(host):
    """Test that fail2ban is installed and running."""
    package = host.package("fail2ban")
    assert package.is_installed, "fail2ban should be installed"
    
    service = host.service("fail2ban")
    assert service.is_enabled, "fail2ban should be enabled"
    assert service.is_running, "fail2ban should be running"


def test_fail2ban_jail_configuration(host):
    """Test fail2ban jail configuration."""
    jail_file = host.file("/etc/fail2ban/jail.local")
    assert jail_file.exists, "jail.local should exist"
    assert jail_file.contains("[sshd]"), "SSHD jail should be configured"
    assert jail_file.contains("enabled = true"), "SSHD jail should be enabled"
    assert jail_file.contains("port = 1923"), "SSHD jail should use custom port"
    assert jail_file.contains("maxretry = 5"), "SSHD jail should have maxretry set"
    assert jail_file.contains("bantime = 3600"), "SSHD jail should have bantime set"


def test_ssh_hardening_config(host):
    """Test SSH hardening configuration."""
    ssh_config = host.file("/etc/ssh/sshd_config.d/custom_port.conf")
    assert ssh_config.exists, "SSH custom config should exist"
    assert ssh_config.contains("Port 1923"), "SSH should use custom port"
    assert ssh_config.contains("PermitRootLogin no"), "Root login should be disabled"
    assert ssh_config.contains("PasswordAuthentication no"), "Password auth should be disabled"


def test_ssh_service_running(host):
    """Test that SSH service is running."""
    service = host.service("ssh")
    assert service.is_enabled, "SSH should be enabled"
    assert service.is_running, "SSH should be running"


def test_ufw_tcp_port_range_rules(host):
    """Test that UFW TCP port range rules are configured."""
    ufw_status = host.run("ufw status")
    assert ufw_status.rc == 0, "UFW should be running"
    assert "10000:10999" in ufw_status.stdout, "TCP port range 10000:10999 should be allowed"
