# Jio AirFiber ODU Unlock and Firmware Guides

Community-maintained model-specific guides for Jio AirFiber ODU devices (JODU51641, JODU51642, JODU52041, JODU52140, JODU52240, and JODU52540). This repository documents local access, firmware recovery and downgrade, ACS configuration, and companion-app/eSIM workflows. Here, “unlock” refers to documented ODU access and firmware procedures, not carrier or SIM unlocking.

> [!IMPORTANT]
> Application credit: HONEY ([@H0NEYJI](https://t.me/H0NEYJI))
>
> Disclaimer: This project is provided for educational, authorized device-management, and legitimate research purposes only. Use it only on devices you own or are explicitly authorized to modify. Do not use this software or any related procedures to interfere with third-party systems, bypass controls, access unauthorized networks, or cause harm to people, property, or services. Always verify the exact model before flashing, and comply with all applicable local laws, manufacturer requirements, and service agreements. The maintainers provide this repository as-is without warranty and are not responsible for misuse, loss, or damage caused by improper use.
>
> Warning: Flashing an incorrect image or interrupting a firmware write can brick the device.

## Supported models

| Model | Access / update method | Guide |
|---|---|---|
| JODU51641 | USB-C → Fastboot → recovery/recoveryfs → ADB shell → downgrade → ACS block | [51641 / 51642](docs/models/51641-51642.md) |
| JODU51642 | USB-C → Fastboot → recovery/recoveryfs → ADB shell → downgrade → ACS block | [51641 / 51642](docs/models/51641-51642.md) |
| JODU52041 | WebUI firmware update | [52041](docs/models/52041.md) |
| JODU52140 | UART shell → post-boot setup → SSH → ACS/CWMP/heartbeat changes | [52140](docs/models/52140.md) |
| JODU52240 | WebUI firmware update | [52240](docs/models/52240.md) |
| JODU52540 | WebUI firmware update; UART fallback can restore WebUI; persistent ACS-off workflow | [52540](docs/models/52540.md) |

## Android ODU companion app

The Android app is reported to support nearby ODU discovery and eSIM/device-management features. Download the APK from [this external link](https://files.catbox.moe/e8181l.apk); the APK is not stored in this repository. See [the app guide](docs/odcpe-app.md) for setup, compatibility notes, and safe-use guidance.

## Repository layout

```text
JIOAF/
├── README.md
├── LICENSE
├── THIRD_PARTY.md
├── configs/
│   └── acs-blocklist.hosts
├── devices/
│   ├── 51641/
│   ├── 51642/
│   ├── 52041/
│   └── 52140/
├── docs/
│   ├── models/
│   └── legacy/
├── scripts/
│   └── generate-checksums.sh
└── tools/
    └── fake_sbin/
```

## 51641 / 51642 overview

1. Install ADB and Fastboot utilities.
2. Connect the ODU over USB-C.
3. Run `fastboot devices`.
4. Press/hold reset until the ODU is detected in Fastboot.
5. Extract the matching model package.
6. Flash the supplied recovery and recoveryfs images.
7. Reboot/reset as required and run the supplied ADB helper.
8. Obtain the shell.
9. Mount the model-specific persistent UBIFS volume.
10. Set `major_ver` to `0` for the documented downgrade flow.
11. Add the ACS/FOTA/heartbeat hostname blocklist.

**Persistent UBIFS volumes used by the supplied notes:**

- JODU51641: `/dev/ubi2_0`
- JODU51642: `/dev/ubi1_0`

See [the full guide](docs/models/51641-51642.md).

## 52041 / 52240 / 52540 overview

These models use the WebUI firmware-update workflow documented in their model guides. Always use firmware intended for the exact model and do not interrupt power during flashing.

## 52140 overview

Initial access is through UART.

Project-documented shell password:

```text
oelinux123
```

The workflow then installs/uses the supplied post-boot/Dropbear files and edits the persistent ACS/CWMP/heartbeat configuration, including ACS server links and ACS authentication username/password values.

See [the 52140 guide](docs/models/52140.md).

## ACS / heartbeat blocklist

The shared blocklist is maintained in:

```text
configs/acs-blocklist.hosts
```

## Firmware links retained from the original project

- **51641:** https://mega.nz/file/fR9BnQ6B#WVnFp1jl30lwkedAZ0jBxuslY8dH4EQIwRldCAoyuxU
- **51642:** https://mega.nz/file/qUUl3bRY#D0I3uPM_a_uxkVbo0f75bXPpgFsz15qc8Dqas_dxHRo
- **52240:** https://gofile.io/d/O8tz9cfA
- **52540:** https://gofile.io/d/lJ0PaRWO

External links can expire or change. Prefer publishing SHA-256 checksums alongside firmware files.

## Credits

See [CREDITS.md](CREDITS.md) for full model-by-model attribution.

- **51641:** 2.68 KB/S ([@Daaru_Chakhna](https://t.me/Daaru_Chakhna))
- **51642:** 2.68 KB/S ([@Daaru_Chakhna](https://t.me/Daaru_Chakhna)), Richard Dawkins ([@RichardDawkinsIN](https://t.me/RichardDawkinsIN))
- **52041:** HONEY ([@H0NEYJI](https://t.me/H0NEYJI))
- **52140:** Bluenecko, HONEY ([@H0NEYJI](https://t.me/H0NEYJI)), 2.68 KB/S ([@Daaru_Chakhna](https://t.me/Daaru_Chakhna))
- **52240 / 52540:** HONEY ([@H0NEYJI](https://t.me/H0NEYJI))

## License

Original repository documentation and scripts are released under the [MIT License](LICENSE).

Firmware, recovery images, vendor packages, and third-party binaries are not relicensed by this repository. See [THIRD_PARTY.md](THIRD_PARTY.md).
