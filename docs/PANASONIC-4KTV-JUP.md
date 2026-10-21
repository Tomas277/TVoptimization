# Case study: Panasonic 4KTV-JUP

A real run of this toolkit, with what worked and what didn't. Use it as a guide
for your own TV, but check your own `00_detect.sh` report before copying anything.

| | |
|---|---|
| Model | Panasonic 4KTV-JUP (`Jupiter_EU`, MediaTek SoC) |
| Android | 11 (SDK 30), firmware 3.501, security patch 2024-03 |
| RAM | 1.7 GB (+512 MB swap), 4 cores |
| Storage | ~11.5 GB `/data` |
| Launcher | Panasonic "my Home Screen"; owner uses a third-party launcher |

## What this TV looks like

- The TV core is **MediaTek**: tuner, inputs and TV center are `com.mediatek.*`.
  The Panasonic bits are the home screen, quick menu and control panel.
  Neither is a `com.panasonic.avc.*` package, so the original profile guess was
  wrong. `profiles/panasonic.conf` now protects the real names.
- Google's own launcher (`com.google.android.tvlauncher`) was already disabled
  by the owner, and UK Freeview helper apps (`uk.co.freeview.*`) too.
- Memory is the bottleneck. After boot almost all RAM is in use and swap fills
  up. The kernel reports a nonsense `MemAvailable` (21 billion kB), so tools
  that rely on it look wrong; use `MemFree` + `Cached` instead.

## What was done

1. `00_detect.sh` + `01_backup.sh` (read-only).
2. Removed four unused system apps with `02_debloat.sh`:
   `com.panasonic.demomode`, `com.google.android.backdrop`,
   `com.google.android.partnersetup`, `com.google.android.onetimeinitializer`.
   No problems after a restart: live TV, HDMI inputs and apps all worked.
3. `03_tweaks.sh`: animation scales 0.5, ad-tracking limit, Private DNS
   (AdGuard), background Wi-Fi/Bluetooth scanning off. Frees about 350 MB of
   cache via `04_cleanup.sh`.
4. `05_background.sh`: denied background running for nine streaming apps.
   Nothing uninstalled. About 270 MB of RAM was freed right away.
5. Hid the Watch Next row in the third-party launcher (its channel settings).
   The home screen looks lighter; this did **not** reduce the launcher's own
   memory.
6. Force-stopped idle apps once. Freed about 160 MB, and some came back.

## Results

Measured 2 minutes after a reboot. Before = first restart, after the first batch.

| | Before | After |
|---|---|---|
| In use | 1,679 MB | 1,605 MB |
| Free | ~58 MB | 132 MB |
| Swap in use | 157 MB | ~89 MB |
| Cached (reclaimable) | 427 MB | 588 MB |

A modest gain. A 1.7 GB TV stays tight; software tweaks only go so far.

## Things that didn't go as expected

- **`am start -a android.settings.PRIVACY_SETTINGS` opened the factory reset
  page** (`com.android.tv.settings/.device.storage.ResetActivity`). Nothing was
  reset because the page needs confirmation, and Back left it. **Don't use
  settings intents on Panasonic TVs.** Navigate the menu by hand.
- **`adb shell` swallowed the package list.** Run in a `while read` loop, it
  consumed stdin, so only the first package was processed. Fixed in `lib.sh`
  (`tv()` now detaches stdin). This affected any script that loops over a file.
- **The animator scale resets to 0.6 on reboot**, so something on the TV
  rewrites it. The other settings survived the reboot.
- **Netflix preloads at boot** (~175 MB) regardless of the background
  restriction, via `com.mstar.netflixobserver`. A music app was left
  unrestricted on purpose so audio keeps playing.
- **Some apps came back after being force-stopped** (e.g. the Google TV app),
  so a force-stop only helps until they are next opened.
- **`dumpsys meminfo` times out** on this TV. Use `top -b -n 1` and
  `ps -A -o RSS,NAME | sort -rn`.
- **Load average sits around 60** right after boot even when the CPU is ~70%
  idle. It looks like a vendor-kernel quirk, not overload.

## Screenshots over ADB

`adb exec-out screencap -p` prints a few debug lines before the PNG on this
TV, so the file won't open. Strip everything before the `\x89PNG` signature.

## Things worth trying that ADB can't do

- Developer options → **Background process limit** (e.g. "At most 3").
  Settable on the TV only; its effect on this TV wasn't measured.
- Play Store auto-updates off.
- Panasonic and Google privacy menus (usage & diagnostics, ACR).
