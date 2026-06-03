# Multi-TEE support patch for a34x

Check currently supported bootloader versions: [here](https://github.com/UN1CA/target_a34x_patches_tee/blob/main/supported_bootloaders)

Check changelog and the bootloader versions supported in each Multi-TEE version: [here](https://github.com/UN1CA/target_a34x_patches_tee/blob/main/CHANGELOG.md)

To check your bootloader version simply run the following command in Termux or ADB shell, then check if the Multi-TEE version your ROM has supports that bootloader version:
```
getprop ro.boot.bootloader
```

This patches are made for UN1CA build system and currently work only with API 35 vendor (used in One UI 7 and later) of Galaxy A34 5G. 

Contents of this repository should be cloned in the `target/a34x/patches/tee` folder. You can use the following command to set them up in your UN1CA-based environment as long as `a34x` is your target.
```
git clone https://github.com/UN1CA/target_a34x_patches_tee target/a34x/patches/tee
```

They make it possible to support booting on multiple bootloader versions (so multiple variants) by shipping different TEE blobs which are dynamically mounted at boot time. TEEGris on A34 requires the version signature of each TA to match with the version of the bootloader.

Only latest firmware for each model is supported. Because One UI 8 has made bootloader unlock impossible, blobs version will be freezed to the latest available One UI 7 version for each model.

In the rare case you found a way to unlock One UI 8 bootloader (using an exploit or a EM Token) running One UI you can, of course, request adding support for that bootloader version using the appropriate Issue template. 

### License
All files of this project are currently under GPLv3 license, this excludes all the prebuilt files located in vendor/tee_* directories.

You can use this project but you must make sure you give credits to me and the other prople who made this possible.

### Credits
- [@salvogiangri](https://github.com/salvogiangri)
- [@jesec](https://github.com/jesec) and [@corsicanu](https://github.com/corsicanu) for the original GitHub Actions script
