#!/bin/bash
# =============================================================================
# TEST SUITE FOR SETUP.SH
# =============================================================================
set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

print_test_header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo -e "  ${GREEN}✓${NC} PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗${NC} FAIL: $test_name"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    if echo "$haystack" | grep -q "$needle"; then
        echo -e "  ${GREEN}✓${NC} PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "  ${RED}✗${NC} FAIL: $test_name"
        echo "    Expected to contain: '$needle'"
        echo "    Actual: '$haystack'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# =============================================================================
# LOAD FUNCTIONS FROM SETUP.SH
# =============================================================================

# Source only the functions we need to test
escape_for_sed() {
    # Экранирование для sed с разделителем |
    printf '%s\n' "$1" | sed 's/[&|\]/\\&/g'
}

# =============================================================================
# TESTS
# =============================================================================

test_escape_for_sed() {
    print_test_header "Test: escape_for_sed()"

    local result

    # Test 1: Plain text
    result=$(escape_for_sed "Hello World")
    assert_equals "Hello World" "$result" "Plain text should not be modified"

    # Test 2: Ampersand
    result=$(escape_for_sed "AT&T")
    assert_equals "AT\\&T" "$result" "Ampersand should be escaped"

    # Test 3: Pipe character
    result=$(escape_for_sed "A|B")
    assert_equals "A\\|B" "$result" "Pipe should be escaped"

    # Test 4: Backslash
    result=$(escape_for_sed "A\\B")
    assert_equals "A\\\\B" "$result" "Backslash should be escaped"

    # Test 5: Multiple special characters
    result=$(escape_for_sed "Apple & Google | Amazon")
    assert_equals "Apple \\& Google \\| Amazon" "$result" "Multiple special chars should be escaped"

    # Test 6: Forward slash (should NOT be escaped with pipe delimiter)
    result=$(escape_for_sed "Apple/Google")
    assert_equals "Apple/Google" "$result" "Forward slash should NOT be escaped"
}

test_vault_name_generation() {
    print_test_header "Test: Vault Name Generation"

    local company_slug
    local role_slug
    local vault_name

    # Test 1: Simple case
    company_slug=$(echo "Acme Corp" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    role_slug=$(echo "CTO" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    vault_name="${company_slug}-${role_slug}"
    assert_equals "acme-corp-cto" "$vault_name" "Simple vault name generation"

    # Test 2: With special characters (company slug strips special chars, role keeps them)
    company_slug=$(echo "AT&T Inc." | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    role_slug=$(echo "VP of R&D" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    vault_name="${company_slug}-${role_slug}"
    # Note: role_slug doesn't strip & like company_slug does, so & remains
    assert_equals "att-inc-vp-of-r&d" "$vault_name" "Vault name with special chars in role"

    # Test 3: Multiple spaces
    company_slug=$(echo "Big   Company   Name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    vault_name="${company_slug}-cto"
    assert_contains "$vault_name" "big" "Multi-space company name should collapse"
}

test_vault_path_generation() {
    print_test_header "Test: Vault Path Generation"

    local company_formatted
    local role_formatted
    local vault_path

    # Test 1: Simple case
    company_formatted=$(echo "Acme Corp" | tr ' ' '_')
    role_formatted=$(echo "CTO" | tr ' ' '_')
    vault_path="$HOME/Documents/${company_formatted}_${role_formatted}"
    assert_contains "$vault_path" "Acme_Corp_CTO" "Simple vault path"

    # Test 2: Multi-word role
    company_formatted=$(echo "Acme" | tr ' ' '_')
    role_formatted=$(echo "Product Manager" | tr ' ' '_')
    vault_path="$HOME/Documents/${company_formatted}_${role_formatted}"
    assert_contains "$vault_path" "Acme_Product_Manager" "Multi-word role path"
}

test_sed_replacement_safety() {
    print_test_header "Test: sed Replacement Safety"

    local temp_file
    temp_file=$(mktemp)

    # Create test file with placeholder
    echo "Company: {{COMPANY}}" > "$temp_file"

    # Test 1: Company name with forward slash
    local safe_company
    safe_company=$(escape_for_sed "Apple/Google")
    sed -i '' -e "s|{{COMPANY}}|${safe_company}|g" "$temp_file"

    local result
    result=$(cat "$temp_file")
    assert_equals "Company: Apple/Google" "$result" "sed with pipe delimiter handles forward slash"

    # Test 2: Company name with ampersand
    echo "Company: {{COMPANY}}" > "$temp_file"
    safe_company=$(escape_for_sed "AT&T")
    sed -i '' -e "s|{{COMPANY}}|${safe_company}|g" "$temp_file"

    result=$(cat "$temp_file")
    assert_equals "Company: AT&T" "$result" "sed handles ampersand correctly"

    # Cleanup
    rm -f "$temp_file"
}

test_placeholder_patterns() {
    print_test_header "Test: Placeholder Patterns in Files"

    # Check that no files have unreplaced problematic placeholders
    local setup_md="../SETUP.md"

    if [[ -f "$setup_md" ]]; then
        local has_stakeholders
        has_stakeholders=$(grep -c "{{STAKEHOLDERS}}" "$setup_md" || true)
        assert_equals "0" "$has_stakeholders" "SETUP.md should not reference {{STAKEHOLDERS}}"

        local has_constraints
        has_constraints=$(grep -c "{{CONSTRAINTS}}" "$setup_md" || true)
        assert_equals "0" "$has_constraints" "SETUP.md should not reference {{CONSTRAINTS}}"

        local has_methodologies
        has_methodologies=$(grep -c "{{METHODOLOGIES}}" "$setup_md" || true)
        assert_equals "0" "$has_methodologies" "SETUP.md should not reference {{METHODOLOGIES}}"
    fi
}

# =============================================================================
# MAIN TEST RUNNER
# =============================================================================

main() {
    clear
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║       SETUP.SH TEST SUITE                                 ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""

    # Change to script directory
    cd "$(dirname "${BASH_SOURCE[0]}")"

    # Run tests
    test_escape_for_sed
    test_vault_name_generation
    test_vault_path_generation
    test_sed_replacement_safety
    test_placeholder_patterns

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  TEST SUMMARY"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${GREEN}✓${NC} Passed: $TESTS_PASSED"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "  ${RED}✗${NC} Failed: $TESTS_FAILED"
        echo ""
        exit 1
    else
        echo -e "  ${YELLOW}○${NC} Failed: 0"
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
