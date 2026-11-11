# Probes

Remote snippets executed on the ODU by `scripts/adb-once.sh` (or by hand through
`adb shell`) during the short ADB window. They are plain shell, so they also
work when pasted into an interactive shell.

```sh
./scripts/adb-once.sh scripts/probes/51642-verify.probe
```

A snippet should end with `echo END`; the runner treats that as the completion
marker and retries inside the same window when adbd dies before it arrives.

Only one probe may run at a time. Two concurrent probes mount different volumes
on the same mountpoint and produce misleading `MOUNT_FAIL` results.

## Two recipes

| Probe | Effect |
|---|---|
| `51642-postdowngrade.probe` | **Writes** `build_type=debug` and the ACS/FOTA/heartbeat block. Backs up both files first. Idempotent. This is the one to run after a firmware install. |
| `51642-verify.probe` | Read-only. Mounts the system volume, prints the version files, backups and per-host `OK` / `MISS` for the blocklist. |

## Diagnostics

Read-only unless noted. Useful when a build does not match the documented
layout, or when a step fails and the reason matters.

| Probe | Answers |
|---|---|
| `51642-layout.probe` | Which MTD/UBI volumes exist, where `major_ver` and `hosts` live, which paths are writable. Fast enough for a 5 s window. |
| `51642-system-volume.probe` | Which volume is really the persistent system root; guarded `ubiattach`, no format or erase. |
| `51642-ubi1.probe` | Volume identification plus one rw mount of `ubi1_0` to prove writability. |
| `51642-volumes.probe` | Walks every ubi1 volume and reports which one holds `/etc/hosts` and `usr/etc/versions`. |
| `51642-buildtype.probe` | **Writes.** Flips `build_type` `perf` → `debug` and dumps what consumes it. |
| `51642-debug-state.probe` | Whether the `build_type` change stuck, and what it changed on the next boot. |
| `51642-ota-log.probe` | `/cache/recovery/last_log` install records and the updater surfaces. |
| `51642-updater.probe` | Firmware-update entry points on the system + cache volumes. |

## Boot race

adbd starts roughly 2.4 s before the UBI volumes finish attaching, so any probe
that mounts must wait for the node first:

```sh
i=0
while [ ! -e /dev/ubi1_0 ] && [ $i -lt 80 ]; do sleep 0.2; i=$((i + 1)); done
```

Then mount with retries — a single attempt can still land between `ubiattach`
and the first successful mount.
