# MX Player Custom FFmpeg Codec

A custom FFmpeg codec library for MX Player with automated build system.

## ⚠️ Important Notice

**Amazon is no longer updating MX Player.** For continued development and updates, consider using:
- **[mpv-android](https://github.com/mpv-android/mpv-android/releases)** - Modern, actively maintained video player

This repository maintains a fork of the original MX Player FFmpeg codec for those still using the legacy player.

---

## 🚀 Quick Start

### Automated Build System

This repository includes **GitHub Actions workflows** for completely automated builds!

#### Option 1: Automatic Builds
Simply push code to `master` branch → Automatic build starts!

#### Option 2: Manual Trigger
1. Go to **Actions** tab → **Manual Codec Build**
2. Click **Run workflow**
3. Select architectures and options
4. Download ZIP from artifacts/releases

#### Option 3: Upstream Sync
1. Go to **Actions** → **Sync Upstream**
2. Automatically pulls latest changes from source

**👉 See [BUILD_AUTOMATION.md](BUILD_AUTOMATION.md) for detailed setup guide**

---

## 🏗️ Manual Build Instructions

### Prerequisites

- **Android NDK** installed
- **Build tools** for your platform (Make, GCC, etc.)
- **Git** for version control

### Build All Architectures

```bash
cd ffmpeg/jni
# Edit ENV file with your NDK location
nano ENV
# Then run the build script
./rebuild-ffmpeg.sh
```

### Build Specific Architecture

```bash
cd ffmpeg/jni
# Edit ENV with your NDK location
nano ENV
# Build for specific architecture
./build-ffmpeg.sh armeabi-v7a    # 32-bit ARM
./build-ffmpeg.sh arm64-v8a      # 64-bit ARM
./build-ffmpeg.sh x86            # 32-bit Intel
./build-ffmpeg.sh x86_64         # 64-bit Intel
```

### Build Output

Libraries will be generated in:
```
ffmpeg/jni/build/[architecture]/lib/
```

---

## 📋 What's Included

### Core FFmpeg Libraries
- `libavcodec.so` - Video/audio codecs
- `libavformat.so` - Container formats
- `libavutil.so` - Utility functions
- `libswscale.so` - Image scaling
- `libswresample.so` - Audio resampling
- `libavfilter.so` - Audio/video filters
- `libavdevice.so` - Device support
- `libpostproc.so` - Post-processing

### Additional Codecs & Libraries
- `libmp3lame.so` - MP3 encoding (LAME)
- `libssl.so` + `libcrypto.so` - OpenSSL encryption
- `libxml2.so` - XML parsing
- `libfribidi.so` - Bidirectional text support
- `libfreetype.so` - Font rendering
- `libfontconfig.so` - Font configuration

### Supported Formats

**Video Codecs:**
- H.264, H.265 (HEVC), VP8, VP9, AV1
- MPEG-2, MPEG-4, Theora, Dirac
- And 50+ more

**Audio Codecs:**
- AAC, MP3, Vorbis, FLAC
- Opus, DTS, AC-3, E-AC-3
- And 30+ more

**Containers:**
- MP4, MKV, AVI, MOV, WebM
- FLV, TS, WAV, AIFF
- And 40+ more

---

## 📊 Architecture Targets

| Architecture | Bit | Devices |
|---|---|---|
| **armeabi-v7a** | 32-bit | Older Android phones |
| **arm64-v8a** | 64-bit | Modern Android phones |
| **x86** | 32-bit | Android tablets, emulators |
| **x86_64** | 64-bit | High-end tablets, emulators |

---

## 🔧 Configuration

### ENV File Settings

Edit `ffmpeg/jni/ENV`:

```bash
# Set your NDK path
export ANDROID_NDK_ROOT="/path/to/android-ndk"

# Optimization flags
export CFLAGS="-O3"

# Target API level
export ANDROID_API_LEVEL=21
```

### Build Customization

Edit `ffmpeg/jni/build-ffmpeg.sh` to:
- Enable/disable specific codecs
- Change optimization levels
- Add/remove libraries
- Modify compilation flags

---

## 📚 Resources

- **[MX Player FFmpeg Info](https://sites.google.com/site/mxvpen/ffmpeg)** - Original documentation
- **[FFmpeg Project](https://ffmpeg.org)** - FFmpeg official site
- **[Android NDK Guide](https://developer.android.com/ndk)** - Android Native Development Kit
- **[mpv-android Alternative](https://github.com/mpv-android/mpv-android)** - Modern video player

---

## 🤖 GitHub Actions Automation

### Available Workflows

1. **build-codec.yml** - Auto-build on push
2. **auto-merge.yml** - Daily upstream sync
3. **manual-build.yml** - On-demand builds

### Workflow Features

✅ Multi-architecture parallel builds  
✅ Automatic GitHub releases  
✅ SHA256 verification checksums  
✅ Build artifacts with logs  
✅ Upstream synchronization  
✅ Manual trigger options  

**Full documentation:** [BUILD_AUTOMATION.md](BUILD_AUTOMATION.md)

---

## 📦 Release Downloads

Latest builds available in [GitHub Releases](https://github.com/khirendra03/MX_FFmpeg/releases)

Each release includes:
- Compiled `.so` libraries for all architectures
- README with build information
- Manifest with library list
- SHA256 checksums

---

## ⚖️ License

This project is a fork of the original MX Player FFmpeg codec. Please see individual component licenses:

- **FFmpeg** - LGPL 2.1+
- **LAME** - LGPL 2+
- **OpenSSL** - Apache 2.0 / OpenSSL License
- **libxml2** - MIT
- **FriBidi** - LGPL 2.1+

---

## 🐛 Issues & Contributions

- **Report issues:** [GitHub Issues](https://github.com/khirendra03/MX_FFmpeg/issues)
- **Pull requests:** Contributions welcome!
- **Discussions:** [GitHub Discussions](https://github.com/khirendra03/MX_FFmpeg/discussions)

---

## 📝 Notes

- This is a **legacy project** - MX Player is no longer maintained by Amazon
- For active development, consider **mpv-android** or other maintained players
- Builds typically take 20-30 minutes per architecture
- GitHub Actions provides free build minutes

---

**Last Updated:** May 2026  
**Original Source:** [MX Player GitHub](https://github.com/MXVideoPlayer/MX-FFmpeg)  
**Original Documentation:** [MX FFmpeg Wiki](https://sites.google.com/site/mxvpen/ffmpeg)
