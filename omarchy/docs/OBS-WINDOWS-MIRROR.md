# OBS Settings — Windows 11 Mirror

Target: Windows 11 gaming rig, RTX 40-series, 4K display
Purpose: match the Linux (Omarchy) OBS configuration for identical 1440p60 footage
Reference: see `OBS-SETUP.md` for the Linux-side config and reasoning

## Video

| Setting | Value |
|---|---|
| Base (Canvas) Resolution | 3840x2160 |
| Output (Scaled) Resolution | 2560x1440 |
| Downscale Filter | **Bicubic** |
| FPS | 60 |

## Recording (Encoder)

| Setting | Value |
|---|---|
| Video Encoder | **NVIDIA NVENC HEVC** |
| Rate Control | **CQP 22** |
| Keyframe interval | 0 (auto) |
| Preset | **P5: Slow (Good Quality)** |
| Tuning | High Quality |
| Multipass Mode | Two Passes (Quarter Resolution) |
| Profile | main |
| Look-ahead | **OFF** |
| Adaptive Quantization | ON (Windows label: "Psychovisual Tuning" / AQ) |
| B-Frames | 2 |

## Output / Format

| Setting | Value |
|---|---|
| Recording Format | **Matroska (.mkv)** + auto-remux to MP4 (Windows alternative: "Hybrid MP4") |
| Audio Encoder | FFmpeg AAC, **192 kbps**, Track 1 only |
| Recording Path | Videos folder |
| Replay Buffer | **300s max, 8192 MB cap** |

## Platform Differences (Windows vs the Linux setup)

1. **Game Capture:** Windows OBS's built-in **Game Capture** hooks games natively —
   **no launch options, no env vars, no plugins.** Add the source, leave it on
   "Capture any fullscreen application" (or specific window). Everything done with
   `obs-vkcapture` / `OBS_VKCAPTURE=1` on Linux was a Wayland workaround only.
2. **Audio:** Use built-in **Application Audio Capture (WASAPI)** — the native equivalent
   of Linux's PipeWire app capture. Pick the game exe; Discord/browser audio stays out.
3. **Remux habit:** File → Remux Recordings (MKV → MP4) before handing files to
   ScreenFlow on the Mac. Same on both platforms.

## Rules That Apply on Both Machines

- **Lower CQP = higher quality, bigger files.** Footage soft? Drop toward 20.
  Files ballooning? Raise toward 24.
- **Changing the encoder resets rate control to CBR 10,000 Kbps** — after ANY encoder
  change, re-verify: CQP 22, Look-ahead off.
- Expected size: **~25–40 GB/hour** at 1440p60 CQP 22 on detail-heavy games.
  Sudden doubling = rate control got reset to CBR.
- Keep games rendering at 4K (DLSS/FSR); OBS does the single clean Bicubic
  4K → 1440p downscale.
- Expected result: footage indistinguishable between the two machines — identical
  1440p60 HEVC output.
