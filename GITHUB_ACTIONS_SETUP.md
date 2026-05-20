# GitHub Actions Automation Setup

This guide provides complete, ready-to-use GitHub Actions workflows for automated FFmpeg codec building and releasing.

## 🚀 Quick Setup (3 Steps)

### Step 1: Create `.github/workflows/` directory
If it doesn't exist, create the `.github/workflows/` directory in your repository root.

### Step 2: Create the workflow files

Copy the YAML files from this guide into `.github/workflows/`:
- `build-codec.yml`
- `auto-merge.yml`
- `manual-build.yml`

### Step 3: Push to GitHub

```bash
git add .github/workflows/
git commit -m "Add GitHub Actions workflows for automated builds"
git push origin master
```

Done! ✅ Your automation is now active.

---

## 📋 Workflow 1: Automated Build & Release

**File:** `.github/workflows/build-codec.yml`

```yaml
name: Build MX FFmpeg Codec

on:
  push:
    branches:
      - master
      - main
    paths:
      - 'ffmpeg/**'
      - '.github/workflows/build-codec.yml'
  pull_request:
    branches:
      - master
      - main
  workflow_dispatch:
    inputs:
      architectures:
        description: 'Architectures to build (comma-separated: armeabi-v7a, arm64-v8a, x86, x86_64)'
        required: false
        default: 'armeabi-v7a,arm64-v8a,x86,x86_64'

env:
  ANDROID_SDK_ROOT: /usr/local/lib/android/sdk
  ANDROID_NDK_ROOT: /usr/local/lib/android/sdk/ndk/21.4.7075529

jobs:
  setup:
    runs-on: ubuntu-latest
    outputs:
      architectures: ${{ steps.set-archs.outputs.archs }}
    steps:
      - name: Set architectures
        id: set-archs
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            ARCHS="${{ github.event.inputs.architectures }}"
          else
            ARCHS="armeabi-v7a,arm64-v8a,x86,x86_64"
          fi
          echo "archs=$ARCHS" >> $GITHUB_OUTPUT

  build:
    needs: setup
    runs-on: ubuntu-latest
    strategy:
      matrix:
        arch: [armeabi-v7a, arm64-v8a, x86, x86_64]
      fail-fast: false
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install build dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            build-essential \
            git \
            autoconf \
            automake \
            libtool \
            pkg-config \
            texinfo \
            yasm \
            nasm \
            perl

      - name: Set NDK environment
        run: |
          mkdir -p ffmpeg/jni
          cat > ffmpeg/jni/ENV << EOF
          NDK=$ANDROID_NDK_ROOT
          export NDK
          EOF

      - name: Build for ${{ matrix.arch }}
        run: |
          cd ffmpeg/jni
          chmod +x build-ffmpeg.sh rebuild-ffmpeg.sh
          ./build-ffmpeg.sh ${{ matrix.arch }} 2>&1 | tee build-${{ matrix.arch }}.log
          if [ $? -ne 0 ]; then
            echo "Build failed for ${{ matrix.arch }}"
            exit 1
          fi

      - name: Upload build artifacts
        if: success()
        uses: actions/upload-artifact@v3
        with:
          name: build-${{ matrix.arch }}
          path: ffmpeg/jni/build
          retention-days: 7

      - name: Upload build logs on failure
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: build-logs-${{ matrix.arch }}
          path: ffmpeg/jni/build-*.log
          retention-days: 30

  package:
    needs: build
    runs-on: ubuntu-latest
    if: success()
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Download all artifacts
        uses: actions/download-artifact@v3
        with:
          path: artifacts

      - name: Prepare package
        run: |
          mkdir -p codec-release
          find artifacts -name "*.so" -exec cp {} codec-release/ \;
          cp README codec-release/README.txt || true
          
          cat > codec-release/BUILD_INFO.txt << EOF
          MX FFmpeg Custom Codec
          Build Date: $(date -u +'%Y-%m-%d %H:%M:%S UTC')
          Git Commit: ${{ github.sha }}
          Repository: ${{ github.repository }}
          EOF

      - name: Create ZIP archive
        run: |
          cd codec-release
          zip -r ../mx-ffmpeg-codec-${{ github.run_id }}.zip .

      - name: Generate checksum
        run: |
          sha256sum mx-ffmpeg-codec-${{ github.run_id }}.zip > mx-ffmpeg-codec-${{ github.run_id }}.zip.sha256

      - name: Upload package
        uses: actions/upload-artifact@v3
        with:
          name: mx-ffmpeg-codec-package
          path: |
            mx-ffmpeg-codec-*.zip
            mx-ffmpeg-codec-*.sha256
          retention-days: 90

  release:
    needs: package
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/master'
    permissions:
      contents: write
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Download package
        uses: actions/download-artifact@v3
        with:
          name: mx-ffmpeg-codec-package

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: release-${{ github.run_number }}
          name: MX FFmpeg Codec Build #${{ github.run_number }}
          body: |
            # MX FFmpeg Custom Codec Release
            
            **Build ID:** ${{ github.run_id }}
            **Commit:** ${{ github.sha }}
            
            ## Included Architectures
            - armeabi-v7a (ARM 32-bit)
            - arm64-v8a (ARM 64-bit)
            - x86 (Intel 32-bit)
            - x86_64 (Intel 64-bit)
          files: |
            mx-ffmpeg-codec-*.zip
            mx-ffmpeg-codec-*.sha256
```

---

## 📋 Workflow 2: Auto-Merge Upstream Updates

**File:** `.github/workflows/auto-merge.yml`

```yaml
name: Auto-Merge Upstream Updates

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  check-upstream:
    runs-on: ubuntu-latest
    outputs:
      has-updates: ${{ steps.check.outputs.has-updates }}
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check for updates
        id: check
        run: |
          git remote add upstream https://github.com/USBhost/MX_FFmpeg.git || true
          git fetch upstream master
          
          LOCAL=$(git rev-parse origin/master)
          UPSTREAM=$(git rev-parse upstream/master)
          
          if [ "$LOCAL" != "$UPSTREAM" ]; then
            echo "has-updates=true" >> $GITHUB_OUTPUT
          else
            echo "has-updates=false" >> $GITHUB_OUTPUT
          fi

  merge:
    needs: check-upstream
    runs-on: ubuntu-latest
    if: needs.check-upstream.outputs.has-updates == 'true'
    permissions:
      contents: write
      pull-requests: write
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Configure Git
        run: |
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git config user.name "GitHub Actions Bot"

      - name: Merge upstream
        run: |
          git remote add upstream https://github.com/USBhost/MX_FFmpeg.git || true
          git fetch upstream master
          git checkout -b auto/merge-upstream origin/master
          
          git merge --no-ff upstream/master \
            -m "Merge: Sync with upstream USBhost/MX_FFmpeg" || {
            echo "CONFLICT=true" >> $GITHUB_ENV
            git merge --abort
          }

      - name: Push and create PR
        run: |
          if [ "${{ env.CONFLICT }}" == "true" ]; then
            TITLE="⚠️ Merge: Conflicts detected"
            BODY="Manual merge required - conflicts detected"
          else
            TITLE="⬆️ Merge: Upstream sync"
            BODY="Automatic upstream merge"
          fi
          
          git push -u origin auto/merge-upstream
          echo "TITLE=$TITLE" >> $GITHUB_ENV
          echo "BODY=$BODY" >> $GITHUB_ENV

      - name: Create PR
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: "${{ env.TITLE }}",
              body: "${{ env.BODY }}",
              head: "auto/merge-upstream",
              base: "master",
              labels: ["automatic", "upstream-sync"]
            })
```

---

## 📋 Workflow 3: Manual On-Demand Build

**File:** `.github/workflows/manual-build.yml`

```yaml
name: Manual Codec Build

on:
  workflow_dispatch:
    inputs:
      architectures:
        description: 'Select architectures'
        required: true
        default: 'armeabi-v7a'
        type: choice
        options:
          - 'armeabi-v7a'
          - 'arm64-v8a'
          - 'x86'
          - 'x86_64'
          - 'all'
      clean_build:
        description: 'Clean build (remove old artifacts)'
        required: false
        type: boolean
        default: false
      create_release:
        description: 'Create GitHub release'
        required: false
        type: boolean
        default: false

env:
  ANDROID_NDK_ROOT: /usr/local/lib/android/sdk/ndk/21.4.7075529

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        arch: ${{ fromJson(format('["{0}"]', github.event.inputs.architectures == 'all' && 'armeabi-v7a,arm64-v8a,x86,x86_64' || github.event.inputs.architectures)) }}
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y build-essential autoconf automake libtool pkg-config yasm nasm perl

      - name: Clean (optional)
        if: github.event.inputs.clean_build == 'true'
        run: |
          rm -rf ffmpeg/jni/build
          echo "Cleaned old builds"

      - name: Set NDK
        run: |
          mkdir -p ffmpeg/jni
          echo "NDK=$ANDROID_NDK_ROOT" > ffmpeg/jni/ENV
          export NDK

      - name: Build
        run: |
          cd ffmpeg/jni
          chmod +x build-ffmpeg.sh
          ./build-ffmpeg.sh ${{ matrix.arch }}

      - name: Upload
        uses: actions/upload-artifact@v3
        with:
          name: build-manual-${{ matrix.arch }}
          path: ffmpeg/jni/build
          retention-days: 30
```

---

## 🔧 Installation Instructions

### Option 1: Manual Creation

1. Create `.github/workflows/` directory:
```bash
mkdir -p .github/workflows
```

2. Copy each workflow YAML file above into the directory

3. Commit and push:
```bash
git add .github/workflows/
git commit -m "Add GitHub Actions automation"
git push
```

### Option 2: Using CLI

```bash
# Create directory
mkdir -p .github/workflows

# Create files (paste YAML content above into these files)
touch .github/workflows/build-codec.yml
touch .github/workflows/auto-merge.yml
touch .github/workflows/manual-build.yml

# Commit
git add .github/workflows/
git commit -m "Add automated build workflows"
git push origin master
```

---

## ✅ Verification

After pushing, verify the workflows are active:

1. Go to **GitHub repository** → **Actions** tab
2. You should see:
   - ✅ "Build MX FFmpeg Codec"
   - ✅ "Auto-Merge Upstream Updates"
   - ✅ "Manual Codec Build"

If they appear with a green checkmark, automation is active! 🎉

---

## 🎯 Usage Examples

### Automatic Build
```bash
# Just push to master
git push origin master
# Builds automatically!
```

### Manual Build
1. Go to **Actions** → **Manual Codec Build**
2. Click **Run workflow**
3. Select architecture: `armeabi-v7a`, `arm64-v8a`, `x86`, or `x86_64`
4. Check `clean_build` to remove old artifacts
5. Click **Run workflow**

### Check Auto-Merge
1. Go to **Actions** → **Auto-Merge Upstream Updates**
2. It runs daily at 2 AM UTC
3. Creates PR if updates found
4. Manually trigger with **Run workflow**

---

## 🔧 Configuration Options

### Change Cron Schedule (Auto-Merge)

In `auto-merge.yml`, modify the `cron` schedule:

```yaml
schedule:
  - cron: '0 2 * * *'     # Daily at 2 AM UTC
  # Examples:
  # - cron: '0 * * * *'   # Every hour
  # - cron: '0 0 * * 0'   # Weekly Sunday midnight
  # - cron: '0 0 1 * *'   # Monthly 1st at midnight
```

### Change Upstream Source

In `auto-merge.yml`, change the repository:

```yaml
git remote add upstream https://github.com/YOUR_ORG/YOUR_REPO.git
git fetch upstream YOUR_BRANCH
```

### Change NDK Path

In workflow files, modify:

```yaml
ANDROID_NDK_ROOT: /your/ndk/path
```

---

## 📊 Monitoring

### View Workflow Status
1. **Actions** tab → Select workflow
2. View real-time logs
3. Download artifacts from completed runs

### Build Logs
1. Click on failed workflow
2. Expand job steps
3. Download logs as artifacts

---

## 🚨 Troubleshooting

### Workflow Not Running
- Check `.github/workflows/` directory exists
- Verify YAML syntax (use [YAML validator](https://www.yamllint.com/))
- Push to default branch (master)

### Build Failures
- Check NDK path in workflow
- Verify dependencies installed
- Review build logs in artifacts

### Permission Errors
- Ensure GitHub Actions enabled in repo settings
- Check workflow permissions (usually set automatically)

---

## 📝 Files Structure

After setup, your repo should have:

```
khirendra03/MX_FFmpeg/
├── .github/
│   └── workflows/
│       ├── build-codec.yml
│       ├── auto-merge.yml
│       └── manual-build.yml
├── ffmpeg/
│   └── jni/
├── README.md
├── BUILD_AUTOMATION.md
└── ...
```

---

## 🎓 Next Steps

1. ✅ Copy workflow files to `.github/workflows/`
2. ✅ Commit and push to GitHub
3. ✅ Go to **Actions** tab to verify
4. ✅ Trigger manual build to test
5. ✅ Check for build artifacts/releases

**You now have fully automated codec building!** 🚀

