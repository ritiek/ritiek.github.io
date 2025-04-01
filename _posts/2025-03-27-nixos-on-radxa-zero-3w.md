---
title: NixOS on Radxa Zero 3W
date: 2025-03-27
layout: post
comments: false
tags:
  - linux
---


I was able to get NixOS working on Radxa Zero 3W! It's got some firmware related issues, with
the major one being built-in WiFi not getting detected correctly. Otherwise, it seems usable for
the most part.


## TL;DR

NixOS SD card images can be build using this flake:
[https://github.com/nabam/nixos-rockchip](https://github.com/nabam/nixos-rockchip)

Use the image for `CM3/CM3 I/O` board type.

<!-- TODO: I think the reason this probably works is.. (See boot source code (at home)). -->

Basically, add the inputs to our flake.nix:
```nix
inputs = {
  rockchip.url = "github:nabam/nixos-rockchip";
  flake-utils.url = "github:numtide/flake-utils";
};
```

Define the target outputs in flake.nix
```nix
nixosConfigurations.radxa-zero-3 = inputs.nixpkgs.lib.nixosSystem {
  system = "aarch64-linux";
  modules = [
    ./machines/radxa-zero-3
    ./machines/radxa-zero-3/hw-config.nix
  ];
  specialArgs = { inherit inputs; };
};

radxa-zero-3-sd = self.nixosConfigurations.radxa-zero-3.config.system.build.sdImage;
```

Add this config to the board's hardware configuration:
```nix
{ config, lib, pkgs, modulesPath, inputs, ... }:

let
  noZFS = {
    inputs.nixpkgs.overlays = [
      (final: super: {
        zfs = super.zfs.overrideAttrs (_: { meta.platforms = [ ]; });
      })
    ];
  };
in
{
  imports = [
    inputs.rockchip.nixosModules.sdImageRockchip
    inputs.rockchip.nixosModules.noZFS
  ];

  # I'll assume native host machine as aarch64.
  # (I believe "aarch64-linux" can be changed to "x86-64-linux" to cross-compile)
  rockchip.uBoot = inputs.rockchip.packages."aarch64-linux".uBootRadxaCM3IO;
  boot.kernelPackages = inputs.rockchip.legacyPackages."aarch64-linux".kernel_linux_6_12_rockchip;
}
```

## Issues

It looks like the onboard WiFi is not yet supported by the kernel shipped with the [current latest version
of NixOS unstable](https://github.com/NixOS/nixpkgs/commit/b6eaf97c6960d97350c584de1b6dcff03c9daf42).

It is important to note that early Radxa Zero 3W boards shipped with a different WiFi chip, AP6212. The
newer versions and the board I have on me come with the AIC WiFi chip. Both of these depened on a different
software driver. The AIC WiFi chip requires the AIC8800 driver.

[https://forum.radxa.com/t/wifi-driver-for-radxa-zero-3w/20507](https://forum.radxa.com/t/wifi-driver-for-radxa-zero-3w/20507)

There's an open issue on nixpkgs to add support for the newer Radxa Zero 3W's onboard WiFi module:

[https://github.com/NixOS/nixpkgs/issues/342133](https://github.com/NixOS/nixpkgs/issues/342133)

In the meanwhile, it's possible to feed internet to the board via USB tethering. My Android mobile device,
as well most Android devices out there support USB tethering out-of-the-box.

I also tried an RTL8192EU based WiFi dongle and it has been a plug-and-play experience as well.


## How to know if the board is booting into the OS?

I've tried out the `CM3/CM3 I/O` image variant from
[https://github.com/nabam/nixos-rockchip](https://github.com/nabam/nixos-rockchip)
which looks to boot properly on my Radxa Zero 3W.

It's easy to verify whether the image is booting into the OS if we've a supported micro-HDMI cable and a
monitor around.

If not, there's another way to verify whether the boot sequence is working correctly. Try out the following:

1. Flash the image onto the microSD card.

2. Mount this flashed microSD card onto your local machine first and take note of the directory structure
  present in the root partition.

3. Insert this flashed SD card into Radxa Zero 3W and keep the board powered on for ~5 mins. If the boot
  sequence is working as expected, the software should perform nix path registrations on the first boot.

4. Now pull out the microSD card from the board and mount it onto your local machine. If the directory
  structure has changed considerably from before, and nix-path-registrations file is no longer present in the
  root partition, that means the boot was a success!

That is pretty much it! If you're headless, you can build a config using nixos-rockchip that launches the
OpenSSH server on boot with your credentials. You can then find the IP address of the board after tethering
and SSH'ing into the board should then work just fine.


## Radxa Zero 3E?

I've also Radxa Zero 3E with me which doesn't seem to boot up with the Radxa CM3/CM3 I/O image (or any
other image, including the Radxa-supported Debian and Ubuntu images).
I'm not sure if I received a damaged board or that the boot addresses are different
between the 3W and the 3E. I've read people having issues with the microSD slot where the pins do not
make contact when the microSD card is inserted on the 3E, although mine seems to look good in this
regard. More tinkering imminent.
