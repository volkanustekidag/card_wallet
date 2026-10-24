fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

App Store text + screenshots, every locale. promo:true also sends the promotional text (it goes live at once).

----


## Android

### android metadata

```sh
[bundle exec] fastlane android metadata
```

Play listing (text, phone screenshots, feature graphic), every locale; left unsent for review. wear:true keeps the Wear OS frame 4.

### android wear

```sh
[bundle exec] fastlane android wear
```

Upload the Wear OS AAB to a Wear track as a draft (build: tools/release_build.sh android)

### android wear_screenshots

```sh
[bundle exec] fastlane android wear_screenshots
```

Wear OS screenshots for every locale (once the Wear form factor is on)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
