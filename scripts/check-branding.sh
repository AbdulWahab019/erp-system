#!/bin/bash
# Fail if any user-facing file contains forbidden branding strings.
# Run in CI after every merge from upstream.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

FORBIDDEN_PATTERNS=(
    "Frappe Technologies"
    "frappe.io/erpnext"
    "docs.erpnext.com"
    "erpnext.com/docs"
    "discuss.frappe.io"
    "frappe.io/school"
    "Frappe School"
    "Frappe CRM"
    "Frappe Helpdesk"
)

FOUND=0

echo "=== Branding Leak Check ==="
echo ""

# Check user-facing file types (HTML, JS, CSS, Python)
for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    results=$(grep -rn "$pattern" "$REPO_ROOT/erpnext/" \
        --include='*.html' --include='*.js' --include='*.css' --include='*.py' \
        --exclude-dir='node_modules' --exclude-dir='.git' --exclude-dir='__pycache__' \
        --exclude='check-branding.sh' \
        --exclude='update_docs_link.py' \
        | grep -v '# Copyright' \
        | grep -v '// Copyright' \
        | grep -v 'test_' \
        || true)
    if [ -n "$results" ]; then
        echo "FOUND: '$pattern'"
        echo "$results"
        echo ""
        FOUND=1
    fi
done

# Check JSON labels, titles, and documentation URLs
for pattern in "ERPNext" "erpnext.com" "frappe.io"; do
    results=$(grep -rn "\"label\".*$pattern\|\"title\".*$pattern\|\"documentation_url\".*$pattern" "$REPO_ROOT/erpnext/" \
        --include='*.json' \
        --exclude-dir='__pycache__' \
        || true)
    if [ -n "$results" ]; then
        echo "FOUND in JSON: '$pattern'"
        echo "$results"
        echo ""
        FOUND=1
    fi
done

echo ""
if [ $FOUND -eq 1 ]; then
    echo "FAIL: Forbidden branding strings found. Fix before deploying."
    exit 1
else
    echo "PASS: No forbidden branding strings found."
    exit 0
fi
