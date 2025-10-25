+++
title = "MicroSD Boot Partition with NVMe Root Filesystem on Raspberry Pi 5"
date = 2025-10-20
path = "2025/10/20/microsd-boot-partition-with-nvme-root-filesystem-on-raspberry-pi-5"
template = "page.html"
[taxonomies]
tags = []
+++

I run NixOS on my Raspberry Pi 5. For a while I've been running everything off a microSD card, but
I wanted to migrate to an NVMe drive connected through a M.2 HAT via the PCIe slot for better performance
and reliability.

I currently use the now deprecated [raspberry-pi-nix](https://github.com/nix-community/raspberry-pi-nix)
flake to build an image for my RPi5. While I'd like to migrate to the actively maintained
[nixos-raspberrypi](https://github.com/nvmd/nixos-raspberrypi) flake, I haven't gotten around to it yet.
When using u-boot with this flake, it's currently unable to boot directly off NVMe on the Pi 5, so a
hybrid boot approach with the microSD card is necessary.

I found it's possible to set up a hybrid boot configuration - boot from the microSD card initially,
then mount the NVMe drive as the root filesystem. This gives me the performance benefits of NVMe
while working around the u-boot limitations.

## Updating the firmware

Before attempting the hybrid boot setup, I updated my Raspberry Pi 5's firmware to the latest version.
Newer firmware versions have better NVMe support and handle drive detection more reliably. For example,
[this issue](https://github.com/raspberrypi/firmware/issues/1833) tracks recently released improvements
for booting off NVMe drives connected through PCIe switches.

I flashed Raspberry Pi OS to a separate microSD card, booted from it, and updated the bootloader
firmware directly from the command line:

```bash
$ sudo rpi-eeprom-update -a
```

Alternatively, the bootloader can be updated through the interactive menu:

```bash
$ sudo raspi-config
```

Then navigate to **Advanced Options → Bootloader Version → Latest**.

After the update completed, I rebooted and verified the firmware version:

```bash
$ sudo rpi-eeprom-update
```

Once confirmed the firmware was up to date, I proceeded with setting up the hybrid boot configuration.

## The hybrid boot approach

The idea is simple: the Raspberry Pi 5 reads the boot partition from the microSD card to load the
kernel and initial boot configuration, but then switches to using the NVMe drive for the actual
root filesystem.

The boot process works like this:
1. RPi5 firmware reads the FAT32 boot partition on the microSD card (`/dev/mmcblk0p1`).
2. It loads the kernel and reads `cmdline.txt` which specifies the root partition.
3. The root partition specified in `cmdline.txt` points to the NVMe drive instead of the microSD card.
4. System boots with NVMe as the root filesystem.

## Setting up the hybrid boot

### Step 1: Prepare cmdline.txt for delayed boot

First, I needed to give the system enough time to detect the NVMe drive during boot. I mounted the
boot partition and modified `cmdline.txt` before cloning:

```bash
$ sudo mount /dev/mmcblk0p1 /mnt
$ sudo vi /mnt/cmdline.txt
```

I added `rootwait rootdelay=30` to the end of the existing parameters. The `rootdelay=30` gives the
system 30 seconds to detect and initialize the NVMe drive before attempting to mount the root partition.

Once done, I unmounted the partition:
```bash
$ sudo umount /mnt
```

### Step 2: Clone the microSD card to NVMe

Next, I cloned the entire microSD card contents to the NVMe drive (dangerous! this will wipe off the
NVMe drive).

I switched to a root shell to avoid permission issues with block device operations:

```bash
$ sudo su
# pv /dev/mmcblk0 > /dev/sda
```

This took a while since it's copying everything bit-by-bit to the NVMe drive. The result is an exact
duplicate of the microSD card on the NVMe.

### Step 3: Modify partition identifiers to avoid conflicts

Here's the tricky part - both the microSD card and NVMe now have identical partition UUIDs and labels,
which would confuse the system about which partition to mount. Since I'm using the microSD card's boot
partition and the NVMe's root partition, I needed to change identifiers to avoid conflicts.

**Important:** Before making any changes, note down the current UUIDs, PARTUUIDs, and labels of all
partitions on both the drive as well as the microSD card:

```bash
$ sudo blkid /dev/mmcblk0p1 /dev/mmcblk0p2 /dev/sda1 /dev/sda2
```

Save this output somewhere safe. If something goes wrong, we'll need these values to revert the changes.

Since the system will use the microSD card's boot partition and the NVMe's root partition, I needed
to change identifiers on the unused partitions to avoid conflicts.

**For the ext4 root partition on the microSD card** (`/dev/mmcblk0p2`):

I changed the microSD card's root partition identifiers so it won't conflict with the NVMe's root
partition:

```bash
# Change the label
$ sudo e2label /dev/mmcblk0p2 NIXOS_SD_UNUSED

# Change filesystem UUID
$ sudo tune2fs /dev/mmcblk0p2 -U random

# Verify changes
$ sudo blkid /dev/mmcblk0p2
```

This partition can be kept as a backup root filesystem in case the NVMe fails, or repurposed for
other storage needs.

**For the FAT32 boot partition on the NVMe** (`/dev/sda1`):

I also changed the NVMe's boot partition identifiers so it won't conflict with the microSD card's
boot partition:

```bash
# Change the label
$ sudo fatlabel /dev/sda1 FIRMWARE_UNUSED

# Change filesystem UUID using mlabel
$ echo "drive x: file=\"/dev/sda1\"" > /tmp/mtoolsrc
$ MTOOLS_SKIP_CHECK=1 sudo env MTOOLSRC=/tmp/mtoolsrc mlabel -N ABCDEF01 x:

# Verify changes
$ sudo blkid /dev/sda1
```

**Note:** The `mlabel -N` command takes an 8-digit hexadecimal value for the FAT32 volume serial number.
We only change the filesystem UUID of the NVMe boot partition, not the disk signature, because changing
the disk signature would alter the PARTUUID of `/dev/sda2` which needs to remain stable for `cmdline.txt`
to reference it correctly.

### Step 4: Verify cmdline.txt points to the correct partition

The `cmdline.txt` on the microSD card's boot partition should reference the NVMe's root partition.
Mine looks like this:

```txt
root=PARTUUID=2178694e-02 rootfstype=ext4 fsck.repair=yes rootwait rootdelay=30 console=tty1 console=serial0,115200n8 init=/sbin/init loglevel=7 lsm=landlock,yama,bpf
```

The `root=PARTUUID=2178694e-02` should match the PARTUUID of the NVMe's root partition (`/dev/sda2`),
not the microSD card's root partition.

The PARTUUID of NVMe root partition can be verified with:
```bash
$ sudo blkid /dev/sda2
```

The output will show both the filesystem UUID and partition PARTUUID. Make sure the PARTUUID in
`cmdline.txt` matches what you see for `/dev/sda2`.

### Step 5: Boot with both drives connected

I connected both the microSD card and NVMe drive back into my RPi5 and powered it on. The system now:
1. Reads the boot partition from the microSD card.
2. Mounts the root filesystem from the NVMe drive.
3. Runs NixOS entirely off the NVMe for all file operations.

Success! My NixOS root partition now runs off the NVMe drive, giving me the performance and reliability
I was looking for.

## Expanding the NVMe storage

After getting the hybrid boot working, I realized the NVMe drive had much more space than the microSD
card I cloned from. The cloned root partition was only using the same amount of space as the original
microSD card, leaving the rest of the NVMe drive unused.

The root partition on the NVMe can be resized to use all available space, or new partitions can be
created for additional storage.
