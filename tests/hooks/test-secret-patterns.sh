#!/bin/bash
# Tests for secret-scan.sh pattern detection
# Validates true positives (must detect) and false positives (must not detect)
#
# Note: Some test tokens are constructed at runtime via string concatenation
# to avoid triggering GitHub Push Protection on this test file.

FIXTURES="tests/fixtures"

# --- True Positive Tests ---

assert_grep_match "TP: AWS Access Key ID" 'AKIA[0-9A-Z]{16}' "AKIAIOSFODNN7EXAMPLE"
assert_grep_match "TP: Anthropic API Key" 'sk-ant-[A-Za-z0-9-]{90,}' "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
assert_grep_match "TP: GitHub PAT" 'ghp_[A-Za-z0-9]{36}' "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij"
assert_grep_match "TP: GitHub OAuth Token" 'gho_[A-Za-z0-9]{36}' "gho_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij"
assert_grep_match "TP: Google API Key" 'AIza[A-Za-z0-9_-]{35}' "AIzaSyABCDEFGHIJKLMNOPQRSTUVWXYZ1234567"
assert_grep_match "TP: Azure Connection String" 'DefaultEndpointsProtocol=https;Account' "DefaultEndpointsProtocol=https;AccountName=myaccount"
assert_grep_match "TP: Password assignment" 'password\s*[:=]\s*["\x27][^"\x27]{8,}' 'password = "mysecretpassword123"'
assert_grep_match "TP: API key assignment" 'api[_-]?key\s*[:=]\s*["\x27][^"\x27]{8,}' 'api_key = "sk_abcdefghijklmnop"'

# Runtime-constructed tokens (avoid GitHub Push Protection)
# Slack Bot Token
SLACK_PREFIX="xoxb-"
SLACK_BODY="123456789012-1234567890123-abcdef"
assert_grep_match "TP: Slack Bot Token" 'xoxb-[0-9]+-[A-Za-z0-9]+' "${SLACK_PREFIX}${SLACK_BODY}"

# Slack User Token
SLACK_USER_PREFIX="xoxp-"
assert_grep_match "TP: Slack User Token" 'xoxp-[0-9]+-[A-Za-z0-9]+' "${SLACK_USER_PREFIX}${SLACK_BODY}"

# Stripe Secret Key
STRIPE_PREFIX="sk_live_"
STRIPE_BODY="ABCDEFGHIJKLMNOPQRSTUVWX"
assert_grep_match "TP: Stripe Secret Key" 'sk_live_[A-Za-z0-9]{24,}' "${STRIPE_PREFIX}${STRIPE_BODY}"

# Stripe Restricted Key
STRIPE_RK_PREFIX="rk_live_"
assert_grep_match "TP: Stripe Restricted Key" 'rk_live_[A-Za-z0-9]{24,}' "${STRIPE_RK_PREFIX}${STRIPE_BODY}"

# --- False Positive Tests ---

assert_grep_no_match "FP: Normal base64 not AWS key" 'AKIA[0-9A-Z]{16}' "dGhpcyBpcyBhIHRlc3QgYmFzZTY0IHN0cmluZw=="
assert_grep_no_match "FP: SHA256 hash not a secret" 'AKIA[0-9A-Z]{16}' "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
assert_grep_no_match "FP: Git commit hash not a token" 'ghp_[A-Za-z0-9]{36}' "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
assert_grep_no_match "FP: URL path not a secret" 'sk_live_[A-Za-z0-9]{24,}' "https://api.example.com/v1/users/profile"
assert_grep_no_match "FP: Empty password not detected" 'password\s*[:=]\s*["\x27][^"\x27]{8,}' 'password = ""'
assert_grep_no_match "FP: Short API key not detected" 'api[_-]?key\s*[:=]\s*["\x27][^"\x27]{8,}' 'api_key = "short"'
assert_grep_no_match "FP: Version string not a secret" 'sk-ant-[A-Za-z0-9-]{90,}' "VERSION=1.0.0-alpha.1+build.123"
assert_grep_no_match "FP: PEM header not a secret" 'AKIA[0-9A-Z]{16}' "-----BEGIN CERTIFICATE-----"

# --- Bulk scan: true positive fixture file ---

TP_FILE="$FIXTURES/secret-samples.txt"
if [ -f "$TP_FILE" ]; then
    PATTERNS=(
        'AKIA[0-9A-Z]{16}'
        'sk-ant-[A-Za-z0-9-]{90,}'
        'ghp_[A-Za-z0-9]{36}'
        'gho_[A-Za-z0-9]{36}'
        'AIza[A-Za-z0-9_-]{35}'
        'DefaultEndpointsProtocol=https;Account'
        'password\s*[:=]\s*["\x27][^"\x27]{8,}'
        'api[_-]?key\s*[:=]\s*["\x27][^"\x27]{8,}'
    )
    TP_DETECTED=0
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [ -z "$line" ] && continue
        for pattern in "${PATTERNS[@]}"; do
            if echo "$line" | grep -qP "$pattern" 2>/dev/null; then
                TP_DETECTED=$((TP_DETECTED + 1))
                break
            fi
        done
    done < "$TP_FILE"

    if [ "$TP_DETECTED" -ge 7 ]; then
        pass "Bulk TP: detected $TP_DETECTED secrets in fixture file (threshold: >=7)"
    else
        fail "Bulk TP: detected $TP_DETECTED secrets in fixture file" "expected at least 7"
    fi
else
    skip "Bulk TP test" "fixtures file not found"
fi

# --- Bulk scan: false positive fixture file ---

FP_FILE="$FIXTURES/false-positives.txt"
if [ -f "$FP_FILE" ]; then
    FP_DETECTED=0
    FP_TOTAL=0
    while IFS= read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        [ -z "$line" ] && continue
        FP_TOTAL=$((FP_TOTAL + 1))
        for pattern in "${PATTERNS[@]}"; do
            if echo "$line" | grep -qP "$pattern" 2>/dev/null; then
                FP_DETECTED=$((FP_DETECTED + 1))
                break
            fi
        done
    done < "$FP_FILE"

    if [ "$FP_DETECTED" -le 1 ]; then
        pass "Bulk FP: $FP_DETECTED/$FP_TOTAL false positives (threshold: <=1)"
    else
        fail "Bulk FP: $FP_DETECTED/$FP_TOTAL false positives" "expected at most 1"
    fi
else
    skip "Bulk FP test" "fixtures file not found"
fi
