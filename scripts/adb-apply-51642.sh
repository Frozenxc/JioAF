#!/bin/bash
# adb-apply-51642.sh — idempotent apply of the 51642 downgrade + ACS block
# during each short ADB window.
#
#   window 1 -> major_ver = 0        (downgrade prep)
#   window 2 -> /etc/hosts blocklist (ACS / FOTA / heartbeat)
#   window 3 -> verification only
#
# This is the standalone watcher: it scans every volume on `UBI_DEV` and picks
# the one that actually contains usr/etc/versions or etc/hosts, so it does not
# depend on UBI numbering. For the post-install re-apply (persist ADB + block
# on the freshly installed rootfs) scripts/probes/51642-postdowngrade.probe is
# the shorter path.
#
# Handles the boot race: adbd starts ~2.5 s BEFORE the system UBI device
# finishes attaching, so the payload waits for the volume node instead of
# guessing. Never formats, erases, detaches, or creates volumes.
#
#   ./scripts/adb-apply-51642.sh
#   SERIAL=afb84a10 ./scripts/adb-apply-51642.sh
#   UBI_DEV=1 VOLS="0 1 2 3 4" ./scripts/adb-apply-51642.sh

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
HOST_FILE="$REPO_DIR/configs/acs-blocklist.hosts"
LOG_DIR="$REPO_DIR/logs"
LOG_FILE="$LOG_DIR/adb-apply-51642.log"

UBI_DEV="${UBI_DEV:-1}"
VOLS="${VOLS:-0 1 2 3 4}"
SERIAL="${SERIAL:-}"
POLL="${POLL:-0.2}"
SHELL_TIMEOUT="${SHELL_TIMEOUT:-30}"
ATTACH_WAIT="${ATTACH_WAIT:-80}"   # x0.2s = 16s ceiling

mkdir -p "$LOG_DIR"
: >> "$LOG_FILE"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }
with_timeout() { perl -e 'alarm shift; exec @ARGV' "$@" 2>/dev/null; }

[ -f "$HOST_FILE" ] || { echo "missing blocklist: $HOST_FILE" >&2; exit 1; }
HOSTS=$(awk '!/^[[:space:]]*#/ && NF >= 2 { print $2 }' "$HOST_FILE" | tr '\n' ' ')

read -r -d '' PAYLOAD <<'REMOTE'
DEV=__UBI_DEV__
VOLS="__VOLS__"
WAIT=__ATTACH_WAIT__
HOSTS="__HOSTLIST__"

echo "WHOAMI:$(id -u 2>/dev/null)"
echo "CMDLINE_RECOVERY:$(grep -o 'boot_into_recovery=[01]' /proc/cmdline 2>/dev/null)"

i=0
while [ ! -e "/dev/ubi${DEV}_0" ] && [ $i -lt $WAIT ]; do
  sleep 0.2
  i=$((i + 1))
done
echo "ATTACH_WAIT_MS=$((i * 200))"
if [ ! -e "/dev/ubi${DEV}_0" ]; then
  echo "RESULT:NO_UBI_DEVICE"
  echo "NODES:"; ls -l /dev/ubi* 2>&1
  echo "MOUNTS:"; mount 2>&1 | grep -i ubi
  echo "END"
  exit 0
fi

TARGET=""
TVOL=""
for n in $VOLS; do
  d="/tmp/ubi_apply_$n"
  mkdir -p "$d" 2>/dev/null
  if mount -t ubifs -o rw,bulk_read "/dev/ubi${DEV}_$n" "$d" 2>/dev/null; then
    TOP=$(ls "$d" 2>/dev/null | tr '\n' ' ')
    echo "VOL ubi${DEV}_$n mounted: $TOP"
    if [ -z "$TARGET" ]; then
      if [ -d "$d/usr/etc/versions" ] || [ -f "$d/etc/hosts" ]; then
        TARGET="$d"
        TVOL="ubi${DEV}_$n"
        echo "RESULT:TARGET_VOLUME=$TVOL"
        break
      fi
    fi
    if [ "$d" != "$TARGET" ]; then
      umount "$d" 2>/dev/null
    fi
  else
    echo "VOL ubi${DEV}_$n mount-failed"
  fi
done

if [ -z "$TARGET" ]; then
  echo "RESULT:NO_CONFIG_VOLUME"
  echo "END"
  exit 0
fi

V="$TARGET/usr/etc/versions/major_ver"
H="$TARGET/etc/hosts"
CUR=$(tr -d ' \r\n' < "$V" 2>/dev/null)
echo "MAJOR_VER_BEFORE=${CUR:-absent}"

if [ -n "$CUR" ] && [ "$CUR" != "0" ]; then
  [ -f "$V.bak" ] || cp "$V" "$V.bak"
  printf '0\n' > "$V"
  echo "MAJOR_VER_AFTER=$(tr -d ' \r\n' < "$V")"
  echo "ACTION:SET_MAJOR_VER"
elif [ -f "$H" ]; then
  echo "HOSTS_BEFORE:"; head -12 "$H" 2>&1
  [ -f "$H.bak" ] || cp "$H" "$H.bak"
  ADDED=0
  for h in $HOSTS; do
    if grep -qE "[[:space:]]$h\$" "$H" 2>/dev/null; then
      :
    else
      echo "127.0.0.1 $h" >> "$H"
      ADDED=$((ADDED + 1))
    fi
  done
  echo "HOSTS_ADDED=$ADDED"
  echo "HOSTS_BLOCKED_TOTAL=$(grep -cE '^127\.0\.0\.1' "$H" 2>/dev/null)"
  echo "HOSTS_AFTER:"; grep -E 'jio|fota|heartbeat|jfdca|jpdc' "$H" 2>/dev/null
  echo "ACTION:BLOCK_HOSTS"
else
  echo "ACTION:NOTHING_TO_DO"
fi

sync
cd / 2>/dev/null
umount "$TARGET" 2>&1 && echo "UMOUNT_OK" || echo "UMOUNT_FAIL:$TARGET"
echo "DONE"
echo "END"
REMOTE

PAYLOAD=${PAYLOAD//__UBI_DEV__/$UBI_DEV}
PAYLOAD=${PAYLOAD//__VOLS__/$VOLS}
PAYLOAD=${PAYLOAD//__ATTACH_WAIT__/$ATTACH_WAIT}
PAYLOAD=${PAYLOAD//__HOSTLIST__/$HOSTS}

log "apply start serial=${SERIAL:-any} ubi_dev=$UBI_DEV vols='$VOLS' hosts=$(echo "$HOSTS" | wc -w | tr -d ' ')"

last=""
fired=0
tries=0
while :; do
  dev=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1; exit}')
  off=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="offline"{print $1; exit}')
  if [ -n "$dev" ]; then cur="device:$dev"
  elif [ -n "$off" ]; then cur="offline:$off"
  else cur="absent"; fi

  if [ "$cur" != "$last" ]; then
    log "[$cur]"
    last="$cur"; fired=0; tries=0
  fi

  case "$cur" in
    device:*)
      ser=${cur#device:}
      if [ "$fired" = "0" ] && [ "$tries" -lt 3 ]; then
        fired=1; tries=$((tries + 1))
        log "FIRE $ser (attempt $tries)"
        out=$(with_timeout "$SHELL_TIMEOUT" adb -s "$ser" shell "$PAYLOAD" 2>&1)
        printf '%s\n' "$out" | sed 's/^/    /' | tee -a "$LOG_FILE"
        case "$out" in
          *"ACTION:SET_MAJOR_VER"*) log ">>> major_ver=0 written. POWER-CYCLE NOW." ;;
          *"ACTION:BLOCK_HOSTS"*)   log ">>> hosts block written ("$(printf '%s' "$out" | grep -o 'HOSTS_ADDED=[0-9]*' | head -1)"). Reboot and verify." ;;
          *"ACTION:NOTHING_TO_DO"*) log ">>> major_ver already 0 and hosts already complete." ;;
          *"RESULT:NO_UBI_DEVICE"*) log "!!! ubi${UBI_DEV} never appeared in this window." ;;
          *"RESULT:NO_CONFIG_VOLUME"*) log "!!! no volume had usr/etc/versions or etc/hosts." ;;
        esac
        case "$out" in
          *END*) : ;;
          *) log "no END marker - truncated; retrying this window"; fired=0; sleep 1 ;;
        esac
      fi
      ;;
    *) fired=0 ;;
  esac
  sleep "$POLL"
done
