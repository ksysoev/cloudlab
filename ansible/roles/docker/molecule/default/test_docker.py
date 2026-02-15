"""
Testinfra tests for docker role
"""
import pytest
import time


def test_docker_packages_installed(host):
    """Test that Docker packages are installed."""
    packages = [
        "docker-ce",
        "docker-ce-cli",
        "containerd.io",
        "docker-buildx-plugin",
        "docker-compose-plugin",
    ]
    for package in packages:
        pkg = host.package(package)
        assert pkg.is_installed, f"Package {package} should be installed"


def test_docker_service_running(host):
    """Test that Docker service is running and enabled."""
    service = host.service("docker")
    assert service.is_enabled, "Docker should be enabled"
    assert service.is_running, "Docker should be running"


def test_docker_daemon_config(host):
    """Test Docker daemon configuration."""
    config_file = host.file("/etc/docker/daemon.json")
    assert config_file.exists, "daemon.json should exist"
    assert config_file.contains('"log-driver": "json-file"'), "Log driver should be json-file"
    assert config_file.contains('"max-size": "10m"'), "Max log size should be 10m"
    assert config_file.contains('"max-file": "3"'), "Max log files should be 3"
    assert config_file.contains('"metrics-addr": "127.0.0.1:9323"'), "Metrics should be configured"


def test_deployer_in_docker_group(host):
    """Test that deployer user is in docker group."""
    user = host.user("deployer")
    assert "docker" in user.groups, "Deployer should be in docker group"


def test_docker_command_works(host):
    """Test that docker command works."""
    cmd = host.run("docker --version")
    assert cmd.rc == 0, "Docker command should work"
    assert "Docker version" in cmd.stdout, "Should show Docker version"


def test_docker_info(host):
    """Test docker info command."""
    cmd = host.run("docker info")
    assert cmd.rc == 0, "Docker info should work"


def test_docker_swarm_initialized(host):
    """Test that Docker Swarm is initialized."""
    # Give swarm a moment to fully initialize
    time.sleep(2)
    
    cmd = host.run("docker info")
    assert cmd.rc == 0, "Docker info should work"
    assert "Swarm: active" in cmd.stdout, "Swarm should be active"


def test_docker_swarm_manager_role(host):
    """Test that node has manager role."""
    cmd = host.run("docker node ls")
    assert cmd.rc == 0, "Should be able to list nodes as manager"


def test_docker_overlay_network_exists(host):
    """Test that overlay network is created."""
    # Give network creation a moment
    time.sleep(1)
    
    cmd = host.run("docker network ls")
    assert cmd.rc == 0, "Should be able to list networks"
    assert "test-network" in cmd.stdout, "Test overlay network should exist"
