#!/usr/bin/env bash
# Self-check for hooks/tdd-guard.sh. Run: just test-claude
set -u
hook="$(cd "$(dirname "$0")/../hooks" && pwd)/tdd-guard.sh"
repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
git -C "$repo" init -q
mkdir -p "$repo/pkg"
mark="$(git -C "$repo" rev-parse --absolute-git-dir)/tdd-phase"
fail=0

# expect <deny|allow> <path> <label>
expect() {
	out=$(jq -nc --arg p "$2" '{tool_name:"Edit",tool_input:{file_path:$p}}' | bash "$hook")
	got=allow
	printf '%s' "$out" | grep -q '"permissionDecision":"deny"' && got=deny
	if [ "$got" != "$1" ]; then
		echo "FAIL $3: want $1, got $got"
		fail=1
	fi
}

# expect_bash <deny|allow> <command> <label>: runs with cwd at the repo root
expect_bash() {
	out=$(jq -nc --arg c "$2" --arg d "$repo" '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}' | bash "$hook")
	got=allow
	printf '%s' "$out" | grep -q '"permissionDecision":"deny"' && got=deny
	if [ "$got" != "$1" ]; then
		echo "FAIL $3: want $1, got $got"
		fail=1
	fi
}

# expect_json <deny|allow> <tool json> <label>
expect_json() {
	out=$(printf '%s' "$2" | bash "$hook")
	got=allow
	printf '%s' "$out" | grep -q '"permissionDecision":"deny"' && got=deny
	if [ "$got" != "$1" ]; then
		echo "FAIL $3: want $1, got $got"
		fail=1
	fi
}

# edit <path> <old> <new> [replace_all]: an Edit payload
edit() {
	jq -nc --arg p "$1" --arg o "$2" --arg n "$3" --argjson a "${4:-false}" \
		'{tool_name:"Edit",tool_input:{file_path:$p,old_string:$o,new_string:$n,replace_all:$a}}'
}

expect allow "$repo/pkg/a_test.go" "no marker"
expect_bash allow "rm pkg/a_test.go" "bash no marker"

printf 'green\npkg/a_test.go\n' >"$mark"
expect deny "$repo/pkg/a_test.go" "green frozen file"
expect allow "$repo/pkg/b_test.go" "green unfrozen test"
expect allow "$repo/pkg/a.go" "green source"
expect allow "$repo/new/dir/c_test.go" "green new dir"
expect_bash deny "rm pkg/a_test.go" "bash rm frozen"
expect_bash deny "git rm -q pkg/a_test.go" "bash git rm frozen"
expect_bash deny "sed -i '' 's/x/y/' pkg/a_test.go" "bash sed -i frozen"
expect_bash deny "echo x > pkg/a_test.go" "bash redirect onto frozen"
expect_bash deny "cd $repo && mv pkg/a_test.go /tmp/" "bash cd then mv frozen"
expect_bash deny "rm $repo/pkg/a_test.go" "bash rm frozen absolute"
expect_bash allow "go test ./pkg -run X > out.log" "bash redirect elsewhere"
expect_bash allow "cat pkg/a_test.go" "bash read frozen"
expect_bash allow "rm pkg/b_test.go" "bash rm unfrozen test"
expect_bash allow "go test ./pkg/a_test.go; rm -rf /tmp/x" "bash rm elsewhere in another segment"
expect_bash allow "git checkout -- pkg/a_test.go" "bash restore frozen"

echo frozen >"$mark"
expect deny "$repo/pkg/b_test.go" "frozen go test"
expect deny "$repo/py/test_x.py" "frozen py test"
expect deny "$repo/web/x.spec.ts" "frozen ts spec"
expect deny "$repo/crate/tests/it.rs" "frozen rust integration"
expect deny "$repo/crate/src/board/tests.rs" "frozen rust sibling unit tests"
expect deny "$repo/src/tests.rs" "frozen rust root unit tests"
expect deny "$repo/test/App.Tests/LexerTests.cs" "frozen csharp tests"
expect deny "$repo/test/App.Tests/LexerTest.cs" "frozen csharp test"
expect allow "$repo/src/App/Lexer.cs" "frozen csharp source"
expect allow "$repo/crate/src/board.rs" "frozen rust source"
expect allow "$repo/pkg/a.go" "frozen source"
expect allow "/nonexistent/elsewhere/a_test.go" "outside any repo"
expect_bash deny "rm tests/test_x.py" "bash frozen phase py test"
expect_bash deny "perl -pi -e 's/a/b/' web/x.spec.ts" "bash frozen phase perl -i"
expect_bash allow "rm pkg/a.go" "bash frozen phase source"

# Rust inline tests: only the trailing #[cfg(test)] mod tests region is frozen
board="$repo/crate/src/board.rs"
mkdir -p "$repo/crate/src"
cat >"$board" <<'RS'
pub fn size() -> u32 {
    3
}

#[cfg(test)]
fn helper() -> u32 {
    3
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn size_is_three() {
        assert_eq!(size(), 3);
    }
}
RS
plain="$repo/crate/src/plain.rs"
printf 'pub fn x() {}\n' >"$plain"
region() { bash "$(dirname "$hook")/test-region" "$@"; }
[ "$(region "$board" | head -n 2 | tail -n 1)" = "mod tests {" ] || {
	echo "FAIL test-region start"
	fail=1
}
[ "$(region "$board" | tail -n 1)" = "}" ] || {
	echo "FAIL test-region end"
	fail=1
}
[ -z "$(region "$plain")" ] || {
	echo "FAIL test-region on a file without tests"
	fail=1
}
[ "$(region - <"$board")" = "$(region "$board")" ] || {
	echo "FAIL test-region stdin"
	fail=1
}
attrs="$repo/crate/src/attrs.rs"
cat >"$attrs" <<'RS'
pub fn x() {}

#[cfg(test)]
#[allow(clippy::float_cmp)]
#[allow(
    clippy::cast_sign_loss,
)]
mod tests {
    #[test]
    fn t() {}
}
RS
[ "$(region "$attrs" | head -n 1)" = "#[cfg(test)]" ] || {
	echo "FAIL test-region attributes: start"
	fail=1
}
[ "$(region "$attrs" | grep -c .)" = 9 ] || {
	echo "FAIL test-region attributes: whole module"
	fail=1
}

printf 'green\ncrate/src/board.rs\n' >"$mark"
expect_json allow "$(edit "$board" "    3
}

#[cfg(test)]
fn helper" "    4 && 5
}

#[cfg(test)]
fn helper")" "green inline: edit code above the tests"
expect_json allow "$(edit "$board" "pub fn size() -> u32 {" "pub fn size() -> u32 { // &")" "green inline: edit first line"
expect_json deny "$(edit "$board" "assert_eq!(size(), 3);" "assert_eq!(size(), 4);")" "green inline: edit inside the tests"
expect_json deny "$(edit "$board" "3" "4" true)" "green inline: replace_all reaching the tests"
expect_json deny "$(edit "$board" "        assert_eq!(size(), 3);
    }
}" "        assert_eq!(size(), 3);
    }
}

pub fn after() {}")" "green inline: code after the tests"
expect_json allow "$(edit "$board" "        assert_eq!(size(), 3);
    }
}" "        assert_eq!(size(), 3);
    }

    #[test]
    fn size_is_odd() {
        assert_eq!(size() % 2, 1);
    }
}")" "green inline: append a test inside the module"
expect_json deny "$(edit "$board" "        assert_eq!(size(), 3);
    }
}" "        assert_eq!(size(), 3);
    }
}

#[cfg(test)]
mod more_tests {
    #[test]
    fn x() {}
}")" "green inline: a second test module"
expect_json deny "$(edit "$board" "#[cfg(test)]
mod tests {" "mod tests {")" "green inline: drop the cfg"
expect_json allow "$(edit "$board" "no such text" "x")" "green inline: old_string not found"
expect_json allow "$(jq -nc --arg p "$board" '{tool_name:"MultiEdit",tool_input:{file_path:$p,edits:[{old_string:"    3\n}\n\n#[cfg(test)]\nfn helper",new_string:"    4\n}\n\n#[cfg(test)]\nfn helper"}]}}')" "green inline: multiedit code"
expect_json deny "$(jq -nc --arg p "$board" '{tool_name:"MultiEdit",tool_input:{file_path:$p,edits:[{old_string:"pub fn size",new_string:"pub fn len"},{old_string:"size_is_three",new_string:"len_is_three"}]}}')" "green inline: multiedit reaching the tests"
expect_json allow "$(jq -nc --arg p "$board" --arg c "$(sed 's/^    3$/    9/' "$board")" '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}')" "green inline: write keeping the tests"
expect_json deny "$(jq -nc --arg p "$board" --arg c "$(sed 's/size(), 3/size(), 9/' "$board")" '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}')" "green inline: write changing the tests"
expect_json allow "$(edit "$plain" "pub fn x() {}" "pub fn y() {}")" "green inline: unlisted file"
expect_bash deny "sed -i '' 's/3/4/' crate/src/board.rs" "bash sed -i on inline frozen file"

echo frozen >"$mark"
expect_json allow "$(edit "$board" "pub fn size() -> u32 {" "pub fn len() -> u32 {")" "frozen inline: edit code"
expect_json deny "$(edit "$board" "size_is_three" "len_is_three")" "frozen inline: edit tests"
expect_json allow "$(edit "$plain" "pub fn x() {}" "pub fn y() {}")" "frozen inline: file without tests"
expect_bash deny "rm crate/src/board.rs" "bash frozen phase rm inline test file"
expect_bash allow "rm crate/src/plain.rs" "bash frozen phase rm file without tests"

[ $fail -eq 0 ] && echo ok
exit $fail
