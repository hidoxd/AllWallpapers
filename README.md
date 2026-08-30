# AllWallpapers 0.1.0

Read-only PosterBoard descriptor browser for iOS 18.5 / Dopamine 3.x rootless.

## Safety scope

This project does not use kernel R/W, IOKit exploitation, task ports, sysctl patching, SpringBoard binary patching, or writes to PosterBoard. It only reads the PosterBoard `CollectionsPoster` descriptor store after asking ContainerManager for a sandbox extension.

The tweak is injected only into `com.apple.Preferences` and adds an **All** button on wallpaper-related Settings screens. The browser lists all discovered descriptors and thumbnails. Selecting one is read-only in v0.1.

## Build

GitHub Actions uses `waruhachi/theos-action@v2.4.6` and builds with `THEOS_PACKAGE_SCHEME=rootless`.

## Install

Install the resulting `.deb` with Sileo/Zebra. Re-springing is not part of the package script beyond restarting Preferences.

## Important

`com.apple.WallpaperKit.CollectionsPoster` and private ContainerManager behavior are undocumented/private APIs. This build deliberately stops before applying a wallpaper. That keeps the first iteration read-only and easier to diagnose.
