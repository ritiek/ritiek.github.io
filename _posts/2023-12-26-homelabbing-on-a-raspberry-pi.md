---
title: "Homelabbing on a Raspberry Pi"
date: 2023-12-26
layout: post
comments: false
tags:
  - linux
---

I've had to constantly declutter my photos and documents stored on Google Drive as I've been running
low on the 15 GB free-tier storage since a while. Doing so has bought me a few weeks each time, but isn't fun.

Despite of already having compression enabled for my stuff on Google Photos, I was still reaching a point
of always having to carefully think about considerations of what and what not to upload.
That said, 15 GB doesn't seem much at all in the first place as of writing this; storage requirements have been
inflating and there are growing number of other services that like to store backups on Google Drive, leaving
less for everything else. Getting a premium-tier should help, but it doesn't seem like a long term solution to
me (I'm sure I'll exhaust 100 GB tier too after a while, if given the freedom) and all of this also seems to
contribute to vendor lock-in. I'd also like to avoid a 3rd party service perform face recognition or deduce
other things from my photo collections.

## What I've been looking for

So I decided to look out for self-hostable FOSS alternatives to Google Photos and I liked
[Immich](https://github.com/immich-app/immich). With self-hosting things there come a plethora of other
things that need to be taken care of. I don't
want my server to be accessible only locally and my ISP puts me behind a NAT which makes port forwarding
not work for me. Although, putting personal photos behind a public address doesn't seem like a good idea
anyway. There are many ways to get my server accessible from the outside Internet securely.
I used to use remote.it which seems meh to me after I tried out [tailscale](https://github.com/tailscale/tailscale) and for me tailscale seems to do all the things I could ever ask for, but there are many alternatives
to tailscale around too weighing up and down worth an explore.

I now self-host a couple more services besides Immich, few of them I'll mention later.
As of late, my setup seems to be stable enough for everyday use, has increased my quality of life, and now
feels legal to call it teeny-bit my own "homelab" given how far I think it has come. I've made rough pointers
on technical considerations/ramifications I've had to deal with during the process, that I'd wanted to
archive here in more detail.

<!--It'll be a good idea to the read the entire post first. Otherwise one might take away specific parts which
may not be as accurate, as my reasonings don't necessarily read in chronological order.-->

## Hardware

I recently got a Raspberry Pi 4 (4GB model) and reading up seems like Immich worked fine on one. So I decided
to get into this with my RPi4

### Architecture

RPi4 is ARM 64-bit. Generally, I've read software support for ARM 64-bit isn't quite yet up to the par with
x86 systems. I've low-key faced this problem myself when setting up a few services later on
(say [TubeArchivist](https://github.com/tubearchivist/tubearchivist)), it takes a bit of researching but so
far I've always been lucky enough to be able to get away with things working fine in my case eventually.

### OS

I'll be running Raspberry Pi OS lite (64-bit) headlessly on my Pi and doing things later on via SSH.
I've also kept a USB to TTL adapter connected to the GPIO pins, it's been immensely useful
in debugging whenever I wasn't able to access my Pi through SSH and [and network issues](http://localhost:4000/2023/12/09/debugging-wifi-on-a-headless-raspberry-pi/).

### Storage

Initially, my boot and root filesystems were present on a MicroSD card plugged into my RPi, and I'd be storing
my Immich photos on a USB 3.0 external SSD plugged into my RPi.

Since, RPi4 supports USB boot, I later on decided to move away completely from MicroSD cards to SSDs for
all storage as MicroSD cards seem a bit fragile to me both physically and circuitry wise, and also due to
the reason that now I'd have 2 different storage devices (failure points) working in conjunction to achieve
one goal of self-hosting my services.

I also decided to get a newer NVMe SSD with a USB 3.0 enclosure instead of using a USB 3.0 external SSD.
I had my reasons for this:

• USB 3.0 external SSD could get difficult to work with if their USB 3.0 connector gets damaged. This shouldn't
be a problem with NVMe SSD with USB enclosure. In the case the USB connector of the enclosure were to get
damaged, I could get a new USB enclosure and get back to normal working immediately.

• It can be re-used as internal storage in machines with PCIe slot.

• NVMe is faster (though in my case, USB 3.0 speeds will probably bottleneck before anything else)

• My old SSD couldn't store as much and the combination of getting a reputable NVMe SSD + USB enclosure
was cheaper to get than a USB 3.0 external SSD with the same amount of storage in my place. 

#### Partioning

With now everything on my SSD, I had to think of how to best partition filesystems on it. I also got to
research about lesser-known filesystems like ZFS, BTRFS during this time. I went ahead with this partitioning:

BootFS and RootFS:
```
/dev/sda1               vfat       255M  53.6M 201.4M  21% /boot
/dev/sda2               ext4      49.2G  13.1G    34G  27% /
```
Then a logical partition with 2 LUKS encrypted partitions under it:
```
/dev/mapper/docker-data ext4      97.9G  28.9G    64G  29% /var/lib/docker
/dev/mapper/media       btrfs    765.2G 211.7G 553.3G  28% /media
```
And a 16GB reserved space (also under the previously created logical partition) after the BTRFS partition
since I've read around BTRFS dealing defragmentation can at times leave partition out of space, so this
little reserve might come in handy. I can use this reserve as LUKS encrypted swap space other times if
needed.
```
/dev/sda7       1919971328 1953523711   33552384    16G 82 Linux swap / Solaris
```
I went ahead with using ext4 with my RootFS as I've never tried other filesystems and BTRFS (unlike traditional
filesystems like ext4) has a bit of a learning curve in order to personalize it as per our requirements,
so didn't want to put my eggs in the same basket all at once while I'm still relatively new to it.

Here's the mount options that I've been using with BTRFS as of writing:
```bash
$ sudo mount -o defaults,noatime,nodiscard,noautodefrag,ssd,space_cache=v2,compress-force=zstd:3 /dev/mapper/media /media
```

At the time of writing mainline kernel for RPi4 points to the `6.1.y` tree. I read around there were BTRFS
related improvements made in the newer kernels, so I was able to update my kernel with to the `6.6.y` tree with:
```bash
$ sudo rpi-update rpi-6.6.y
```
and things have been stable so far with a month or two since the update.

You can see which branch is the newer kernel version [here](https://github.com/raspberrypi/linux) and pass it
to `rpi-update`.

I used ext4 with `/var/lib/docker/` as it looks to be a place with high rate of read and writes, something
BTRFS to me still seems dicey with after researching around.


### Low-RAM Issues

Immich alone mentions these requirements as of writing this:
> OS: Preferred unix-based operating system (Ubuntu, Debian, MacOS, etc). Windows works too, with Docker Desktop on Windows
>
> RAM: At least 4GB, preferred 6GB.
>
> CPU: At least 2 cores, preferred 4 cores.

After hosting quite a a few services besides Immich; the 4GB RAM on RPi4 did turn out to be a bottleneck after
a while. Pi would start to freeze up and in the scenario it did let me SSH into it (I didn't had the USB to
TTL thing set up yet) and do `btop`, it indeed seemed to be struggling with RAM while `kswapd` was seen
to be hogging up all the CPU. And then sometimes the OOM killer kicked in and everything was a mess.

I set aside 16 GB swap space on my SSD and freezes went away, but soon I learned about zram (a Linux kernel
module for compressing data before storing it on RAM) and I decided to set it up to reduce SSD wear as well
as coming across convincing-enough claims about it improving read/write speeds (despite the de/compression
CPU overhead).

#### ZRAM

I used [zram-swap](https://github.com/foundObjects/zram-swap) to set up zram.
Initially, I went ahead with lz4 compression as it seemed a good speed vs compression ratio trade-off on
paper. I set up 2GB (out of the 4GB) of RAM to be utilized as zram with this sysctl config:
```
vm.swappiness = 180
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
vm.page-cluster = 0
```

In practise however, lz4 for me seems
to cause lots of CPU cycles on `kswapd`, keeping CPU usage to around 100% all the time. Researching around,
I came across this [reddit comment](https://www.reddit.com/r/Fedora/comments/mzun99/comment/h1cnvv3/)
mentioning lz4 being suspectible to OOM.

Later on, I moved to zstd and used 1/3 out of the 4GB RAM (so 1.33 GB RAM as zram) with this sysctl config:
```
vm.vfs_cache_pressure = 500
vm.swappiness = 100
vm.dirty_background_ratio = 1
vm.dirty_ratio = 50
vm.page-cluster = 0
```
zstd has better compression ratio with lower speeds
than lz4 on paper. I've noticed when self-hosting CPU mostly stays on idle workload most of the time and
gets bursts of heavy lifting time to time, so zstd shouldn't be so bad (it's still much much faster than swap
on disk). Interestingly, CPU hogging problem that I faced with lz4 went away with zstd.

### Overheating

Without any way to control heat, my Pi would quickly reach temperatures around 85°C on load which seems
to kick-in thermal throttling. The official RPi4 case made it worse.

I then got a aluminium passive cooling case. The temperatures still get around 80° on load but now take
couple minutes on constant load to get there, and I haven't come across any noticeable throttling so far.
So I've been keeping this so far.


## Software

### Docker

With self-hosting things, it can quickly get overwhelming to keep track of any vulnerabilities, updates,
breaking dependencies, so much more. Docker with portainer keep it good enough to help me deal with this.
This works well as I've noticed almost every self-hostable solution adds in support for Docker and provide
example stack configurations that can be plugged into portainer (or directly into docker). Spend some time
learning to manage volumes in docker to get an idea about how persistent storage works. Losing important
data when a running container goes down is no good.

I also like having this section for my docker compose configurations:
```conf
    extra_hosts:
    - "host.docker.internal:host-gateway"
```
It lets a service to interact with other services on my private tailscale network through MagicDNS domain
names.

### WiFi Issues

I've had problems with having my Pi long-term stay connected to my WiFi access point. There's a separate
[post](https://ritiek.github.io/2023/12/09/debugging-wifi-on-a-headless-raspberry-pi/) I wrote on it
recently.

### Decrypting LUKS

This is a preference on how someone'd like to mount their decrypt their encrypted partitions when mounting.
I've done a little shell script that I need to manually call that asks me for my LUKS passphrase/passfile
and mounts the decrypted partitions with my favourite mount options.

### Backups

[Borg](https://github.com/borgbackup/borg) or [Kopia](https://github.com/kopia/kopia) both work decent
for me with both onsite and offsite backups. I run them in Docker too, both on my Pi and the secondary
machines that keep the backups. I've found that Kopia needs HTTPS set up at least on the offsite repository
server to work correctly. `tailscale serve` worked nice when setting this up on my private tailscale network.
