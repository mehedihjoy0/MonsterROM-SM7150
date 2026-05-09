<h1 align="center">
  <img loading="lazy" src="readme-res/banner.png"/>
</h1>
<p align="center">
  <a href="https://github.com/devcore94/MonsterROM-REBORN/blob/sixteenQPR2/LICENSE"><img loading="lazy" src="https://img.shields.io/github/license/devcore94/MonsterROM-REBORN?style=for-the-badge&logo=github"/></a>
  <a href="https://github.com/devcore94/MonsterROM-REBORN/commits/sixteenQPR2"><img loading="lazy" src="https://img.shields.io/github/last-commit/devcore94/MonsterROM-REBORN/sixteenQPR2?style=for-the-badge"/></a>
  <a href="https://github.com/devcore94/MonsterROM-REBORN/stargazers"><img loading="lazy" src="https://img.shields.io/github/stars/devcore94/MonsterROM-REBORN?style=for-the-badge"/></a>
  <a href="https://github.com/devcore94/MonsterROM-REBORN/actions/workflows/build.yml"><img loading="lazy" src="https://img.shields.io/github/actions/workflow/status/devcore94/MonsterROM-REBORN/build.yml?branch=sixteenQPR2&style=for-the-badge"/></a>
</p>
<p align="center">MonsterROM-REBORN is a One UI 8.5 custom firmware project based on the Galaxy S26+ SM-S947B firmware.</p>

<p align="center">
  <a href="https://github.com/devcore94/MonsterROM-REBORN/discussions">Discussions</a>
</p>

# What is MonsterROM-REBORN?
MonsterROM-REBORN is a work-in-progress custom firmware for Samsung Galaxy devices, designed to provide a refined, optimized and more feature-rich One UI experience.
This branch is based on Samsung's One UI 8.5 / Android 16 QPR2 firmware for the Galaxy S26+ SM-S947B on the Exynos SSI path and inherits the upstream build system, patch framework and feature set. Snapdragon targets keep the inherited `qssi.sh` SM-S948B donor.

The build system automatically builds the required tools, downloads and extracts firmware components, applies platform, device and ROM patches, then generates a target-files or flashable zip for the selected target device.

The goal is to deliver a fast, smooth and modern UX while keeping S947B as the Exynos donor firmware and preserving compatibility with inherited scripts and smali hooks.

Any form of contribution, suggestions, bug report or feature request for the project will be welcome.

# Features
### Core features:
- Based on Galaxy S26+ SM-S947B One UI 8.5 firmware
- EROFS powered
- Galaxy S25 wallpapers/sounds included
- Galaxy AI support
  - Audio eraser
  - Browsing assist
  - Call assist
  - Drawing assist
  - Interpreter
  - Note assist
  - Now brief
  - Photo assist
  - Semantic search
  - Transcript assist
  - Writing assist
- High end animations
- Native/live blur support*
- AOD clock transition support
- Adaptive color tone support
- Adaptive refresh rate support
- Extra brightness support
- Picture remaster support
- Object, shadow and reflection eraser support
- Image clipper support
- Multi user support
- Samsung DeX support**
- Camera privacy toggle support
- Debloated from useless system services/additional apps
- Dual Messenger available for all apps
- Custom FlipFont fonts support
- Outdoor mode support
- Auto PIN confirm with 4 digits
- [BluetoothLibraryPatcher](https://github.com/3arthur6/BluetoothLibraryPatcher) integrated
- [KnoxPatch](https://github.com/salvogiangri/KnoxPatch) integrated
- Extra CSC features enabled (Call recording, Hiya, Network speed in status bar, AltZLife)

\* Not available on MediaTek devices<br>
\*\* DeX via HDMI not available for devices without USB-C DP support

### MonsterROM-REBORN features:
- Integrated MonsterROM-REBORN OTA updates app
- Native/live blur toggle
- One UI Home animations option
- Vulkan renderer toggle
- Key attestation spoof ([TrickyStore](https://github.com/5ec1cff/TrickyStore)) options*
- Play Integrity Fix integrated
- Ability to hide installed apps ([Hide My Applist](https://github.com/Dr-TSNG/Hide-My-Applist))
- Ability to hide developer options
- Allow app downgrade toggle
- Allow installing apps with old targetSdk toggle
- Allow secure screenshot toggle
- Screenshot/screen recording detection toggle
- Unlimited backup storage on Google Photos
- Games FPS unlock toggle

\* Requires a valid keybox

# Licensing
This project is licensed under the terms of the [GNU General Public License v3.0](LICENSE). External dependencies might be distributed under a different license, such as:
- [android-tools](https://github.com/nmeum/android-tools), licensed under the [Apache License 2.0](https://github.com/nmeum/android-tools/blob/master/LICENSE)
- [apktool](https://github.com/iBotPeaches/Apktool), licensed under the [Apache License 2.0](https://github.com/iBotPeaches/Apktool/blob/master/LICENSE.md)
- [erofs-utils](https://github.com/sekaiacg/erofs-utils/), dual license ([GPL-2.0](https://github.com/sekaiacg/erofs-utils/blob/dev/LICENSES/GPL-2.0), [Apache-2.0](https://github.com/sekaiacg/erofs-utils/blob/dev/LICENSES/Apache-2.0))
- [img2sdat](https://github.com/xpirt/img2sdat), licensed under the [MIT License](https://github.com/xpirt/img2sdat/blob/master/LICENSE)
- [platform_build](https://android.googlesource.com/platform/build/) (ext4_utils, f2fs_utils, signapk), licensed under the [Apache License 2.0](https://source.android.com/docs/setup/about/licenses)

# Contributors
<a href="https://github.com/devcore94/MonsterROM-REBORN/graphs/contributors"><img loading="lazy" src="https://contrib.rocks/image?repo=devcore94/MonsterROM-REBORN"/></a>

# Credits
A special thanks goes to the following for their invaluable contributions in no particular order:
- **[ShaDisNX255](https://github.com/ShaDisNX255)** for his help, time and for his [NcX ROM](https://github.com/ShaDisNX255/NcX_Stock) which inspired this project
- **[DavidArsene](https://github.com/DavidArsene)** for his help and time
- **[paulowesll](https://github.com/paulowesll)** for his help and support
- **[Simon1511](https://github.com/Simon1511)** for his support and some of the device-specific patches
- **[ananjaser1211](https://github.com/ananjaser1211)** for troubleshooting and his time
- **[Fede2782](https://github.com/Fede2782)** for his contributions and help with Exynos/MTK support
- **[iDrinkCoffee](https://github.com/iDrinkCoffee-TG)** and **[RisenID](https://github.com/RisenID)** for their support
- **[LineageOS Team](https://www.lineageos.org/)** for their original [OTA updater implementation](https://github.com/LineageOS/android_packages_apps_Updater)
- *All upstream project contributors, fork maintainers, testers and users*

# Stargazers over time
[![Stargazers over time](https://starchart.cc/devcore94/MonsterROM-REBORN.svg)](https://starchart.cc/devcore94/MonsterROM-REBORN)
