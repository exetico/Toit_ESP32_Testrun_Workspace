# Toit & Jaguar - Work in progress (Personal notes)

You've found my personal notes, on how to use the solutions from Toit.io - Jaguar and the toit-lang.

## VL53L0X Driver - Work in progress

This project is currently in a "work in progress" state. It's somewhat working, but finetuning and clean must be done, before this should be used in a final product.

You're more than welcome to create a PR, if you have any suggestions on how to both improve, refactor an optimize the current solution, or maybe even "tune" the settings and calibration for the VL53L0X.

## Links

**Toit standard libraries**: [https://libs.toit.io/](https://libs.toit.io/)
**Toit language basics**: [https://docs.toit.io/language](https://docs.toit.io/language)
**Toit project examples**: [https://github.com/toitlang/toit/tree/master/examples](https://github.com/toitlang/toit/tree/master/examples)

## Install

### MacOS

`brew install toitlang/toit/jag`

Point to a SDK like: `https://github.com/toitlang/toit/releases/download/v2.0.0-alpha.48/toit-macos.tar.gz`

Remember to check the [release page](https://github.com/toitlang/toit/releases).

### Linux / Manjaro

`yay install jaguar-bin`

Or use a GUI like `bauh`

Hereafter, remember to run `jag setup`.

## Jaguar Cheat-sheet

Serial monitor:
`jag monitor --attach`

### Flash ESP32

Flash ESP32 with:
`jag flash`

### Containers

Install container:
`jag container install hello hello.toit`

Uninstall:
`jag container uninstall hello`

### Packages

Take a look at the [documentation for packages](https://docs.toit.io/language/package). Visit the [Package quick start](https://docs.toit.io/language/package/pkgguide) for a short introduction.

Sync packages:
`jag pkg sync`

Search for packages:
`jag pkg search ntp`

Install package:
`jag pkg install ntp`

## Notes

### Getting time on the ESP32

First you'll need to grap the print-time.toit example from the documentation, or use this repo. Hereafter, get both settime.toit and synchronize.toit from [here](https://github.com/toitlang/pkg-ntp/blob/master/examples/).

Install the required `ntp` package in Jaguar by executing `jag pkg install ntp`.

Hereafter run the settime.toit on the ESP32 by executing `jag run print-time.toit`.

The time is now in sync, until the next reboot of the device.

All scripts uploaded to the ESP32 can be wrapped in a container. Containers will be executed on every reboot. Therefore, it's possible to secure the correct time on every reboot, by creating a set-time container like so:
`jag container install set-time settime.toit`

In some scenarios, consider to use a real-time clock instead. But.. That's really up to you and the project-requirements.
