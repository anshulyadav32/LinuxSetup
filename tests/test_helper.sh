#!/bin/bash
# =============================================================================
# Test Helper Functions
# =============================================================================

source ../src/utils/utils.sh

# Test environment setup
setup_test_env() {
    log_header "Setting up test environment"
    export TEST_MODE=true
    export TEST_DIR=$(mktemp -d)
    export BACKUP_DIR="$TEST_DIR/backup"
    export CONFIG_DIR="$TEST_DIR/config"
    mkdir -p "$BACKUP_DIR" "$CONFIG_DIR"
}

# Test environment cleanup
cleanup_test_env() {
    log_header "Cleaning up test environment"
    rm -rf "$TEST_DIR"
    unset TEST_MODE TEST_DIR BACKUP_DIR CONFIG_DIR
}

# Test assertion functions
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [ "$expected" = "$actual" ]; then
        log_success "✓ $message"
        return 0
    else
        log_error "✗ $message (Expected: $expected, Got: $actual)"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"
    
    if [ -f "$file" ]; then
        log_success "✓ $message"
        return 0
    else
        log_error "✗ $message (File not found: $file)"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="$2"
    
    if [ -d "$dir" ]; then
        log_success "✓ $message"
        return 0
    else
        log_error "✗ $message (Directory not found: $dir)"
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    local message="$2"
    
    if command_exists "$cmd"; then
        log_success "✓ $message"
        return 0
    else
        log_error "✗ $message (Command not found: $cmd)"
        return 1
    fi
}

assert_service_running() {
    local service="$1"
    local message="$2"
    
    if systemctl is-active --quiet "$service"; then
        log_success "✓ $message"
        return 0
    else
        log_error "✗ $message (Service not running: $service)"
        return 1
    fi
}

# Run all tests in a directory
run_test_suite() {
    local test_dir="$1"
    local total=0
    local passed=0
    local failed=0
    
    log_header "Running test suite: $test_dir"
    
    for test_file in "$test_dir"/*_test.sh; do
        if [ -f "$test_file" ]; then
            total=$((total + 1))
            if bash "$test_file"; then
                passed=$((passed + 1))
            else
                failed=$((failed + 1))
            fi
        fi
    done
    
    log_header "Test Results"
    log_info "Total: $total"
    log_success "Passed: $passed"
    [ $failed -gt 0 ] && log_error "Failed: $failed" || log_info "Failed: $failed"
    
    return $failed
}

# Export functions
export -f setup_test_env
export -f cleanup_test_env
export -f assert_equals
export -f assert_file_exists
export -f assert_dir_exists
export -f assert_command_exists
export -f assert_service_running
export -f run_test_suite
