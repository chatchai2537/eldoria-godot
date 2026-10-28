#!/usr/bin/env bash
# รันเทสทุกชุด · ใช้: bash source/tools/run_tests.sh [path/to/godot]
# ผ่านหมด = บรรทัดสุดท้าย "ALL TESTS PASS" · ต้องผ่านก่อน push ทุกครั้ง
set -u
cd "$(dirname "$0")/.."
G="${1:-${GODOT:-godot}}"
RUN=("$G" --path . --resolution 860x400)
if command -v xvfb-run >/dev/null 2>&1; then RUN=(xvfb-run -a -s "-screen 0 1280x720x24" "${RUN[@]}"); else RUN=("$G" --headless --path . --resolution 860x400); fi
"$G" --headless --path . --import >/dev/null 2>&1
fail=0
run() {  # $1=ชื่อ $2..=อาร์กิวเมนต์
  local name="$1"; shift
  local log="/tmp/eldoria_test_${name}.log"
  timeout 600 "${RUN[@]}" "$@" > "$log" 2>&1
  local rc=$?
  local bad
  bad=$(grep -E "FAIL:|SCRIPT ERROR|Parse Error" "$log" | head -5)
  if [ $rc -ne 0 ] || [ -n "$bad" ]; then echo "❌ $name (rc=$rc)"; echo "$bad"; fail=1; else echo "✅ $name: $(grep -E 'failures=' "$log" | tail -1)"; fi
}
run startup  --script res://tests/startup_smoke.gd -- --mobile
run recovery --script res://tests/startup_smoke.gd -- --mobile --recovery-test
run combat   --script res://tests/combat_smoke.gd -- --mobile
run visual   --script res://tests/visual_smoke.gd -- --mobile
run all      --script res://tests/all_systems.gd -- --mobile
if [ $fail -eq 0 ]; then echo "ALL TESTS PASS"; else echo "TESTS FAILED — ห้าม push"; exit 1; fi
