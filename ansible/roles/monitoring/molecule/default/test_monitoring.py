"""
Testinfra tests for monitoring role
"""
import pytest


def test_alloy_package_installed(host):
    """Test that Grafana Alloy package is installed."""
    package = host.package("alloy")
    assert package.is_installed, "Alloy should be installed"


def test_alloy_user_exists(host):
    """Test that alloy system user exists."""
    user = host.user("alloy")
    assert user.exists, "Alloy user should exist"
    assert user.shell == "/usr/sbin/nologin", "Alloy should have nologin shell"
    assert "docker" in user.groups, "Alloy user should be in docker group"


def test_alloy_data_directory(host):
    """Test that alloy data directory exists with correct permissions."""
    data_dir = host.file("/var/lib/alloy/data")
    assert data_dir.exists, "Alloy data directory should exist"
    assert data_dir.is_directory, "Should be a directory"
    assert data_dir.user == "alloy", "Should be owned by alloy user"
    assert data_dir.group == "alloy", "Should be owned by alloy group"


def test_alloy_configuration(host):
    """Test that alloy configuration file exists."""
    config_file = host.file("/etc/alloy/config.alloy")
    assert config_file.exists, "Alloy config should exist"
    assert config_file.contains("test-swarm"), "Should contain instance name"
    assert config_file.contains("logging {"), "Should have logging config"
    assert config_file.contains("prometheus.exporter.unix"), "Should have node exporter"
    assert config_file.contains("loki.write"), "Should have loki writer"


def test_alloy_environment_file(host):
    """Test that alloy environment file exists."""
    env_file = host.file("/etc/default/alloy")
    assert env_file.exists, "Alloy environment file should exist"
    assert env_file.contains('CONFIG_FILE="/etc/alloy/config.alloy"'), "Should set config path"


def test_alloy_service(host):
    """Test that alloy service is enabled and running."""
    service = host.service("alloy")
    assert service.is_enabled, "Alloy should be enabled"
    assert service.is_running, "Alloy should be running"


def test_grafana_repository_configured(host):
    """Test that Grafana APT repository is configured."""
    repo_file = host.file("/etc/apt/sources.list.d/grafana.list")
    assert repo_file.exists, "Grafana repo should be configured"
    assert repo_file.contains("https://apt.grafana.com"), "Should contain Grafana APT URL"
    
    gpg_key = host.file("/etc/apt/keyrings/grafana.gpg")
    assert gpg_key.exists, "Grafana GPG key should exist"
