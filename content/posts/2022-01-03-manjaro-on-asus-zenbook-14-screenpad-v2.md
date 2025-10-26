+++
title = "Installing Manjaro on ASUS Zenbook 14 (with ScreenPad 2.0)"
date = 2022-01-03
path = "2022/01/03/manjaro-on-asus-zenbook-14-screenpad-v2"
template = "blog/page.html"
[taxonomies]
tags = []
+++

Notes on ASUS Zenbook 14 having the ScreenPad 2.0

I started off with installing Manjaro v21.2.0 with kernel v5.15.7 on this little machine.

## Sound

Sound didn't work for me. I found two ways on the Internet I could get it to work.
```bash
$ lshw
...
*-multimedia
     description: Multimedia audio controller
     product: Tiger Lake-LP Smart Sound Technology Audio Controller
     vendor: Intel Corporation
     physical id: 1f.3
     bus info: pci@0000:00:1f.3
     version: 20
     width: 64 bits
     clock: 33MHz
     capabilities: bus_master cap_list
     configuration: driver=sof-audio-pci latency=32
     ...
...
```

The configuration driver was set to `sof-audio-pci` by default. Seems like Manjaro didn't
come with these drivers pre-installed with the distro. All I had to do was run:
```bash
$ sudo pacman -S sof-firmware
```

Other method that worked for me was to fallback on Intel drivers:
```yaml
# /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="... snd_hda_intel.dmic_detect=0"
```

Reboot in either case.

## Suspend

Waking up from suspend froze the machine. This got fixed when I moved (downgraded?) to LTS
kernel v5.10.84.

## ScreenPad 2.0

ScreenPad 2.0 gets detected as a second display. I had to install a kernel module to be able to
adjust the brightness on this display:<br>
[https://aur.archlinux.org/packages/asus-wmi-screenpad-dkms-git/](https://aur.archlinux.org/packages/asus-wmi-screenpad-dkms-git/)

I also wrote a very simple shell script to turn off the display or adjust the brightness:<br>
[https://github.com/ritiek/dotfiles/blob/master/spad.sh](https://github.com/ritiek/dotfiles/blob/master/spad.sh)
