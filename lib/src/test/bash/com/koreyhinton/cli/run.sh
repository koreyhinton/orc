#!/bin/bash

# Tests the orc command line (lib/src/main/bash/com/koreyhinton/cli): the
# orc dispatcher and orc root; orc init (what it finds, what it asks, what it
# writes, that stopping writes nothing, and that running it again only adds
# what's new); the build.sh it writes; orc check (which calls it catches and
# which mentions it lets through); how orc-env.sh finds orc; and that each
# language's skeleton compiles, where that compiler is installed. Each test
# runs in its own empty temp folder. Exits 1 if any test fails.

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "Error, script must not be sourced. Run again without sourcing it" >&2
    return 1
fi

RN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RN_RT="$(cd "${RN_DIR}/../../../../../../.." && pwd)"
RN_CLI="${RN_RT}/lib/src/main/bash/com/koreyhinton/cli"
RN_TMP="$(mktemp -d)"
trap 'rm -rf "${RN_TMP}"' EXIT

# the cli on PATH, as an app's developer would have it; ORC unset, so
# orc-env.sh finds orc through orc root. Answers come from flags unless a
# test sets ORC_INIT_INTERACTIVE and pipes them in.
export PATH="${RN_CLI}:${PATH}"
unset ORC ORC_INIT_INTERACTIVE

RN_PASSED=0
RN_FAILED=0
RN_SKIPPED=()

# fail <message>: fail the current test
fail() {
    echo "    FAIL: $*"
}

# skip <why>: note that part of a test couldn't run here
skip() {
    echo "    SKIP: $*"
}

# run_test <name>: run the function of that name in a fresh, empty folder
run_test() {
    local dir="${RN_TMP}/$1"
    mkdir -p "${dir}/app"
    (cd "${dir}/app" && "$1" < /dev/null) > "${dir}/out.log" 2>&1
    if grep -q '    FAIL: ' "${dir}/out.log"; then
        echo "fail  $1"
        grep '    FAIL: ' "${dir}/out.log"
        RN_FAILED=$((RN_FAILED + 1))
    else
        echo "ok    $1"
        RN_PASSED=$((RN_PASSED + 1))
    fi
    while IFS= read -r line; do
        RN_SKIPPED+=("$1: ${line#    SKIP: }")
    done < <(grep '    SKIP: ' "${dir}/out.log")
}

# snapshot: every file and folder here (but .git) with its contents' hash,
# to show nothing changed
snapshot() {
    find . -mindepth 1 -not -path './.git' -not -path './.git/*' -not -name 'out.txt' -not -name 'err.txt' \
        | sort | while IFS= read -r path; do
            if [[ -f "${path}" ]]; then echo "${path} $(md5sum < "${path}")"; else echo "${path}/"; fi
        done
}

# write <path> <line>...: a file with those lines
write() {
    local path=$1
    shift
    mkdir -p "$(dirname "${path}")"
    printf '%s\n' "$@" > "${path}"
}

# write_snippet <path> <line>...: a snippet script that prints its lines
write_snippet() {
    local path=$1
    shift
    write "${path}" '#!/bin/bash' '' 'v=$1' "$@"
    chmod +x "${path}"
}

# a small Cargo layout, as cargo init makes it
cargo_layout() {
    write Cargo.toml '[package]' 'name = "app"' 'version = "0.1.0"' "edition = \"${1:-2021}\"" '' '[dependencies]'
    write src/main.rs 'fn main() {' '    println!("Hello, world!");' '}'
}

# ---- orc, orc root ----

test_orc_with_no_command_prints_usage_and_fails() {
    orc > out.txt 2> err.txt
    [[ $? -eq 2 ]] || fail "exit $?, want 2"
    grep -q '^usage: orc' err.txt || fail "no usage on stderr"
}

test_orc_help_succeeds() {
    orc --help > out.txt || fail "orc --help failed"
    grep -q 'init' out.txt || fail "usage doesn't list init"
}

test_orc_rejects_an_unknown_command() {
    orc frobnicate 2> err.txt
    [[ $? -eq 2 ]] || fail "exit $?, want 2"
    grep -q 'unknown command: frobnicate' err.txt || fail "no error message"
    orc ../orc-init 2> /dev/null
    [[ $? -eq 2 ]] || fail "orc ../orc-init ran something"
    orc common 2> /dev/null
    [[ $? -eq 2 ]] || fail "orc common ran the shared file"
}

test_orc_root_is_the_folder_holding_lib() {
    [[ "$(orc root)" == "${RN_RT}" ]] || fail "orc root is $(orc root), want ${RN_RT}"
}

test_orc_root_works_through_a_symlink() {
    mkdir bin
    ln -s "${RN_CLI}/orc" bin/orc
    [[ "$(bin/orc root)" == "${RN_RT}" ]] || fail "through a symlink: $(bin/orc root)"
}

# ---- orc init: finding the pipelines ----

test_init_adopts_cargo_s_main_rs() {
    cargo_layout 2021
    cp src/main.rs ../original.rs
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    [[ -x src/main.sh ]] || fail "no executable src/main.sh"
    grep -qF '"src/main.sh|src/main.rs|rustfmt --edition 2021"' build.sh \
        || fail "build.sh pipeline: $(grep -F 'src/main.sh|' build.sh)"
    grep -q 'seeded the heredoc below from the original main.rs' src/main.sh || fail "main.sh doesn't say it was seeded"
    if command -v rustfmt > /dev/null; then
        ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
        cmp -s src/main.rs ../original.rs || fail "the first build changed main.rs: $(diff src/main.rs ../original.rs)"
    else
        skip "rustfmt isn't installed"
    fi
}

test_init_reads_the_rust_edition_or_defaults_to_2024() {
    write src/main.rs 'fn main() {}'
    orc init --yes > /dev/null 2>&1 || fail "orc init failed"
    grep -qF 'src/main.rs|rustfmt --edition 2024"' build.sh || fail "no Cargo.toml should mean 2024"
}

test_init_adopts_main_go_at_the_root() {
    write go.mod 'module example.com/app' '' 'go 1.21'
    write main.go 'package main' '' 'import "fmt"' '' 'func main() {' $'\tfmt.Println("hi")' '}'
    cp main.go ../original.go
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -qF '"main.sh|main.go|gofmt"' build.sh || fail "build.sh: $(grep -F 'main.sh|' build.sh)"
    if command -v gofmt > /dev/null; then
        ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
        cmp -s main.go ../original.go || fail "the first build changed main.go: $(diff main.go ../original.go)"
    else
        skip "gofmt isn't installed"
    fi
}

test_init_adopts_a_spring_application_and_skips_tests() {
    write src/main/java/com/example/demo/DemoApplication.java \
        'package com.example.demo;' '' '@SpringBootApplication' 'public class DemoApplication {' \
        '    public static void main(String[] args) {' '        SpringApplication.run(DemoApplication.class, args);' '    }' '}'
    write src/test/java/com/example/demo/DemoApplicationTests.java 'class DemoApplicationTests {}'
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    local dir=src/main/java/com/example/demo
    grep -qF "\"${dir}/main.sh|${dir}/DemoApplication.java|\"" build.sh || fail "build.sh: $(grep -F 'main.sh|' build.sh)"
    cp "${dir}/DemoApplication.java" ../original.java
    ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
    # no formatter for Java: the heredoc's indent passes through
    [[ "$(sed 's/^    //' "${dir}/DemoApplication.java")" == "$(cat ../original.java)" ]] \
        || fail "the first build changed more than indentation: $(diff "${dir}/DemoApplication.java" ../original.java)"
    [[ ! -e src/test/java/com/example/demo/main.sh ]] || fail "adopted the test class"
}

test_init_finds_an_entry_file_gitignore_lists() {
    # a .gitignore that already ignores the output, as one from an earlier
    # orc init would
    command -v git > /dev/null || { skip "git isn't installed"; return; }
    git init -q .
    cargo_layout
    write .gitignore '/target' '/src/main.rs'
    orc init --dry-run > out.txt 2>&1 || fail "dry run failed: $(cat out.txt)"
    grep -q 'create    src/main.sh  (seeded from src/main.rs' out.txt || fail "missed src/main.rs: $(cat out.txt)"
}

test_init_skips_entry_files_in_ignored_folders() {
    command -v git > /dev/null || { skip "git isn't installed"; return; }
    git init -q .
    write .gitignore 'history/'
    write history/old/src/main.rs 'fn main() {}'
    write main.go 'package main' 'func main() {}'
    orc init --dry-run > out.txt 2>&1 || fail "dry run failed: $(cat out.txt)"
    grep -q 'main.sh -> main.go' out.txt || fail "didn't adopt main.go: $(cat out.txt)"
    ! grep -q 'history' out.txt || fail "looked in an ignored folder: $(cat out.txt)"
}

test_init_stops_on_several_entry_files_without_a_terminal() {
    write server/main.go 'package main' 'func main() {}'
    write web/src/main.ts 'console.log(1);'
    local before
    before=$(snapshot)
    orc init --yes > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q 'found several entry files' err.txt || fail "$(cat err.txt)"
    grep -q -- '--entry' err.txt || fail "doesn't suggest --entry"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_entry_chooses_among_several() {
    write server/main.go 'package main' 'func main() {}'
    write web/src/main.ts 'console.log(1);'
    orc init --yes --entry web/src/main.ts > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    [[ -f web/src/main.sh && ! -e server/main.sh ]] || fail "wrong main.sh"
    grep -qF '"web/src/main.sh|web/src/main.ts|"' build.sh || fail "build.sh: $(grep -F 'main.sh|' build.sh)"
}

test_init_asks_which_entry_files_in_a_terminal() {
    write server/main.go 'package main' 'func main() {}'
    write web/src/main.ts 'console.log(1);'
    printf '1,2\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    [[ -f server/main.sh && -f web/src/main.sh ]] || fail "didn't set up both"
    ! grep -q 'Let build.sh own' err.txt || fail "asked again about files picked from the list"
    [[ "$(grep -c '|' build.sh)" -ge 2 ]] || fail "build.sh lacks two pipelines"
}

test_init_adds_a_main_sh_that_is_already_written() {
    write_snippet src/main.sh 'cat << EOF' 'fn main() {}' 'EOF'
    write src/main.rs 'fn main() {}'
    cp src/main.sh ../main.sh.before
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    cmp -s src/main.sh ../main.sh.before || fail "changed a main.sh that was already written"
    grep -qF '"src/main.sh|src/main.rs|rustfmt' build.sh || fail "build.sh: $(grep -F 'main.sh|' build.sh)"
}

test_init_fills_an_empty_main_sh_for_the_extension_given() {
    mkdir src && touch src/main.sh
    orc init --yes --ext go > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -q 'func main()' src/main.sh || fail "no Go skeleton in main.sh"
    grep -qF '"src/main.sh|src/main.go|gofmt"' build.sh || fail "build.sh: $(grep -F 'main.sh|' build.sh)"
}

test_init_asks_an_empty_main_sh_s_extension_in_a_terminal() {
    mkdir src && touch src/main.sh
    printf 'java\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    grep -qF '"src/main.sh|src/Main.java|"' build.sh || fail "Java's file should be Main.java: $(grep -F 'main.sh|' build.sh)"
    grep -q 'public class Main' src/main.sh || fail "no Java skeleton"
}

test_init_with_nothing_to_go_on_needs_a_terminal_or_flags() {
    orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q -- '--yes' err.txt || fail "doesn't suggest --yes: $(cat err.txt)"
    [[ -z "$(ls -A)" || "$(ls -A)" == $'err.txt\nout.txt' ]] || fail "wrote: $(ls -A)"
}

test_init_creates_src_main_sh_when_you_say_yes() {
    printf '\nrs\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    grep -q 'Create src/main.sh? \[Y/n\]' err.txt || fail "didn't ask"
    grep -q 'fn main()' src/main.sh || fail "no Rust skeleton"
    grep -qF '"src/main.sh|src/main.rs|rustfmt --edition 2024"' build.sh || fail "build.sh: $(grep -F 'main.sh|' build.sh)"
}

test_init_writes_nothing_when_you_say_no() {
    printf 'n\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q 'nothing was written' err.txt || fail "$(cat err.txt)"
    [[ "$(ls -A)" == $'err.txt\nout.txt' ]] || fail "wrote: $(ls -A)"
}

test_init_creates_src_main_sh_from_flags() {
    orc init --yes --ext c > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -q 'int main(void)' src/main.sh || fail "no C skeleton"
    ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
    grep -q 'int main(void)' src/main.c || fail "no src/main.c"
}

test_init_unknown_extension_gets_an_empty_program() {
    orc init --yes --ext zig > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -q 'orc has no .zig skeleton' out.txt || fail "the plan doesn't say so: $(cat out.txt)"
    grep -qF '"src/main.sh|src/main.zig|"' build.sh || fail "build.sh: $(grep -F 'main.sh|' build.sh)"
}

# ---- orc init: owning an existing file, and framework skeletons ----

# a Cargo project that depends on macroquad, with cargo's untouched main.rs
macroquad_layout() {
    write Cargo.toml '[package]' 'name = "app"' 'version = "0.1.0"' 'edition = "2024"' '' '[dependencies]' 'macroquad = "0.4.16"'
    write src/main.rs 'fn main() {' '    println!("Hello, world!");' '}'
}

test_init_asks_before_owning_an_entry_file() {
    cargo_layout
    local before
    before=$(snapshot)
    printf 'n\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q 'Let build.sh own src/main.rs? \[Y/n\]' err.txt || fail "didn't ask: $(cat err.txt)"
    grep -q 'direct edits to src/main.rs are overwritten on every build' err.txt || fail "didn't explain"
    grep -q 'no pipeline left to set up' err.txt || fail "$(cat err.txt)"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_owning_an_entry_file_without_a_terminal_needs_yes() {
    cargo_layout
    local before
    before=$(snapshot)
    orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q -- '--yes' err.txt || fail "doesn't suggest --yes: $(cat err.txt)"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_offers_macroquad_for_cargo_s_hello_world() {
    macroquad_layout
    printf '\n\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    grep -q 'Start src/main.sh from a macroquad skeleton instead? \[Y/n\]' err.txt || fail "didn't offer: $(cat err.txt)"
    grep -q '#\[macroquad::main("app")\]' src/main.sh || fail "no macroquad skeleton: $(cat src/main.sh)"
    grep -q 'Rust macroquad skeleton' out.txt || fail "the plan doesn't say so: $(cat out.txt)"
    grep -q 'overwrite src/main.rs' out.txt || fail "the plan doesn't say main.rs is overwritten"
}

test_init_yes_takes_the_macroquad_skeleton() {
    macroquad_layout
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -q 'next_frame().await' src/main.sh || fail "no macroquad skeleton"
}

test_init_keeps_hello_world_when_you_decline_macroquad() {
    macroquad_layout
    printf '\nn\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    grep -q 'Hello, world!' src/main.sh || fail "not seeded from main.rs"
    ! grep -q 'macroquad::main' src/main.sh || fail "used the skeleton anyway"
}

test_init_seeds_real_code_even_with_macroquad() {
    macroquad_layout
    write src/main.rs 'use macroquad::prelude::*;' '' '#[macroquad::main("Mine")]' 'async fn main() {}'
    printf '\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    ! grep -q 'skeleton instead' err.txt || fail "offered to replace real code"
    grep -q 'macroquad::main("Mine")' src/main.sh || fail "not seeded from main.rs"
}

test_init_no_framework_without_the_dependency() {
    cargo_layout
    printf '\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    ! grep -q 'skeleton instead' err.txt || fail "offered a framework: $(cat err.txt)"
}

test_init_a_dev_dependency_is_not_a_framework() {
    write Cargo.toml '[package]' 'name = "app"' 'edition = "2024"' '' '[dev-dependencies]' 'macroquad = "0.4.16"'
    orc init --yes --ext rs > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    ! grep -q 'macroquad' src/main.sh || fail "used the macroquad skeleton for a dev-dependency"
}

test_init_finds_dependency_tables_of_each_form() {
    write Cargo.toml '[package]' 'name = "app"' '' '[dependencies.macroquad]' 'version = "0.4.16"'
    orc init --yes --ext rs > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -q 'macroquad::main' src/main.sh || fail "missed [dependencies.macroquad]"
    rm -rf ./* .[!.]*
    write Cargo.toml '[package]' 'name = "app"' '' "[target.'cfg(unix)'.dependencies]" 'macroquad = "0.4.16"'
    orc init --yes --ext rs > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -q 'macroquad::main' src/main.sh || fail "missed a target dependency table"
}

test_init_fresh_rust_with_macroquad_uses_its_skeleton() {
    write Cargo.toml '[package]' 'name = "app"' 'edition = "2024"' '' '[dependencies]' 'macroquad = "0.4.16"'
    orc init --yes --ext rs > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    grep -q '#\[macroquad::main("app")\]' src/main.sh || fail "no macroquad skeleton"
}

test_skeleton_rs_macroquad_compiles() {
    command -v cargo > /dev/null || { skip "cargo isn't installed, so the macroquad skeleton wasn't compiled"; return; }
    macroquad_layout
    if ! cargo fetch --offline > out.txt 2>&1; then
        skip "macroquad isn't in cargo's offline cache, so its skeleton wasn't compiled"
        return
    fi
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
    CARGO_TARGET_DIR="${RN_TMP}/cargo-target" cargo check --offline -q > out.txt 2>&1 \
        || fail "the macroquad skeleton doesn't compile: $(cat out.txt)"
}

# ---- orc init: stopping writes nothing ----

test_init_ctrl_c_at_a_question_writes_nothing() {
    mkfifo ../answers
    # hold the pipe open, so the question waits
    exec 3<> ../answers
    ORC_INIT_INTERACTIVE=1 timeout --preserve-status -s INT 2 "${RN_CLI}/orc" init < ../answers > out.txt 2> err.txt
    local status=$?
    exec 3>&-
    [[ ${status} -eq 130 ]] || fail "exit ${status}, want 130"
    grep -q 'stopped; nothing was written' err.txt || fail "$(cat err.txt)"
    [[ "$(ls -A)" == $'err.txt\nout.txt' ]] || fail "wrote: $(ls -A)"
}

test_init_end_of_input_at_a_question_writes_nothing() {
    cargo_layout
    local before
    before=$(snapshot)
    printf '' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_declining_the_plan_writes_nothing() {
    cargo_layout
    local before
    before=$(snapshot)
    printf '\nn\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q 'Proceed? \[y/N\]' err.txt || fail "didn't ask to proceed"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_without_yes_or_a_terminal_only_shows_the_plan() {
    # a main.sh already written: no questions before the plan
    write_snippet src/main.sh 'cat << EOF' 'fn main() {}' 'EOF'
    write src/main.rs 'fn main() {}'
    local before
    before=$(snapshot)
    orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q 'orc init will:' out.txt || fail "no plan shown"
    grep -q -- '--yes' err.txt || fail "doesn't suggest --yes"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_dry_run_writes_nothing() {
    cargo_layout
    local before
    before=$(snapshot)
    orc init --dry-run > out.txt 2>&1 || fail "dry run failed"
    grep -q 'create    src/main.sh' out.txt || fail "the plan lacks main.sh: $(cat out.txt)"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_never_replaces_a_build_sh_it_did_not_write() {
    cargo_layout
    write build.sh '#!/bin/bash' 'make all'
    local before
    before=$(snapshot)
    orc init --yes > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    grep -q "build.sh is already here, and orc didn't write it" err.txt || fail "$(cat err.txt)"
    [[ "$(snapshot)" == "${before}" ]] || fail "wrote something"
}

test_init_never_replaces_an_orc_env_sh_it_did_not_write() {
    cargo_layout
    write orc-env.sh 'export NSMAP=/somewhere'
    orc init --yes > /dev/null 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    [[ ! -e build.sh ]] || fail "wrote build.sh"
}

# ---- orc init: running it again ----

test_init_again_with_nothing_new_does_nothing() {
    cargo_layout
    orc init --yes > /dev/null 2>&1 || fail "first orc init failed"
    local before
    before=$(snapshot)
    orc init --yes > out.txt 2>&1 || fail "second orc init failed"
    grep -q 'nothing to do' out.txt || fail "$(cat out.txt)"
    [[ "$(snapshot)" == "$(echo "${before}" | grep -v 'out.txt')" || "$(snapshot | grep -v out.txt)" == "$(echo "${before}" | grep -v out.txt)" ]] \
        || fail "changed files"
}

test_init_again_adds_a_new_pipeline_and_keeps_the_old() {
    cargo_layout
    orc init --yes > /dev/null 2>&1 || fail "first orc init failed"
    write_snippet web/main.sh 'cat << EOF' 'console.log(1);' 'EOF'
    write web/main.ts 'console.log(1);'
    orc init --yes > out.txt 2>&1 || fail "second orc init failed: $(cat out.txt)"
    grep -qF '"src/main.sh|src/main.rs|rustfmt --edition 2021"' build.sh || fail "lost the first pipeline"
    grep -qF '"web/main.sh|web/main.ts|"' build.sh || fail "didn't add web: $(grep -F 'main.sh|' build.sh)"
    [[ "$(grep -c '^    "' build.sh)" -eq 2 ]] || fail "want 2 pipelines: $(grep '^    "' build.sh)"
    grep -qxF '/web/main.ts' .gitignore || fail ".gitignore lacks /web/main.ts"
    [[ "$(grep -cxF '/src/main.rs' .gitignore)" -eq 1 ]] || fail "/src/main.rs is in .gitignore twice"
}

test_init_again_refreshes_orc_md() {
    cargo_layout
    orc init --yes > /dev/null 2>&1 || fail "first orc init failed"
    echo "old rules" > ORC.md
    orc init --yes > out.txt 2>&1 || fail "second orc init failed: $(cat out.txt)"
    grep -q 'update    ORC.md' out.txt || fail "the plan doesn't say so: $(cat out.txt)"
    cmp -s ORC.md "${RN_CLI}/init/ORC.md" || fail "ORC.md wasn't refreshed"
}

test_init_again_restores_the_claude_md_import() {
    cargo_layout
    orc init --yes > /dev/null 2>&1 || fail "first orc init failed"
    write CLAUDE.md '# app' '' 'Our notes.'
    orc init --yes > /dev/null 2>&1 || fail "second orc init failed"
    grep -qx '@ORC.md' CLAUDE.md || fail "the import wasn't restored"
    grep -qx 'Our notes.' CLAUDE.md || fail "lost the app's notes"
}

# ---- orc init: the files around the pipelines ----

test_init_writes_the_whole_setup() {
    cargo_layout
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    for path in LICENSE .gitignore ORC.md CLAUDE.md AGENTS.md orc-env.sh build.sh src/main.sh .github/workflows/orc.yml; do
        [[ -f "${path}" ]] || fail "missing ${path}"
    done
    for path in orc-env.sh build.sh src/main.sh; do
        [[ -x "${path}" ]] || fail "${path} isn't executable"
    done
    cmp -s LICENSE "${RN_RT}/LICENSE" || fail "LICENSE isn't orc's"
    if grep -rl '@ORC_\|@RUST_EDITION@' --exclude-dir=.git . > left.txt; then
        fail "placeholders left in: $(tr '\n' ' ' < left.txt)"
    fi
}

test_init_gitignore_appends_only_what_is_missing() {
    cargo_layout
    write .gitignore '/target' '*~' 'notes/'
    orc init --yes > /dev/null 2>&1 || fail "orc init failed"
    [[ "$(head -3 .gitignore)" == $'/target\n*~\nnotes/' ]] || fail "changed the existing lines"
    for pattern in '\#*\#' '.#*' '/src/main.rs' '/src/main.rs.tmp'; do
        grep -qxF "${pattern}" .gitignore || fail ".gitignore lacks ${pattern}"
    done
    [[ "$(grep -cxF '*~' .gitignore)" -eq 1 ]] || fail "*~ twice"
    [[ "$(grep -cxF '/target' .gitignore)" -eq 1 ]] || fail "/target twice"
    grep -q '^# orc: ' .gitignore || fail "no orc header"
}

test_init_gitignore_works_with_git() {
    command -v git > /dev/null || { skip "git isn't installed"; return; }
    cargo_layout
    git init -q .
    orc init --yes > /dev/null 2>&1 || fail "orc init failed"
    touch 'notes.txt~' '#notes.txt#' '.#notes.txt' kept.txt src/main.rs.tmp
    local status
    status=$(git status --porcelain --untracked-files=all)
    [[ -z "$(echo "${status}" | grep -E 'notes|main\.rs')" ]] || fail "git doesn't ignore: ${status}"
    echo "${status}" | grep -q 'kept.txt' || fail "git ignores too much"
}

test_init_notes_an_output_git_tracks() {
    command -v git > /dev/null || { skip "git isn't installed"; return; }
    cargo_layout
    git init -q . && git add . && git -c user.name=t -c user.email=t@t commit -qm init
    orc init --dry-run > out.txt 2>&1 || fail "dry run failed"
    grep -q 'git rm --cached src/main.rs' out.txt || fail "no note: $(cat out.txt)"
}

test_init_keeps_an_agpl_license() {
    cargo_layout
    cp "${RN_RT}/LICENSE" LICENSE
    echo "edited" >> LICENSE
    orc init --yes > out.txt 2>&1 || fail "orc init failed"
    [[ "$(tail -1 LICENSE)" == "edited" ]] || fail "replaced an AGPL LICENSE"
}

test_init_keeps_another_license_unless_told() {
    cargo_layout
    write LICENSE 'MIT License'
    orc init --yes > out.txt 2>&1 || fail "orc init failed"
    [[ "$(cat LICENSE)" == "MIT License" ]] || fail "replaced the MIT LICENSE"
    grep -q 'keep      LICENSE' out.txt || fail "the plan doesn't say so: $(cat out.txt)"
}

test_init_license_agpl_replaces_another_license() {
    cargo_layout
    write LICENSE 'MIT License'
    orc init --yes --license agpl > /dev/null 2>&1 || fail "orc init failed"
    cmp -s LICENSE "${RN_RT}/LICENSE" || fail "not replaced"
}

test_init_asks_before_replacing_another_license() {
    cargo_layout
    write LICENSE 'MIT License'
    printf 'y\ny\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    grep -q 'outside contributors would have to agree' err.txt || fail "no warning"
    cmp -s LICENSE "${RN_RT}/LICENSE" || fail "not replaced after yes"
}

test_init_keeps_another_license_by_default_in_a_terminal() {
    cargo_layout
    write LICENSE 'MIT License'
    printf '\n\ny\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    [[ "$(cat LICENSE)" == "MIT License" ]] || fail "replaced on Enter"
}

test_init_adds_to_an_existing_claude_md_and_agents_md() {
    cargo_layout
    write CLAUDE.md '# app' '' 'Our notes.'
    write AGENTS.md '# app' '' 'Agent notes.'
    orc init --yes > /dev/null 2>&1 || fail "orc init failed"
    [[ "$(head -3 CLAUDE.md)" == $'# app\n\nOur notes.' ]] || fail "changed CLAUDE.md's notes"
    grep -qx '@ORC.md' CLAUDE.md || fail "CLAUDE.md doesn't import ORC.md"
    [[ "$(head -3 AGENTS.md)" == $'# app\n\nAgent notes.' ]] || fail "changed AGENTS.md's notes"
    grep -q '\[ORC.md\](ORC.md)' AGENTS.md || fail "AGENTS.md doesn't link ORC.md"
}

test_init_new_agents_md_links_claude_md_and_orc_md() {
    cargo_layout
    orc init --yes > /dev/null 2>&1 || fail "orc init failed"
    grep -q '\[CLAUDE.md\](CLAUDE.md)' AGENTS.md || fail "no link to CLAUDE.md"
    grep -q '\[ORC.md\](ORC.md)' AGENTS.md || fail "no link to ORC.md"
    grep -qx '@ORC.md' CLAUDE.md || fail "CLAUDE.md doesn't import ORC.md"
    grep -q '\[ORC.md\](ORC.md)' CLAUDE.md || fail "CLAUDE.md doesn't link ORC.md"
}

test_init_leaves_an_existing_import_alone() {
    cargo_layout
    write CLAUDE.md '# app' '@ORC.md'
    orc init --yes > /dev/null 2>&1 || fail "orc init failed"
    [[ "$(cat CLAUDE.md)" == $'# app\n@ORC.md' ]] || fail "changed CLAUDE.md"
}

test_init_seeding_keeps_what_bash_would_expand() {
    # a C file with the characters a heredoc would otherwise expand, and a
    # line that is just EOF
    write src/main.c '#include <stdio.h>' '/* $HOME `date` \ and $(ls) */' 'int main(void) {' \
        '    printf("%s\\n", "a \\\\ b");' 'EOF' '    return 0;' '}' ''
    cp src/main.c ../original.c
    orc init --yes > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
    [[ "$(sed 's/^    //' src/main.c)" == "$(cat ../original.c)" ]] \
        || fail "the first build changed more than indentation: $(diff <(sed 's/^    //' src/main.c) ../original.c)"
}

test_init_rejects_bad_arguments() {
    for args in "--ext ../x" "--ext a-b" "--license mit" "--frob"; do
        # shellcheck disable=SC2086
        orc init ${args} > /dev/null 2>&1
        [[ $? -eq 2 ]] || fail "accepted: ${args}"
    done
    orc init --entry missing.rs --yes > /dev/null 2>&1
    [[ $? -eq 1 ]] || fail "accepted a missing --entry"
    [[ -z "$(ls -A)" ]] || fail "wrote files: $(ls -A)"
}

test_init_workflow_is_valid_yaml() {
    cargo_layout
    orc init --yes > /dev/null 2>&1 || fail "orc init failed"
    grep -q 'ORC: ${{ github.workspace }}/orc' .github/workflows/orc.yml || fail "the workflow doesn't set ORC"
    if command -v python3 > /dev/null && python3 -c 'import yaml' 2> /dev/null; then
        python3 -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' .github/workflows/orc.yml \
            || fail "the workflow isn't valid YAML"
    else
        skip "no python3 yaml to check the workflow"
    fi
}

# ---- orc init: warnings that don't stop it ----

test_init_warns_when_cargo_toml_is_missing() {
    orc init --yes --ext rs > out.txt 2> err.txt || fail "orc init stopped: $(cat err.txt)"
    grep -q 'warning: no Cargo.toml for src/main.rs' err.txt || fail "no warning: $(cat err.txt)"
    grep -q 'run cargo init' err.txt || fail "doesn't name cargo init: $(cat err.txt)"
    [[ -f src/main.sh ]] || fail "the warning stopped the setup"
}

test_init_does_not_warn_with_a_cargo_toml() {
    cargo_layout
    orc init --yes > out.txt 2> err.txt || fail "orc init failed"
    ! grep -q 'no Cargo.toml' err.txt || fail "warned anyway: $(cat err.txt)"
}

test_init_finds_a_project_file_above_the_output() {
    write go.mod 'module example.com/app' '' 'go 1.21'
    write cmd/app/main.go 'package main' 'func main() {}'
    orc init --yes > out.txt 2> err.txt || fail "orc init failed: $(cat err.txt)"
    ! grep -q 'no go.mod' err.txt || fail "missed the go.mod above: $(cat err.txt)"
}

test_init_project_files_can_be_globs() {
    write Program.cs 'class Program { static void Main() {} }'
    orc init --dry-run > out.txt 2> err.txt || fail "dry run failed"
    grep -q 'no \*.csproj for Program.cs' err.txt || fail "no warning without a .csproj: $(cat err.txt)"
    write app.csproj '<Project/>'
    orc init --dry-run > out.txt 2> err.txt || fail "dry run failed"
    ! grep -q 'csproj' err.txt || fail "warned with app.csproj there: $(cat err.txt)"
}

test_init_never_warns_for_c_with_no_project_file() {
    orc init --yes --ext c > out.txt 2> err.txt || fail "orc init failed"
    ! grep -q 'warning: no ' err.txt || fail "warned: $(cat err.txt)"
}

test_init_warns_in_time_to_stop() {
    # the warning comes before the plan is accepted, and stopping there
    # writes nothing
    printf 'y\nrs\nn\n' | ORC_INIT_INTERACTIVE=1 orc init > out.txt 2> err.txt
    [[ $? -eq 1 ]] || fail "exit $?, want 1"
    local warned asked
    warned=$(grep -n 'no Cargo.toml' err.txt | head -1 | cut -d: -f1)
    asked=$(grep -n 'Proceed?' err.txt | head -1 | cut -d: -f1)
    [[ -n "${warned}" && -n "${asked}" && ${warned} -lt ${asked} ]] || fail "warned at ${warned:-never}, asked at ${asked:-never}"
    [[ "$(ls -A)" == $'err.txt\nout.txt' ]] || fail "wrote: $(ls -A)"
}

test_init_warns_when_orc_is_not_set() {
    orc init --yes --ext c > out.txt 2> err.txt || fail "orc init failed"
    grep -q "warning: ORC isn't set; build.sh will use the orc on PATH (${RN_RT})" err.txt || fail "$(cat err.txt)"
}

test_init_says_nothing_about_orc_when_it_is_set_and_on_path() {
    ORC="${RN_RT}" orc init --yes --ext c > out.txt 2> err.txt || fail "orc init failed"
    ! grep -q 'ORC\|PATH' err.txt || fail "warned: $(cat err.txt)"
}

test_init_warns_when_orc_is_not_on_path() {
    PATH=/usr/bin:/bin "${RN_CLI}/orc" init --yes --ext c > out.txt 2> err.txt || fail "orc init stopped: $(cat err.txt)"
    grep -q "warning: orc isn't on PATH; add ${RN_CLI} to PATH" err.txt || fail "$(cat err.txt)"
    grep -q "there's no .*/orc: build.sh won't find orc" err.txt || fail "doesn't say build.sh can't find orc: $(cat err.txt)"
    [[ -f build.sh ]] || fail "the warnings stopped the setup"
}

test_init_names_the_orc_next_to_the_folder() {
    ln -s "${RN_RT}" ../orc
    PATH=/usr/bin:/bin "${RN_CLI}/orc" init --yes --ext c > out.txt 2> err.txt || fail "orc init failed"
    grep -qF "build.sh will use the orc next to this folder (${RN_RT})" err.txt || fail "$(cat err.txt)"
}

# ---- each language's skeleton compiles ----

# skeleton <ext> <compile command, run in the folder>: orc init --ext <ext>,
# build, then compile src/ (skipped if the compiler isn't installed)
skeleton() {
    local ext=$1 compiler=$2
    shift 2
    orc init --yes --ext "${ext}" > out.txt 2>&1 || { fail "orc init --ext ${ext} failed: $(cat out.txt)"; return; }
    ./build.sh > out.txt 2>&1 || { fail "build failed: $(cat out.txt)"; return; }
    if ! command -v "${compiler}" > /dev/null; then
        skip "${compiler} isn't installed, so the ${ext} skeleton wasn't compiled"
        return
    fi
    (cd src && "$@") > out.txt 2>&1 || fail "the ${ext} skeleton doesn't compile: $(cat out.txt)"
}

test_skeleton_rs_compiles() { skeleton rs rustc rustc --edition 2024 -o ../app main.rs; }
test_skeleton_go_compiles() { skeleton go go go build -o ../app main.go; }
test_skeleton_java_compiles() { skeleton java javac javac -d ../classes Main.java; }
test_skeleton_kt_compiles() { skeleton kt kotlinc kotlinc Main.kt -d ../classes; }
test_skeleton_c_compiles() { skeleton c gcc gcc -Wall -Werror -o ../app main.c; }
test_skeleton_cpp_compiles() { skeleton cpp g++ g++ -Wall -Werror -o ../app main.cpp; }
test_skeleton_cs_compiles() { skeleton cs dotnet false; }
test_skeleton_ts_compiles() { skeleton ts tsc tsc --strict --noEmit main.ts; }

# ---- the build.sh orc init writes ----

test_build_inlines_a_snippet_through_main_sh() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    write_snippet src/greet.sh '. ${NSMAP}/bind ${v} Name' 'cat << EOF' '    // hello ${!name}' 'EOF'
    sed -i 's|^    int main(void) {$|    int main(void) {\n` ./greet.sh ${v}greet_ `|' src/main.sh
    sed -i 's|^cat << EOF$|export ${v}greet_Name=world\ncat << EOF|' src/main.sh
    ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
    grep -q '// hello world' src/main.c || fail "the snippet's code isn't in src/main.c: $(cat src/main.c)"
}

test_build_runs_from_any_folder() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    mkdir elsewhere && cd elsewhere || return
    ../build.sh > out.txt 2>&1 || fail "build from a subfolder failed: $(cat out.txt)"
    [[ -f ../src/main.c ]] || fail "no output"
}

test_build_stops_when_a_snippet_calls_a_snippet() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    write_snippet src/inner.sh 'echo inner'
    write_snippet src/outer.sh 'cat << EOF' '` ./inner.sh ${v}in_ `' 'EOF'
    sed -i 's|^cat << EOF$|cat << EOF\n` ./outer.sh ${v}out_ `|' src/main.sh
    ./build.sh > out.txt 2>&1
    [[ $? -eq 1 ]] || fail "the build passed: $(cat out.txt)"
    grep -q 'src/outer.sh:5: runs a script' out.txt || fail "doesn't point at src/outer.sh:5: $(cat out.txt)"
    [[ ! -e src/main.c ]] || fail "wrote the output anyway"
}

test_build_keeps_the_last_good_output_when_main_sh_fails() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    echo "good" > src/main.c
    echo 'exit 3' >> src/main.sh
    ./build.sh > out.txt 2>&1
    [[ $? -eq 1 ]] || fail "the build passed"
    [[ "$(cat src/main.c)" == "good" ]] || fail "the last good output was lost"
    [[ ! -e src/main.c.tmp ]] || fail "left the temp file"
}

test_build_keeps_the_last_good_output_when_the_formatter_fails() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    echo "good" > src/main.c
    sed -i 's#"src/main.sh|src/main.c|"#"src/main.sh|src/main.c|false"#' build.sh
    ./build.sh > out.txt 2>&1
    [[ $? -eq 1 ]] || fail "the build passed"
    [[ "$(cat src/main.c)" == "good" ]] || fail "the last good output was lost"
}

test_build_runs_every_pipeline() {
    write_snippet api/main.sh 'cat << EOF' 'int main(void) { return 0; }' 'EOF'
    write_snippet web/main.sh 'cat << EOF' 'console.log(1);' 'EOF'
    orc init --yes --ext ts > out.txt 2>&1 || fail "orc init failed: $(cat out.txt)"
    ./build.sh > out.txt 2>&1 || fail "build failed: $(cat out.txt)"
    [[ -f api/main.ts && -f web/main.ts ]] || fail "missing an output: $(ls api web)"
}

# ---- orc check ----

# each line is a snippet line that runs another script
RN_CALLS=(
    '` ./other.sh ${v}x_ `'
    '        ` ./other.sh ${v}x_ `'
    'echo "$(./other.sh)"'
    './other.sh'
    '    ${ORC_WS}/snippets/read.sh ${v}rd_ || exit 1'
    '"${DIR}/other.sh" arg'
    '. ./other.sh'
    'source other.sh'
    'bash other.sh'
    'sh ./other.sh'
    'exec ./other.sh'
    'true && ./other.sh'
    'x=1; ./other.sh'
)

# each line mentions a script without running it
RN_MENTIONS=(
    '# the interface, see other.sh'
    '    # called from main.sh'
    '    // the HUD (update-hud.sh clicks them and draw-hud.sh draws them)'
    '    // ws read.sh): "start" gives the seed'
    '. ${NSMAP}/bind ${v} Units View'
    'echo "a .sh file"'
    'let path = "assets/x.png";'
)

test_check_catches_each_way_of_running_a_script() {
    write_snippet src/main.sh '` ./a.sh ${v}a_ `'
    for line in "${RN_CALLS[@]}"; do
        write_snippet src/a.sh 'cat << EOF' "${line}" 'EOF'
        orc check > out.txt 2>&1
        [[ $? -eq 1 ]] || fail "missed: ${line}"
    done
}

test_check_lets_mentions_through() {
    write_snippet src/main.sh '` ./a.sh ${v}a_ `'
    for line in "${RN_MENTIONS[@]}"; do
        write_snippet src/a.sh 'cat << EOF' "${line}" 'EOF'
        orc check > out.txt 2>&1 || fail "flagged: ${line}: $(cat out.txt)"
    done
}

test_check_lets_main_sh_call_snippets() {
    write_snippet src/main.sh './models.sh' '` ./a.sh ${v}a_ `' 'x=$(./b.sh)' '${ORC_WS}/models.sh 1.0 || exit 1'
    write_snippet src/models.sh 'echo models'
    write_snippet src/a.sh 'echo a'
    write_snippet src/b.sh 'echo b'
    orc check > out.txt 2>&1 || fail "main.sh's calls were flagged: $(cat out.txt)"
    grep -q '(1 main.sh, 3 snippets)' out.txt || fail "$(cat out.txt)"
}

test_check_flags_models_sh_calling_a_script() {
    write_snippet src/main.sh './models.sh'
    write_snippet src/models.sh 'cat << EOF' 'EOF' './extra-models.sh'
    orc check > out.txt 2>&1
    [[ $? -eq 1 ]] || fail "models.sh calling a script passed"
}

test_check_checks_snippets_in_subfolders() {
    write_snippet src/main.sh '` ./draw/grid.sh ${v}g_ `'
    write_snippet src/draw/grid.sh '` ./line.sh ${v}l_ `'
    orc check > out.txt 2>&1
    [[ $? -eq 1 ]] || fail "src/draw/grid.sh calling a script passed"
    grep -q 'src/draw/grid.sh:4' out.txt || fail "doesn't name src/draw/grid.sh:4: $(cat out.txt)"
}

test_check_checks_every_pipeline() {
    write_snippet api/main.sh '` ./a.sh ${v}a_ `'
    write_snippet api/a.sh 'echo a'
    write_snippet web/main.sh '` ./b.sh ${v}b_ `'
    write_snippet web/b.sh './c.sh'
    orc check > out.txt 2>&1
    [[ $? -eq 1 ]] || fail "web/b.sh calling a script passed"
    grep -q 'web/b.sh:4' out.txt || fail "$(cat out.txt)"
}

test_check_reports_every_violation() {
    write_snippet src/main.sh '` ./a.sh ${v}a_ `' '` ./b.sh ${v}b_ `'
    write_snippet src/a.sh './b.sh' './c.sh'
    write_snippet src/b.sh 'source ./c.sh'
    orc check > out.txt 2>&1
    [[ "$(grep -c ': runs a script' out.txt)" -eq 3 ]] || fail "want 3 violations: $(cat out.txt)"
}

test_check_leaves_library_snippets_to_their_library() {
    write_snippet src/main.sh '` ${ORC_WS}/snippets/read.sh ${v}rd_ `'
    orc check > out.txt 2>&1 || fail "a library call was flagged: $(cat out.txt)"
}

test_check_skips_what_git_ignores() {
    command -v git > /dev/null || { skip "git isn't installed"; return; }
    git init -q .
    write_snippet src/main.sh 'echo'
    write .gitignore 'history'
    write_snippet history/old/main.sh '` ./bad.sh ${v}b_ `'
    write_snippet history/old/bad.sh './worse.sh'
    orc check > out.txt 2>&1 || fail "checked an ignored folder: $(cat out.txt)"
}

test_check_needs_a_main_sh() {
    write_snippet src/a.sh 'echo'
    orc check > out.txt 2>&1
    [[ $? -eq 2 ]] || fail "exit $?, want 2"
    orc check missing > /dev/null 2>&1
    [[ $? -eq 2 ]] || fail "a missing folder didn't fail with 2"
}

# ---- orc-env.sh ----

test_env_prefers_orc_set_by_the_caller() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    mkdir -p ../fake-orc/lib/src/main/bash/com/koreyhinton
    [[ "$(ORC="$(cd ../fake-orc && pwd)" bash -c '. ./orc-env.sh && echo "${ORC}"')" == "$(cd ../fake-orc && pwd)" ]] \
        || fail "ORC from the caller wasn't used"
}

test_env_finds_orc_on_path() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    [[ "$(bash -c '. ./orc-env.sh && echo "${ORC}|${NSMAP}"')" \
        == "${RN_RT}|${RN_RT}/lib/src/main/bash/com/koreyhinton/nsmap" ]] \
        || fail "got $(bash -c '. ./orc-env.sh && echo "${ORC}|${NSMAP}"')"
}

test_env_falls_back_to_orc_next_to_the_repo() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    ln -s "${RN_RT}" ../orc
    # a PATH without the cli; ORC is the resolved folder
    [[ "$(PATH=/usr/bin:/bin bash -c '. ./orc-env.sh && echo "${ORC}"')" == "${RN_RT}" ]] \
        || fail "got $(PATH=/usr/bin:/bin bash -c '. ./orc-env.sh && echo "${ORC}"')"
}

test_env_warns_when_it_falls_back() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    bash -c '. ./orc-env.sh' 2> err.txt || fail "orc-env.sh failed"
    grep -q "warning: ORC isn't set; using the orc on PATH" err.txt || fail "on PATH: $(cat err.txt)"
    ln -s "${RN_RT}" ../orc
    PATH=/usr/bin:/bin bash -c '. ./orc-env.sh' 2> err.txt || fail "orc-env.sh failed"
    grep -q "warning: ORC isn't set and orc isn't on PATH; using the orc next to this repo" err.txt || fail "next to it: $(cat err.txt)"
    grep -q "warning: orc isn't on PATH; add .* to PATH" err.txt || fail "no PATH warning: $(cat err.txt)"
}

test_env_is_quiet_when_orc_is_set_and_on_path() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    ORC="${RN_RT}" bash -c '. ./orc-env.sh' 2> err.txt || fail "orc-env.sh failed"
    [[ ! -s err.txt ]] || fail "warned: $(cat err.txt)"
    ORC="${RN_RT}" PATH=/usr/bin:/bin bash -c '. ./orc-env.sh' 2> err.txt || fail "orc-env.sh failed"
    [[ "$(cat err.txt)" == *"orc isn't on PATH"* && "$(cat err.txt)" != *"ORC isn't set"* ]] || fail "set but not on PATH: $(cat err.txt)"
}

test_env_leaves_no_helper_variables() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    [[ -z "$(ORC="${RN_RT}" bash -c '. ./orc-env.sh; compgen -v | grep ^orc_env')" ]] || fail "left orc_env_ variables"
}

test_env_without_orc_fails_the_build() {
    orc init --yes --ext c > /dev/null 2>&1 || fail "orc init failed"
    PATH=/usr/bin:/bin ./build.sh > out.txt 2>&1
    [[ $? -eq 1 ]] || fail "the build passed without orc"
    grep -q 'orc not found' out.txt || fail "no hint: $(cat out.txt)"
}

for RN_TEST in $(declare -F | awk '{print $3}' | grep '^test_'); do
    run_test "${RN_TEST}"
done

echo "${RN_PASSED} passed, ${RN_FAILED} failed"
if [[ ${#RN_SKIPPED[@]} -gt 0 ]]; then
    echo "not checked here:"
    printf '  %s\n' "${RN_SKIPPED[@]}"
fi
[[ ${RN_FAILED} -eq 0 ]]
