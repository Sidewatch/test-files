#!/usr/bin/env bash
#
# sample.sh - demonstrate common Bash constructs for syntax highlighting.

set -euo pipefail

# An ALL-UPPERCASE constant (Bash idiom) plus a readonly declaration.
readonly MAX_RETRIES=5
DEFAULT_TIMEOUT=30
LOG_PREFIX="[deploy]"

# A function definition.
retry_command() {
    local attempt=1
    local -i limit="$MAX_RETRIES"
    local message="starting"

    while (( attempt <= limit )); do
        echo "${LOG_PREFIX} attempt ${attempt} of ${limit}: ${message}"
        if "$@"; then
            return 0
        fi
        (( attempt++ ))
        sleep "$DEFAULT_TIMEOUT"
    done

    printf 'Failed after %d attempts\n' "$limit" >&2
    return 1
}

# Another function using a case statement and a type-ish declaration.
classify_status() {
    local code="${1:-0}"
    case "$code" in
        0)   echo "ok" ;;
        1|2) echo "warning" ;;
        *)   echo "error" ;;
    esac
}

main() {
    declare -a targets=("web" "api" "worker")

    for target in "${targets[@]}"; do
        # A function call.
        retry_command echo "Deploying ${target}"
        classify_status "$?"
    done
}

main "$@"
