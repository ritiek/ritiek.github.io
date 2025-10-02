---
title: "Setup local network hostname resolution through Pi-hole"
date: 2025-10-02
layout: post
comments: false
tags:
  - linux
---

I have lots of devices connected to my parents' local network - Computers, RPis, phones, cameras, ESP8266/32s
based smart switches/sensors. To the point where it'd exhaust my (ISP-provided) router's DHCP reservation
list. Most of them are hosted with some kind of network service that I need to access every now and then.
This gets tricky, because it's acceptable for some of them to have downtime which causes my router to assign
a different IP address to these devices when they next come up online after their DHCP lease happens to have
expired. The router lets me reserve IP addresses for only a handful of devices before it
stops accepting any more entries. Even so, I still have to remember and enter IP addresses around or worse -
look them up on my router's DHCP reservation list to figure out what hostname is assigned what IP address.

I remember coming across mDNS in the past which'd let me resolve IP addresses by the device hostname.
I used to be able to access Pi-hole by entering `http://pihole.lan/` on one of my Pis inside the
local network. Looking into it now, it seems mDNS requires special software to be installed on both the
client as well as the machine trying to access the client. I don't prefer setting up another software on my
machines. Nope, this solution isn't even practical for other devices on my local network like the ESP8266s.
I wanted to resolve the machines on my local network through an easy to remember hostname but not in the
mDNS way. Sounds like something I could do by setting my own DNS server inside the local network and then
have a DHCP server hand out this DNS server to the clients in the local network to resolve DNS queries.
I already host Pi-hole that my devices use as a DNS server to help keep unwanted traffic off my network.


## Keeping my local DNS server updated

It'd be nice to update my local DNS server's mapping of hostnames to IP addresses as close to real time as
possible as soon as a device on my local network gets assigned with an IP address. I could mostly identify
devices based on the MAC address of the connecting network interface.

So I prepared a mapping of MAC addresses to the hostname that I'd like them to resolve to, such as:
```
AA:11:BB:22:CC:33 - desktop-computer.pihole
A1:B1:A2:B2:A3:B3 - camera-1.pihole
...
```

There are then two ways I could think of to achieve this. These are as described below.

### 1. Host both my own DNS server as well as a DHCP server

Pi-hole has a built-in DHCP server. Every time it'd hand out an IP address, it'd map the MAC address of the
client that requested for DHCP allocation to the IP address it just handed out. This would look something
like this:
```
AA:11:BB:22:CC:33 - 192.168.1.2
A1:B1:A2:B2:A3:B3 - 192.168.1.3
...
```

Pi-hole would then be able to take the MAC address to hostname mapping that I prepared previously and it
could then create a local DNS entry that'd map IP address to the corresponding hostname that I assigned to
a MAC address. These local DNS entries created would then look like this:
```
192.168.1.2 - desktop-computer.pihole
192.168.1.3 - camera-1.pihole
...
```

Pi-hole has a well-documented API to programmatically create local DNS entries that could work well for such
a case. This approach would also neatly update the DNS entries in real-time. All the locally assigned DNS
entries would show up in Pi-hole WebUI in Settings -> Local DNS Records. Any devices whose MAC addresses
haven't been accounted for in my MAC address to hostname mapping could get a hostname of, say
`unknown-device-AC-CA-BD-DB-CE-EC.pihole`.

### 2. Extract ARP table off my router

For the previous setup to work reliably, my Pi-hole needs to be on whenever my router is on. Right now, I’m
not sure I can keep the Pi-hole running all the time. I don’t want to add another device (even a small one
like a Raspberry Pi Zero W) just to run Pi-hole and handle DHCP, because that would introduce another failure
point in my network. To use Pi-hole for DHCP, I’d have to turn off the DHCP on my router. So, if Pi-hole
goes offline even while the router is working, devices still won’t be able to obtain IP address leases. It'd
require both of them to be online at the same time for connections to work properly.

I imagined I could extract the latest ARP table off my router which'd give me MAC address to IP address
mapping, and then define new DNS entries based off my MAC address to hostname mapping that I created
previously. I'd then pass these DNS entries to my Pi-hole server so they can be resolved properly. I could
set my Pi-hole's IP address as the DNS server to hand out when issuing DHCP leases. This can be done inside
of my router's settings page. This would then assign Pi-hole as the DNS server to all the devices that are
part of the local network.

I went ahead with this approach given the drawbacks of the previous setup. With this approach, it doesn't
matter if my Pi-hole goes down, my machines would fallback to the next DNS server provided by DHCP as defined
in my router and at worst my machines wouldn't be able to resolve any custom-defined hostnames. The internet
and connections would still work normally otherwise. This implementation can be found in my Pi 5's NixOS
config in this commit
[`28bcb1b`](https://github.com/ritiek/dotfiles/commit/28bcb1bb2ede994677d78bfed3b995420a599a60).
It's been less than a week, too soon to say but so far so good.

I am able to extract the ARP table by
authenticating with the router programmatically on the HTTP port and then firing off another request to fetch
the relevant HTML page that contains the ARP table which can be parsed through regex. This procedure would
likely be different depending on the router firmware. Router and Pi-hole's
credentials are stored encrypted using sops-nix in the config itself. This systemd service runs every 30
minutes and updates the Pi-hole DNS entries as per the extracted ARP table. This has one caveat that the
local DNS could go out-of-date within those 30 minutes and would not be able to resolve any new IP address
leases to custom-defined hostnames until the service runs again.

I now point to my cameras in Frigate through my custom-assigned hostname. Both Frigate and Pi-hole run on
the same Pi 5 through different Docker compose configurations. I cannot access Pi-hole's container from inside Frigate using `127.0.0.1`. I also can't use `host.docker.internal` to refer to my host machine as
this hostname would itself have to be resolved in the first place so Docker doesn't allow referring to DNS
servers through hostname. To portably assign Pi-hole as a DNS server to Frigate, I had to set the DNS to
Bridge IP address utilized by my Docker socket as described in this commit
[`9d27048`](https://github.com/ritiek/dotfiles/commit/9d270486691e3aaaef55b30df2daff47bd8d5f06).
