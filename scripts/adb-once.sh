#!/bin/bash
# adb-once.sh — run a shell snippet on the next short ADB window, once.
#
#   ./scripts/adb-once.sh scripts/probes/51642-layout.probe
#   SERIAL=afb84a10 ./scripts/adb-once.sh some.probe
#
# Exits 0 when the snippet returned cleanly, 3 on timeout.
# Output is echoed and appended to logs/adb-once-<name>.log.

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
LOG_DIR="$REPO_DIR/logs"

SNIPPET="${1:-}"
[ -n "$SNIPPET" ] || { echo "usage: $0 <remote-snippet-file>" >&2; exit 2; }
[ -f "$SNIPPET" ] || { echo "no such snippet: $SNIPPET" >&2; exit 2; }

NAME=$(basename "$SNIPPET")
NAME=${NAME%.probe}
NAME=${NAME%.sh}
LOG_FILE="$LOG_DIR/adb-once-$NAME.log"

POLL="${POLL:-0.2}"
SHELL_TIMEOUT="${SHELL_TIMEOUT:-25}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-900}"
SERIAL="${SERIAL:-}"

mkdir -p "$LOG_DIR"
: >> "$LOG_FILE"
START=$(date +%s)

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }
with_timeout() { perl -e 'alarm shift; exec @ARGV' "$@" 2>/dev/null; }

BODY=$(cat "$SNIPPET")

log "runner start snippet=$SNIPPET serial=${SERIAL:-any}"

last=""
while :; do
  dev=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}')
  off=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="offline"{print $1; exit}')

  if [ -n "$dev" ]; then cur="device:$dev"
  elif [ -n "$off" ]; then cur="offline:$off"
  else cur="absent"; fi

  if [ "$cur" != "$last" ]; then
    log "[$cur]"
    last="$cur"
  fi

  case "$cur" in
    device:*)
      ser=${cur#device:}
      log "RUN $ser"
      out=$(with_timeout "$SHELL_TIMEOUT" adb -s "$ser" shell "$BODY" 2>&1)
      printf '%s\n' "$out" | sed 's/^/    /' | tee -a "$LOG_FILE"
      case "$out" in
        *END*)
          log "OK (snippet reached END)"
          exit 0
          ;;
        *)
          log "incomplete output - adbd likely died mid-flight; waiting for next window"
          ;;
      esac
      ;;
  esac

  if [ $(( $(date +%s) - START )) -gt "$WAIT_TIMEOUT" ]; then
    log "timeout after ${WAIT_TIMEOUT}s"
    exit 3
  fi
  sleep "$POLL"
done
