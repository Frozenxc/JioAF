# ODU Companion App

The APK is available from [this external download link](https://files.catbox.moe/e8181l.apk); it is not stored in this repository. This guide describes the capabilities reported for the app and records what is not yet verified. The APK is a binary artifact; Android application source code is not included in this repository. The link's publisher, APK contents, and signature have not been independently verified. Only download and install it if you trust the source and are authorized to use it.

## Reported capabilities

The app is reported to support these operations on Jio AirFiber ODU devices:

| Area | Reported capability |
|---|---|
| Device discovery | Scan for nearby ODU devices |
| eSIM | Add and manage an eSIM profile |
| Device information | View the current profile and EID |
| Network information | View serving tower and signal details |
| Profile control | Enable or disable a profile |
| Device control | Reboot the ODU |

These are user-reported capabilities, not a feature audit. Exact screens, permissions, and operation sequences have not been independently documented here.

## Firmware compatibility

The app is reported to work across ODU models. Some features are also reported to work on older firmware, but the model, firmware versions, and feature-by-feature results are not yet recorded. Do not assume every operation works on every firmware version. Check the target ODU and firmware, and verify each operation independently before relying on it.

| Compatibility item | Current information |
|---|---|
| ODU model coverage | Reported to work across ODU models; no independent test matrix is available |
| Older firmware | Some features reportedly work; exact versions and features are unknown |
| Minimum Android version | Not documented |
| App version and package identifier | Not documented in this repository |

## Install and verify

Only install the APK if you trust its source and are authorized to use it. Android may require permission to install an APK from the app used to open it; allow this only for the trusted source and disable the permission afterward if it is no longer needed.

After downloading, you can calculate a local SHA-256 digest with:

```sh
sha256sum odcpe.apk
```

No independently verified digest is available for the externally hosted APK. A digest calculated from a download can help identify that local copy, but does not prove who published or signed it.

## Using the app

The exact app workflow and labels are not documented. Use the app's on-screen prompts, and verify the ODU model and firmware before changing a profile or rebooting.

1. Power on the ODU and use the app's device scan to find the intended unit.
2. Confirm that the discovered device is the ODU you are authorized to manage.
3. Review the current profile, EID, tower, and signal information as needed.
4. Add an eSIM only with a valid activation method from the carrier or profile provider.
5. Confirm the selected profile before enabling or disabling it. Profile changes can interrupt connectivity.
6. Reboot only when needed; the ODU and app connection will be unavailable while it restarts.

Nearby-device permissions and network requirements can vary by Android version and app implementation. Grant only permissions needed for the requested operation. Do not assume the phone and ODU must use a particular network unless the app indicates that requirement.

## Privacy and operational safety
## Adding an eSIM to an ODU

The exact app screens have not been verified, so labels may differ. Use the app's own prompts and the carrier's activation instructions throughout this process.

1. Confirm that the ODU model and installed firmware support eSIM profile installation. Make sure the app can discover and connect to the intended ODU.
2. In the app's device information, find the ODU's EID. Give it to the carrier or profile provider only through a trusted channel so they can issue a profile for that device.
3. Obtain the carrier-issued eSIM activation method, such as a QR code or manual activation details. Confirm that the plan is supported for the ODU and that the profile has not already been used.
4. In the app's eSIM or profile management area, choose the add/download profile action and follow the offered flow to scan or enter the carrier's activation details. Do not share or save activation details in public logs, screenshots, or repository files.
5. Keep the ODU powered and the app connected while the profile is being downloaded. Wait for the app to report completion, then check that the new profile appears in the profile list.
6. Enable or select the new profile only when ready. Keep a working profile enabled until the new one is confirmed active, unless the carrier's instructions say otherwise; changing profiles can interrupt service.
7. Check the ODU's network registration, signal, and data connection. If activation fails, verify the EID and carrier instructions before retrying. Some activation codes are single-use, so contact the carrier before reusing one.

If the app cannot find an add-profile action or its screens differ, do not guess at firmware commands. Record the ODU model, firmware version, app version, and non-sensitive error text, then consult the carrier or device maintainer.

## Privacy and operational safety

- Use the app only with devices and eSIM profiles you own or are authorized to manage.
- Treat the EID, eSIM activation codes, profile credentials, and device screenshots as sensitive. Redact them before sharing logs, screenshots, or support requests.
- Enabling or disabling a profile may interrupt service. Confirm the intended profile and make sure you have a way to regain access before proceeding.
- A reboot interrupts service temporarily. Do not reboot during a firmware update or other maintenance operation.
- This APK guide does not authorize firmware changes. Follow the matching model guide for firmware procedures, and never apply firmware intended for another model.

## Known documentation gaps

This repository does not include Android source code, a verified app version history, a tested Android-version range, or a model/firmware/feature compatibility matrix. Record future tests with the exact ODU model, firmware version, APK checksum or version, Android version, operation, and result. Avoid recording activation codes or other secrets.