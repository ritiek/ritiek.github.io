---
title: "Sharing Yubikey over the network"
date: 2023-11-14
layout: post
comments: false
tags:
  - linux
---

At any point in this post, whenever I mention the term
[Yubikey](https://www.yubico.com/products/how-the-yubikey-works/), what I really mean is any hardware-based
authentication device that supports [FIDO2](https://fidoalliance.org/fido2/).

I think writings here'll mostly interest people who consider Yubikey in their threat model.

------------------------------

## Why? Isn't the major point about owning a Yubikey is to make online passwords a physical problem?

There seems to be a consensus (for good reasons) to have at least one offsite backup whenever possible for
most things holding digital value, be it storage backups (3-2-1 backup strategy at the least) or Yubikeys.

There's a problem with this, how to keep the offsite backups up to date with our primary media?
For storage media, having an offsite server running a backup service like
[borg](https://github.com/borgbackup/borg) or [kopia](https://github.com/kopia/kopia) over the network seems
a decent choice.

But what about keeping the Yubikey up to date in an offsite location?

I've read some people use Yubikeys as a passkey or as a 2FA method to their password manager. So if we've
got the offsite Yubikey setup as authentication method to unlock our password manager's vault beforehand,
then we should be able to store any other sensitive stuff later on inside of our password manager, as the
offsite Yubikey would only need to unlock our password manager's vault to give us back access to everything.
If our password manager supports it, we can also store passkeys digitally for other services inside our
password manager, and have our Yubikey act as the master passkey to unlock our vault.

This is nice and in this case, people for the most part don't have to go through the hoops in order to keep
their offsite Yubikey synced up, because they don't need to.

Having an offsite Yubikey makes sense to me. But how prepared would we be to retrieve the offsite Yubikey
when a calamity (a Tsunami?) ensues and:

1. Destroys our primary site and we lose access to not only our primary Yubikeys but also our home,
   mobile phones, paper money, and even access to the city's vehicular transport system; each of which seems
   to significantly multiply the difficulty in order for us to physically retrieve the offsite Yubikey.

2. In an extreme scenario, we happen to be unfortunate enough to hit our fleshy human heads on concrete
   (memory loss) during the disaster unfolding, or fail to make it out at all.


For the 2nd point, life support should preceed everything else. I think it's nice to have an offsite
[executor](https://www.reddit.com/r/Bitwarden/comments/q0m19n/on_dying_and_your_password_vault/),
a trusty someone who could take their time to help us with our digital stuff as we start to gain back sense
of self-awareness, or otherwise give the digital us a closure if we're no longer around.

In scenarios similar to 1st point, where we lose our possessions but happen to be physically okay enough,
and want to gain back access to our digital vaults; physically retrieving the offsite Yubikey may not always
sound like a plan.

What I think might work in such scenarios would be to have a trusty person under the same roof where the
offsite Yubikey lives. We can share this offsite Yubikey over to us through the Internet in our SOS situation,
and have our trustypie person finger tap authenticate the Yubikey for us. This way, the offsite Yubikey should
still partially get to keep its job to make online passwords a physical problem, while also being useful to us
remotely.

## Doin' it!

I tried plugging in a Yubikey into my Raspberry Pi located in an (imaginary) offsite location and setting up USB
sharing to my primary machine using [USB/IP](https://wiki.archlinux.org/title/USB/IP); seems a good enough way
to me. The linked arch wiki page should be a good starting point.

Here's what I had to do on my Raspberry Pi (server):

```bash
$ sudo apt install -y usbip
$ sudo modprobe usbip_host
$ sudo usbip list -l
...
 - busid 1-1.3 (1050:0402)
   Yubico.com : Yubikey 4/5 U2F (1050:0402)
...
# ^Note Yubikey's busid: 1-1.3.

# Pass Yubikey's busid below in `ExecStartPost` and `ExecStop`.
$ echo """[Unit]
Description=USB-IP Binding
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/sbin/usbipd
ExecStartPost=/usr/sbin/usbip bind -b 1-1.3
ExecStop=/usr/sbin/usbip unbind -b 1-1.3

[Install]
WantedBy=multi-user.target""" | sudo tee /etc/systemd/system/usbip-yubikey.service

$ sudo systemctl daemon-reload
$ sudo systemctl start usbip-yubikey

# Optional: Auto start usbip server on boot.
$ echo usbip_host | sudo tee /etc/modules-load.d/usbip.conf
$ sudo systemctl enable usbip-yubikey
```

And on my primary arch machine (client):

```bash
$ sudo pacman -S usbip
$ sudo modprobe vhci-hcd
$ sudo usbip attach -r <pi-ip-address> -b 1-1.3

# Optional: Auto load vhci-hcd kernel module on boot (won't have to `modprobe vhci-hcd` on every boot).
$ echo vhci-hcd | sudo tee /etc/modules-load.d/usbip.conf
```

Once setup, my primary machine works as if the remote Yubikey is physically connected to it.
You can try it out by doing something that'll invoke the Yubikey for authentication. As of writing, it looks
like USB/IP sends unencrypted data over TCP which could be a security concern. So you'd probably want to
setup a VPN and make USB/IP connections over it securely ([tailscale](https://github.com/tailscale/tailscale)
is fun).

------------------------------

**There could be more implications behind the entire idea, as well as setting up something like this.
It'll be wise to research more before pushing something like this into production.**

------------------------------

## Blub/netevent

I wrote about [Blub/netevent](https://github.com/Blub/netevent) in
[one of my earlier posts](https://ritiek.github.io/2019/02/18/sharing-linux-event-devices-with-other-linux-machines/)
which works well with sharing `/dev/input/event*` devices, something which doesn't seem possible with
USB/IP (I probably won't be able to share input from my mobile phone's power button to my laptop with USB/IP,
but I got it working back then using netevent as mentioned in the linked post).

On the contrary, sharing USB devices (Yubikey [shows up in `/dev/hidraw*`], USB storage devices, etc.)
isn't possible with netevent.

That said, both netevent and USB/IP still seem to have a bit of overlapping functionality (I should be able
share my USB Mouse and USB keyboard using either of USB/IP or netevent, as this'll be detected as a USB device
[works with USB/IP], as well as show up in `/dev/input/event*` [works with netevent]).
