#!/usr/bin/env bash
#
# CSCE 465/765 - HW3 Task 3
# Test suite for legacy_log_parser_fixed
#
# Covers the five required cases:
#   1. valid short input
#   2. exactly maximum allowed input (BUF_SIZE = 128 bytes)
#   3. one byte over the limit (129 bytes)
#   4. missing file
#   5. original exploit payload (from Task 1)
#
# Usage:
#   ./run_tests.sh [path-to-legacy_log_parser_fixed] [path-to-original-payload.bin]
#
# Defaults to ./legacy_log_parser_fixed and ./payload.bin if not given.

set -u

BIN="${1:-./legacy_log_parser_fixed}"
ORIG_PAYLOAD="${2:-./payload.bin}"
BUF_SIZE=128

WORKDIR="$(mktemp -d)"
PASS=0
FAIL=0

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

if [[ ! -x "$BIN" ]]; then
    echo "ERROR: '$BIN' not found or not executable."
    echo "Build it first with:"
    echo "  gcc -O2 -g -fstack-protector-strong -D_FORTIFY_SOURCE=3 \\"
    echo "      -fPIE -pie -Wl,-z,relro,-z,now -Wl,-z,noexecstack \\"
    echo "      -Wall -Wextra -Werror \\"
    echo "      -o legacy_log_parser_fixed legacy_log_parser_fixed.c"
    exit 1
fi

# -----------------------------------------------------------------------
# helper: run $BIN on a file, report exit code + whether it crashed
# -----------------------------------------------------------------------
run_case() {
    local name="$1"
    local file="$2"
    local expect="$3"   # "success" | "rejected" | "error" (expected, non-crash)

    echo "=============================================="
    echo "TEST: $name"
    echo "File: $file"
    [[ -f "$file" ]] && echo "Size: $(wc -c < "$file") bytes"
    echo "----------------------------------------------"

    local out
    out="$("$BIN" "$file" 2>&1)"
    local code=$?

    echo "$out"
    echo "----------------------------------------------"
    echo "Exit code: $code"

    # A crash (SIGSEGV=139, SIGABRT=134, or any signal: 128+N) means
    # the fix failed, regardless of which test case this is.
    if [[ $code -ge 128 ]]; then
        echo "RESULT: FAIL (program crashed / caught signal $((code - 128)))"
        FAIL=$((FAIL + 1))
        echo ""
        return
    fi

    case "$expect" in
        success)
            if [[ $code -eq 0 ]] && echo "$out" | grep -q "Log preamble:"; then
                echo "RESULT: PASS (parsed and printed preamble as expected)"
                PASS=$((PASS + 1))
            else
                echo "RESULT: FAIL (expected successful parse, did not see it)"
                FAIL=$((FAIL + 1))
            fi
            ;;
        rejected)
            if echo "$out" | grep -q "exceeds destination buffer size"; then
                echo "RESULT: PASS (oversized input correctly rejected, no crash)"
                PASS=$((PASS + 1))
            else
                echo "RESULT: FAIL (expected rejection message, did not see it)"
                FAIL=$((FAIL + 1))
            fi
            ;;
        error)
            if [[ $code -ne 0 ]]; then
                echo "RESULT: PASS (non-zero exit as expected, no crash)"
                PASS=$((PASS + 1))
            else
                echo "RESULT: FAIL (expected non-zero exit)"
                FAIL=$((FAIL + 1))
            fi
            ;;
    esac
    echo ""
}

# -----------------------------------------------------------------------
# Test 1: valid short input
# -----------------------------------------------------------------------
echo "This is a short, well-formed log line." > "$WORKDIR/short.log"
run_case "1. Valid short input" "$WORKDIR/short.log" "success"

# -----------------------------------------------------------------------
# Test 2: exactly maximum allowed input (BUF_SIZE bytes, no trailing newline
# so the byte count is exact)
# -----------------------------------------------------------------------
python3 -c "import sys; sys.stdout.buffer.write(b'B' * $BUF_SIZE)" > "$WORKDIR/exact_max.log"
run_case "2. Exactly maximum allowed input ($BUF_SIZE bytes)" "$WORKDIR/exact_max.log" "success"

# -----------------------------------------------------------------------
# Test 3: one byte over the limit (BUF_SIZE + 1 bytes)
# -----------------------------------------------------------------------
python3 -c "import sys; sys.stdout.buffer.write(b'C' * ($BUF_SIZE + 1))" > "$WORKDIR/over_limit.log"
run_case "3. One byte over the limit ($((BUF_SIZE + 1)) bytes)" "$WORKDIR/over_limit.log" "rejected"

# -----------------------------------------------------------------------
# Test 4: missing file
# -----------------------------------------------------------------------
run_case "4. Missing file" "$WORKDIR/this_file_does_not_exist.log" "error"

# -----------------------------------------------------------------------
# Test 5: original exploit payload from Task 1
# -----------------------------------------------------------------------
if [[ -f "$ORIG_PAYLOAD" ]]; then
    run_case "5. Original exploit payload (from Task 1)" "$ORIG_PAYLOAD" "rejected"
else
    echo "=============================================="
    echo "TEST: 5. Original exploit payload (from Task 1)"
    echo "SKIPPED: '$ORIG_PAYLOAD' not found."
    echo "Pass its path as the 2nd argument, e.g.:"
    echo "  ./run_tests.sh ./legacy_log_parser_fixed ../src/payload.bin"
    echo ""
fi

# -----------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------
echo "=============================================="
echo "SUMMARY: $PASS passed, $FAIL failed"
echo "=============================================="

[[ $FAIL -eq 0 ]]
