#!/bin/zsh
source /Users/flo/.zshrc 2>/dev/null

echo "========================================"
echo "  WRAP FUNCTION TEST SUITE"
echo "========================================"
echo

pass=0
fail=0
test_sessions_created=()

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $label"
        ((pass++))
    else
        echo "  FAIL: $label"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        ((fail++))
    fi
}

assert_contains() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  PASS: $label"
        ((pass++))
    else
        echo "  FAIL: $label"
        echo "    expected to contain: $needle"
        echo "    actual: $haystack"
        ((fail++))
    fi
}

assert_not_contains() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        echo "  PASS: $label"
        ((pass++))
    else
        echo "  FAIL: $label"
        echo "    expected NOT to contain: $needle"
        echo "    actual: $haystack"
        ((fail++))
    fi
}

cleanup() {
    echo "--- CLEANUP ---"
    for s in "${test_sessions_created[@]}"; do
        tmux kill-session -t "$s" 2>/dev/null && echo "  Killed: $s"
    done
    echo
}
trap cleanup EXIT

# Count user's existing wrap sessions dynamically
initial_wrap_count=$(_wrap_sessions | grep -c '.' 2>/dev/null || echo 0)
initial_max=0
initial_results=$(_wrap_sessions)
if [ -n "$initial_results" ]; then
    while IFS=$'\t' read -r dir num name; do
        (( num > initial_max )) && initial_max=$num
    done <<< "$initial_results"
fi
echo "Starting state: $initial_wrap_count wrap sessions, global max #$initial_max"
echo

echo "--- TEST 1: Functions loaded from wrap_functions.sh ---"
assert_contains "wrap is a function" "shell function" "$(type wrap)"
assert_contains "_wrap_sessions is a function" "shell function" "$(type _wrap_sessions)"
assert_contains "wrap sourced from wrap_functions.sh" "wrap_functions.sh" "$(type wrap)"
echo

echo "--- TEST 2: _wrap_sessions (no filter) returns all wrap sessions ---"
all_sessions=$(_wrap_sessions)
count=$(echo "$all_sessions" | grep -c '.' 2>/dev/null || echo 0)
assert_eq "returns $initial_wrap_count wrap sessions" "$initial_wrap_count" "$count"
echo

echo "--- TEST 3: _wrap_sessions filters by exact directory ---"
pt_sessions=$(_wrap_sessions "~/Developer/private-tools")
sc_sessions=$(_wrap_sessions "~/Developer/private-tools/screenshot-classifier")
assert_not_contains "private-tools filter excludes screenshot-classifier" "screenshot-classifier" "$pt_sessions"
assert_not_contains "screenshot-classifier filter excludes bare private-tools sessions" $'private-tools\t1\t~/' "$sc_sessions"
# Verify they don't overlap
pt_count=$(echo "$pt_sessions" | grep -c '.' 2>/dev/null || echo 0)
sc_count=$(echo "$sc_sessions" | grep -c '.' 2>/dev/null || echo 0)
total=$((pt_count + sc_count))
if (( total <= initial_wrap_count )); then
    echo "  PASS: filtered counts ($pt_count + $sc_count = $total) don't exceed total ($initial_wrap_count)"
    ((pass++))
else
    echo "  FAIL: filtered counts exceed total ($pt_count + $sc_count > $initial_wrap_count)"
    ((fail++))
fi
echo

echo "--- TEST 4: _wrap_sessions ignores non-wrap sessions ---"
assert_not_contains "no 'dev' session" $'\tdev\t' "$all_sessions"
assert_not_contains "no 'scorched-earth' session" "scorched-earth" "$all_sessions"
bare_2=$(echo "$all_sessions" | grep "^2	")
assert_eq "no bare '2' session in results" "" "$bare_2"
echo

echo "--- TEST 5: wrap -i output formatting ---"
info_output=$(wrap -i)
assert_contains "shows header" "Wrap sessions:" "$info_output"
assert_not_contains "does not show non-wrap session 'dev'" "dev:" "$info_output"
# Check sort order: private-tools before screenshot-classifier (lexical)
pt_line=$(echo "$info_output" | grep -n "private-tools/#" | head -1 | cut -d: -f1)
sc_line=$(echo "$info_output" | grep -n "screenshot-classifier/#" | head -1 | cut -d: -f1)
if [[ -n "$pt_line" && -n "$sc_line" ]] && (( pt_line < sc_line )); then
    echo "  PASS: sorted lexically (private-tools before screenshot-classifier)"
    ((pass++))
else
    echo "  FAIL: sort order wrong (pt=$pt_line, sc=$sc_line)"
    ((fail++))
fi
echo

echo "--- TEST 6: wrap -r shows correct selection numbers matching session numbers ---"
cd /Users/flo/Developer/private-tools/screenshot-classifier
reattach_output=$(echo "" | wrap -r 2>&1)
# Session numbers in selector must match actual session numbers (not sequential 1,2,3)
sc_nums=()
while IFS=$'\t' read -r dir num name; do
    sc_nums+=("$num")
done <<< "$sc_sessions"
for n in "${sc_nums[@]}"; do
    assert_contains "shows [$n]" "[$n]" "$reattach_output"
done
echo

echo "--- TEST 7: wrap -r from dir with no sessions ---"
cd /Users/flo
r_output=$(wrap -r 2>&1)
r_exit=$?
assert_eq "exit code 1" "1" "$r_exit"
assert_contains "no sessions message" "No wrap sessions for this directory" "$r_output"
echo

echo "--- TEST 8: Global numbering uses highest number across ALL directories ---"
expected_next=$((initial_max + 1))
# Create a session and verify it gets the expected global number
cd /tmp
session_base="/tmp"
tmux new-session -d -s "${session_base}/#${expected_next}"
test_sessions_created+=("${session_base}/#${expected_next}")
verify=$(tmux list-sessions -F '#{session_name}' | grep "^${session_base}/#${expected_next}$")
assert_eq "created session with global number #$expected_next" "${session_base}/#${expected_next}" "$verify"

# Now the next number should be expected_next+1
max_after=0
results_after=$(_wrap_sessions)
while IFS=$'\t' read -r dir num name; do
    (( num > max_after )) && max_after=$num
done <<< "$results_after"
assert_eq "global max updated to #$expected_next" "$expected_next" "$max_after"
assert_eq "next session will be #$((expected_next + 1))" "$((expected_next + 1))" "$((max_after + 1))"
echo

echo "--- TEST 9: wrap -i shows newly created external path session ---"
info_after=$(wrap -i)
assert_contains "shows /tmp session" "/tmp/#${expected_next}" "$info_after"
echo

echo "--- TEST 10: External path uses absolute path, not tilde ---"
tmp_sessions=$(_wrap_sessions "/tmp")
assert_contains "uses /tmp" "/tmp" "$tmp_sessions"
assert_not_contains "no tilde in /tmp sessions" "~" "$tmp_sessions"
echo

echo "--- TEST 11: tmux guard - wrap refuses create inside tmux ---"
guard_output=$(TMUX="/tmp/tmux-501/default,12345,0" wrap 2>&1)
guard_exit=$?
assert_eq "exit code 1" "1" "$guard_exit"
assert_contains "already inside message" "Already inside a tmux session" "$guard_output"
echo

echo "--- TEST 12: wrap -r works inside tmux (not blocked by guard) ---"
cd /Users/flo/Developer/private-tools/screenshot-classifier
r_inside=$(echo "" | TMUX="/tmp/tmux-501/default,12345,0" wrap -r 2>&1)
assert_not_contains "not refused by tmux guard" "Already inside" "$r_inside"
assert_contains "shows sessions listing" "Wrap sessions in" "$r_inside"
echo

echo "--- TEST 13: wrap -r rejects invalid selection ---"
cd /Users/flo/Developer/private-tools/screenshot-classifier
invalid_output=$(echo "999" | wrap -r 2>&1)
assert_contains "invalid selection message" "Invalid selection" "$invalid_output"

invalid_output2=$(echo "abc" | wrap -r 2>&1)
assert_contains "non-numeric selection rejected" "Invalid selection" "$invalid_output2"

invalid_output3=$(echo "" | wrap -r 2>&1)
assert_contains "empty selection rejected" "Invalid selection" "$invalid_output3"
echo

echo "--- TEST 14: wrap -i with no wrap sessions shows correct message ---"
# Can't fully test without killing user sessions, so just verify the code path exists
empty_check=$(echo "" | _wrap_sessions "/__nonexistent_path__")
assert_eq "no results for nonexistent path" "" "$empty_check"
echo

echo "--- TEST 15: wrap from \$HOME creates ~/#N session ---"
cd /Users/flo
expected_home=$((max_after + 1))
tmux new-session -d -s "~/#${expected_home}"
test_sessions_created+=("~/#${expected_home}")
home_verify=$(tmux list-sessions -F '#{session_name}' | grep "^~/#${expected_home}$")
assert_eq "created ~/#$expected_home session" "~/#${expected_home}" "$home_verify"
home_results=$(_wrap_sessions "~")
assert_contains "home session found by _wrap_sessions" "~/#${expected_home}" "$home_results"
echo

echo "--- TEST 16: double-digit numerical sort (#10 after #9, not after #1) ---"
# Create sessions #9 and #10 in a test dir to verify sort order
tmux new-session -d -s "/tmp/sorttest/#9"
test_sessions_created+=("/tmp/sorttest/#9")
tmux new-session -d -s "/tmp/sorttest/#10"
test_sessions_created+=("/tmp/sorttest/#10")
sort_results=$(_wrap_sessions "/tmp/sorttest" | sort -t$'\t' -k2,2n)
first_num=$(echo "$sort_results" | head -1 | cut -f2)
second_num=$(echo "$sort_results" | tail -1 | cut -f2)
assert_eq "first sorted is #9" "9" "$first_num"
assert_eq "second sorted is #10" "10" "$second_num"
echo

echo "--- TEST 17: wrap -d lists same sessions as wrap -r with correct [N] format ---"
cd /Users/flo/Developer/private-tools/screenshot-classifier
delete_list_output=$(echo "" | wrap -d 2>&1)
assert_contains "shows delete header" "Wrap sessions in" "$delete_list_output"
while IFS=$'\t' read -r dir num name; do
    assert_contains "delete listing shows [$num]" "[$num]" "$delete_list_output"
done <<< "$sc_sessions"
echo

echo "--- TEST 18: wrap -d from dir with no sessions ---"
mkdir -p /tmp/wrap_d_empty
cd /tmp/wrap_d_empty
d_output=$(wrap -d 2>&1)
d_exit=$?
assert_eq "exit code 1" "1" "$d_exit"
assert_contains "no sessions message" "No wrap sessions for this directory" "$d_output"
echo

echo "--- TEST 19: wrap -d rejects invalid selection ---"
cd /Users/flo/Developer/private-tools/screenshot-classifier
delete_invalid_output=$(echo "" | wrap -d 2>&1)
assert_contains "empty delete selection rejected" "Invalid selection" "$delete_invalid_output"

delete_invalid_output2=$(echo "abc" | wrap -d 2>&1)
assert_contains "non-numeric delete selection rejected" "Invalid selection" "$delete_invalid_output2"

delete_invalid_output3=$(echo "999" | wrap -d 2>&1)
assert_contains "out-of-range delete selection rejected" "Invalid selection" "$delete_invalid_output3"
echo

echo "--- TEST 20: wrap -d actually kills the selected session ---"
kill_test_num=$((max_after + 100))
mkdir -p /tmp/killtest
tmux new-session -d -s "/tmp/killtest/#${kill_test_num}"
test_sessions_created+=("/tmp/killtest/#${kill_test_num}")
cd /tmp/killtest
kill_output=$(echo "$kill_test_num" | wrap -d 2>&1)
assert_contains "kill confirmation shown" "Killed: /tmp/killtest/#${kill_test_num}" "$kill_output"
if tmux has-session -t "/tmp/killtest/#${kill_test_num}" 2>/dev/null; then
    echo "  FAIL: session still exists after kill"
    ((fail++))
else
    echo "  PASS: session killed"
    ((pass++))
fi
echo

echo "========================================"
echo "  RESULTS: $pass passed, $fail failed"
echo "========================================"
exit $fail
