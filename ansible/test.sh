#!/bin/bash
# Test runner script for Ansible roles
# Usage: ./test.sh [role_name] or ./test.sh all

set -e

ROLES_DIR="roles"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Function to test a single role
test_role() {
    local role=$1
    log_info "Testing role: $role"
    
    if [ ! -d "$ROLES_DIR/$role/molecule" ]; then
        log_warn "No molecule tests found for role: $role"
        return 0
    fi
    
    cd "$ROLES_DIR/$role"
    
    if molecule test; then
        log_info "✓ Tests passed for role: $role"
        cd "$SCRIPT_DIR"
        return 0
    else
        log_error "✗ Tests failed for role: $role"
        cd "$SCRIPT_DIR"
        return 1
    fi
}

# Function to run lint checks
run_lint() {
    log_info "Running lint checks..."
    
    log_info "Running yamllint..."
    if yamllint .; then
        log_info "✓ yamllint passed"
    else
        log_warn "⚠ yamllint found issues"
    fi
    
    log_info "Running ansible-lint..."
    if ansible-lint; then
        log_info "✓ ansible-lint passed"
    else
        log_error "✗ ansible-lint found issues"
        return 1
    fi
}

# Main script
main() {
    cd "$SCRIPT_DIR"
    
    # Check if molecule is installed
    if ! command -v molecule &> /dev/null; then
        log_error "Molecule is not installed. Please install requirements-test.txt"
        exit 1
    fi
    
    # Install Ansible collections
    log_info "Installing Ansible collections..."
    ansible-galaxy collection install -r requirements.yml
    
    local role=${1:-all}
    local failed=0
    
    if [ "$role" == "lint" ]; then
        run_lint
        exit $?
    fi
    
    if [ "$role" == "all" ]; then
        log_info "Testing all roles..."
        
        # Run lint first
        run_lint || ((failed++))
        
        # Test each role
        for role_dir in $ROLES_DIR/*/; do
            role_name=$(basename "$role_dir")
            test_role "$role_name" || ((failed++))
        done
        
        if [ $failed -eq 0 ]; then
            log_info "✓ All tests passed!"
            exit 0
        else
            log_error "✗ $failed test(s) failed"
            exit 1
        fi
    else
        # Test specific role
        if [ ! -d "$ROLES_DIR/$role" ]; then
            log_error "Role not found: $role"
            exit 1
        fi
        
        test_role "$role"
        exit $?
    fi
}

# Show help
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [role_name|all|lint]"
    echo ""
    echo "Examples:"
    echo "  $0           # Test all roles"
    echo "  $0 all       # Test all roles"
    echo "  $0 lint      # Run lint checks only"
    echo "  $0 common    # Test common role only"
    echo "  $0 security  # Test security role only"
    echo "  $0 docker    # Test docker role only"
    echo "  $0 monitoring # Test monitoring role only"
    exit 0
fi

main "$@"
