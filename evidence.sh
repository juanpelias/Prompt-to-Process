#!/usr/bin/env bash
#
# CSCE 465/765 - HW3 Task 4
# Re-runs the full confinement demonstration in one consistent session
# so you can screenshot each labeled section for the report.
#
# Run from ~/csce465-agentsec/hw3
#
# Usage:
#   ./capture_task4_evidence.sh
#
# Adjust the paths below if your layout differs.

set -u

HW3_DIR="$HOME/csce465-agentsec/hw3"
PARSER="$HW3_DIR/legacy_log_parser"
PAYLOAD="$HW3_DIR/payload.bin"
PROFILE_SRC="$HW3_DIR/policy/apparmor.profile"
PROFILE_DST="/etc/apparmor.d/legacy_log_parser"
DECOY="/opt/agentsec/decoy.txt"

banner() {
    echo ""
    echo "=============================================================="
    echo "  $1"
    echo "=============================================================="
}

cd "$HW3_DIR" || { echo "ERROR: cannot cd to $HW3_DIR"; exit 1; }

# -----------------------------------------------------------------------
banner "[1/6] Final AppArmor profile contents"
# -----------------------------------------------------------------------
if [[ -f "$PROFILE_SRC" ]]; then
    cat "$PROFILE_SRC"
else
    echo "ERROR: $PROFILE_SRC not found."
fi

# -----------------------------------------------------------------------
banner "[2/6] Load the profile and confirm it is active"
# -----------------------------------------------------------------------
sudo cp "$PROFILE_SRC" "$PROFILE_DST"
sudo apparmor_parser -r "$PROFILE_DST"
echo ""
echo "--- aa-status (filtered) ---"
sudo aa-status | grep -A1 legacy_log_parser

# -----------------------------------------------------------------------
banner "[3/6] Reset markers/, run exploit as agentlab, confirm clean run"
# -----------------------------------------------------------------------
rm -f "$HW3_DIR/markers/ret2win.txt"
echo "--- program output ---"
sudo -u agentlab "$PARSER" "$PAYLOAD"
echo ""
echo "--- marker file contents ---"
cat "$HW3_DIR/markers/ret2win.txt" 2>&1

# -----------------------------------------------------------------------
banner "[4/6] Control test: loosen DAC on the decoy file, run exploit again"
# -----------------------------------------------------------------------
echo "Decoy permissions before:"
ls -l "$DECOY"
sudo chmod 644 "$DECOY"
echo "Decoy permissions after chmod 644 (DAC alone would now permit a read):"
ls -l "$DECOY"
echo ""
echo "--- program output (should still fail to read the decoy) ---"
sudo -u agentlab "$PARSER" "$PAYLOAD"

# -----------------------------------------------------------------------
banner "[5/6] Kernel log: confirm AppArmor (not DAC) produced the denial"
# -----------------------------------------------------------------------
sudo journalctl -k --no-pager | grep -i apparmor | tail -n 10

# -----------------------------------------------------------------------
banner "[6/6] Restore decoy file permissions"
# -----------------------------------------------------------------------
sudo chmod 600 "$DECOY"
ls -l "$DECOY"

