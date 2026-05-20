# MX FFmpeg Automated Build System

This repository includes automated GitHub Actions workflows to build and release custom MX Player codec libraries.

## 🚀 Quick Start

### Automatic Builds (Scheduled)

The codec is automatically built when:
- Code is pushed to the `master` branch
- Files in the `ffmpeg/` directory change
- Daily scheduled rebuild (optional)

### Manual Builds

Trigger a manual build:
1. Go to **Actions** → **Manual Codec Build**
2. Click **Run workflow**
3. Select architectures and options
4. Click **Run workflow**

## 📋 Available Workflows

### 1. **build-codec.yml** - Automatic Build & Release
- **Trigger:** Push to `master`, pull requests, manual trigger
- **What it does:**
  - Builds FFmpeg libraries for all 4 architectures
  - Packages into a ZIP file
  - Creates a GitHub release with artifacts
  - Generates SHA256 checksums
- **Output:** 
  - Release ZIP file in GitHub Releases
  - Build logs as artifacts

### 2. **auto-merge.yml** - Upstream Synchronization
- **Trigger:** Daily at 2 AM UTC, manual trigger
- **What it does:**
  - Checks for updates from the upstream repository
  - Automatically merges new changes
  - Creates pull requests for conflicts
- **Configuration:**
  - Source: `USBhost/MX_FFmpeg`
  - Can be changed in workflow settings

### 3. **manual-build.yml** - On-Demand Build
- **Trigger:** Manual workflow dispatch
- **What it does:**
  - Build specific architectures only
  - Option for clean rebuild
  - Optional GitHub release creation
- **Architectures:**
  - armeabi-v7a (32-bit ARM)
  - arm64-v8a (64-bit ARM)
  - x86 (32-bit Intel)
  - x86_64 (64-bit Intel)

## 🏗️ Build Architectures

The automated system builds for 4 architectures:

| Architecture | Bit | Device Type |
|---|---|---|
| **armeabi-v7a** | 32-bit | Most Android phones (older) |
| **arm64-v8a** | 64-bit | Modern Android phones |
| **x86** | 32-bit | Android tablets, emulators |
| **x86_64** | 64-bit | High-end tablets, emulators |

## 📦 Release Structure

Automated releases include:

```
mx-ffmpeg-codec-[build-number].zip
├── libavcodec.so (all architectures)
├── libavformat.so
├── libavutil.so
├── libswscale.so
├── libswresample.so
├── libavfilter.so
├── libavdevice.so
├── libpostproc.so
├── libmp3lame.so (LAME encoder)
├── libssl.so (OpenSSL)
├── libcrypto.so
├── libxml2.so
├── libfribidi.so
├── And other codecs...
├── README.txt
├── BUILD_INFO.txt
└── MANIFEST.txt
```

## 🔄 Workflow Usage

### Check Build Status

1. Go to **Actions** tab in your GitHub repository
2. View active workflows and their status
3. Click on a workflow run for detailed logs

### Download Artifacts

1. Click on a completed workflow run
2. Scroll down to "Artifacts"
3. Download the ZIP file(s)

### Manual Trigger Example

```bash
# Using GitHub CLI
gh workflow run manual-build.yml \
  -f architectures="armeabi-v7a,arm64-v8a" \
  -f clean_build=true \
  -f create_release=true
```

## 🔧 Configuration

### Setting NDK Location

The workflows use the default Android NDK path. To customize:

Edit `.github/workflows/build-codec.yml`:
```yaml
ANDROID_NDK_ROOT: /path/to/ndk
```

### Changing Upstream Source

For auto-merge, edit `.github/workflows/auto-merge.yml`:
```yaml
SOURCE_REPO: 'your-org/your-repo'
SOURCE_BRANCH: 'develop'
```

### Schedule Changes

Edit the cron schedule in `auto-merge.yml`:
```yaml
schedule:
  - cron: '0 2 * * *'  # Daily at 2 AM UTC
  # Examples:
  # '0 * * * *'        # Every hour
  # '0 0 * * 0'        # Weekly on Sunday
  # '0 0 1 * *'        # Monthly on the 1st
```

## 📊 Monitoring Builds

### View Build Logs

1. **GitHub Actions Dashboard:**
   - Repository → Actions → Select workflow → Click run
   - Expand each job to see detailed logs

2. **Failed Builds:**
   - Check "Annotations" section for error details
   - Download logs from artifacts

### Build Status Badge

Add to your README:
```markdown
[![Build Status](https://github.com/khirendra03/MX_FFmpeg/actions/workflows/build-codec.yml/badge.svg)](https://github.com/khirendra03/MX_FFmpeg/actions/workflows/build-codec.yml)
```

## 🚨 Troubleshooting

### Build Fails

1. Check the workflow logs:
   - Actions → Select failed workflow → View logs
   
2. Common issues:
   - **NDK not found:** Update `ANDROID_NDK_ROOT` path
   - **Missing dependencies:** Re-run build, dependencies auto-install
   - **Disk space:** GitHub provides 14GB for builds

3. Manual debug:
   - Clone the repo
   - Follow the build steps in the workflow file
   - Check `ffmpeg/jni/build-*.log`

### Merge Conflicts

When auto-merge detects conflicts:
1. A PR is automatically created
2. Resolve conflicts manually
3. Merge the PR to update the branch

## 📝 Release Notes

Each automated release includes:
- Build timestamp
- Git commit hash
- List of included components
- Checksum for verification

### Verify Downloads

```bash
# After downloading the ZIP
sha256sum -c mx-ffmpeg-codec-*.zip.sha256

# Output should be:
# mx-ffmpeg-codec-1234567890.zip: OK
```

## 🔐 Security

- All workflows use GitHub's default permissions
- No secrets or credentials are stored in workflows
- Artifacts are automatically cleaned after retention period
- SHA256 checksums prevent tampering

## 📚 Additional Resources

- **MX Player Documentation:** https://sites.google.com/site/mxvpen/ffmpeg
- **FFmpeg Project:** https://ffmpeg.org
- **GitHub Actions Docs:** https://docs.github.com/en/actions
- **Android NDK:** https://developer.android.com/ndk

## ⚠️ Notes

- Builds typically take 20-30 minutes per architecture
- GitHub Actions provides 2,000 free minutes per month
- Artifacts are stored for 90 days by default
- Older releases can be deleted to save storage

---

**Need help?** Check GitHub Actions logs or create an issue in the repository.
