+++
title = "Re-doing my Homelab with NixOS"
date = 2025-09-09
path = "2025/09/09/re-doing-my-homelab-with-nixos"
template = "page.html"
[taxonomies]
tags = []
+++

It's been close to 2 years since my earlier homelab post ([here](/2023/12/26/homelabbing-on-a-raspberry-pi-4/)).
I moved onto a shiny Raspberry Pi 5 shortly afterwards (from an RPi4) and worked on a few things. This
post is a continuity to how things have evolved in terms of my requirements and the solutions I now see
as a better fit.

The biggest change has been me migrating everything to NixOS, and it's been transformative for how I think about managing my homelab infrastructure.

## Why NixOS for a homelab?

When I first started self-hosting, I was managing services the traditional way: installing packages directly on the system, editing config files scattered across `/etc/`, and hoping I'd remember all the changes I made when something broke.

NixOS seems to help with this. Instead of imperatively configuring your system, you declare what you want in a configuration file, and NixOS builds the entire system through it. This means I can completely recreate my homelab setup on a fresh Raspberry Pi just by copying over my configuration files.

I've slowly migrated most of my machines to run NixOS, including my RPi5 role-playing as homelab. Diving
into NixOS has been one of the few significant investments that I'm really happy about. Beyond the obvious reproducibility benefits, NixOS fundamentally changes how I think about system complexity.

My current NixOS configuration can be found [here](https://github.com/ritiek/dotfiles/tree/f5b87e8fcd23ca6eb05ac79a2143319dbd9967a6). All the techniques I discuss below are implemented in this config, so you can see exactly how they work in practice.

## My approach to self-hosting

I got into self-hosting mostly because it seemed fun and tinkerable. However, with time it's become
pretty important to me, more so to resist stashing away more of my digital identity within walled gardens.

I tend to approach hosting services for personal use with a very long-term perspective. I've got services
like Immich (photo management) and paperless-ngx (document organization) that I've spent time curating carefully. They hold important paperwork and memories of loved ones. Lately I try to approach preserving them in a way I hope will outlive me, at least for a while.

I mainly run a few scheduled jobs and otherwise host services that tend to run idle most of the time, so
a low-powered and power-efficient machine like Raspberry Pis seems like a good deal to me. In the cases I
could use more power (such as AI inference or gaming with Sunshine game streaming), I'm okay with a little bit of wait and
offloading processing to a beefier machine.

## Setting up a NixOS homelab from scratch

One of the most satisfying aspects of NixOS is how I can generate a complete system image from my configuration. Here's my typical workflow when setting up or rebuilding my homelab:

### Building and deploying the system

NixOS lets me generate an image file of my entire configuration that I can
then write directly to a microSD card. It'll boot up on my Pi with all my
favorite packages pre-installed and my environment exactly as defined. However, since I use sops-nix to
store encrypted secrets directly in my config, there are a few additional steps I need to perform to get my homelab-specific private SSH key in place (this key allows sops-nix to decrypt my secrets).

The process looks like this:

1. **Build the system image** (preferably using an ARM64 machine for native compilation):
   ```bash
   $ cd /etc/nixos
   $ nix build .#pilab-sd
   ```

2. **Write the image to microSD**:
   ```bash
   $ pv ./result/sd-image/*.img.zst | unzstd | sudo tee /dev/sdc > /dev/null
   ```

3. **Initial boot setup**: Plug the microSD into my Pi and power it up.

4. **Add the decryption key**: Wait 3-4 minutes for the Pi to set up its directory structure, then power off and mount the microSD on another machine to place my private SSH key into Pi's `/etc/ssh/ssh_host_ed25519_key` (I wonder if it's possible to automate this step by inserting in a Yubikey at boot).

5. **Final boot**: Plug the microSD back into the Pi and boot it up.

That's it! I can now SSH into my Pi and be greeted with my complete environment. I can start my services using `sudo homelab-start`, which I've defined in my flake config.

No more spending hours trying to remember how I configured something months ago.

## Automating software updates safely

One challenge I faced early on was keeping my NixOS system updated. I initially started with NixOS stable channels, but quickly realized my favorite new features in tools like Hyprland (a tiling window manager) sometimes take a while to hit stable channels. I also had issues with screen-sharing.

I moved to unstable channels, but had a similar feeling of being a bit behind. Eventually, I decided to track nixpkgs master branch directly for the latest everything.

This created three problems I needed to solve:
1. **Staying current**: Updates should track upstream as closely as possible
2. **Avoiding broken updates**: Don't start an update if packages will break halfway through
3. **Reducing compilation time**: Avoid compiling everything on my local machines (since NixOS builds up official cache only once the packages reach unstable channels)

### My automated update solution

Here's the system I've developed and it's been running rock-solid for months:

**Daily automated testing**: GitHub Actions creates a pull request to my dotfiles repository every day with the most up-to-date package versions in my `flake.lock` file. For every such update, GitHub Actions attempts to build all packages for all my machines and pushes the resulting build cache to my RPi5.

**Binary cache hosting**: My RPi5 hosts an [Attic](https://github.com/zhaofengli/attic) server (think of it as a self-hosted binary cache for Nix packages). GitHub Actions can reach my RPi5 through my Headscale network (my personal VPN control server hosted on a VPS).

**Checks**: The PR only gets a green checkmark if all packages build successfully on all my machines. This means the update will go through successfully everywhere since I share my `flake.lock` between machines.

You can see an example of this automated process in [this PR](https://github.com/ritiek/dotfiles/pull/33).

**Manual approval**: I only accept updates by merging green PRs. After merging, I manually run `git pull` and `sudo nixos-rebuild switch --flake .#my-machine` on each machine. The build cache gets pulled from my RPi5's Attic server, so updates are fast.

**Recovery options**: If there's a runtime bug (not caught at compile time), I have two options:
1. Rollback to the previous NixOS generation and wait for the bug to be fixed upstream
2. Revert just the problematic package by pinning it to an older nixpkgs version

This setup gives me bleeding-edge packages with confidence that they'll actually work. Since implementing this system a few months ago, I haven't come across pushing any failing updates onto my machines.

## Backups with Restic

I moved from Kopia to Restic for backups because a single Kopia instance doesn't support backing up to multiple repositories, and I didn't want to maintain multiple Kopia instances. NixOS has a native Restic module that gives fine control over backup schedules, snapshot pruning, compression levels, and more.

### Why Restic works well in my setup

**Version compatibility**: My Restic backup servers and clients run on different machines, but they stay compatible because they use the same `flake.lock` file. All my machines run the same Restic version, so I never worry about client-server version mismatches.

**Encrypted credentials**: I store backup passwords and repository credentials encrypted using sops-nix, so they're version-controlled but secure.

**Monitoring integration**: My backup jobs send success/failure notifications to my self-hosted Uptime Kuma monitoring server (also running on the RPi5).

### Testing system recovery

For the system itself (not just data), I periodically test my disaster recovery process. I'll use my RPi4 to build a fresh image for my RPi5, flash it to a new microSD card, and boot my RPi5 from the new card. This simulates a "the microSD died" scenario and ensures I can actually recover my complete system setup.

My Restic configuration files are available in my dotfiles: [client config](https://github.com/ritiek/dotfiles/blob/f5b87e8fcd23ca6eb05ac79a2143319dbd9967a6/machines/pilab/services/restic.nix) and [server config](https://github.com/ritiek/dotfiles/blob/f5b87e8fcd23ca6eb05ac79a2143319dbd9967a6/machines/pilab/services/restic-server.nix).

## On-demand services to save memory

Running lots of containers on my RPi5's 8GB of RAM eventually became a bottleneck, even with zram compression. Rather than buying more hardware, I researched running non-essential services on-demand (when someone actually tries to access them).

### How on-demand services work

Services like Navidrome (music streaming), TubeArchivist (YouTube archival), and Memos (note-taking) don't need to run 24/7. I'm okay waiting a few seconds for these to start up when I want to use them.

Here's the technique I developed:

1. **Port monitoring**: socat listens for connections on the service's normal port
2. **Service startup**: When a connection is detected, the actual service launches on an internal port  
3. **Proxy mode**: socat forwards requests to the now-running service
4. **Automatic shutdown**: A monitor checks for active connections every ~10 minutes. If there are none, the service stops and socat resumes listening

You can see this implemented for Navidrome [here](https://github.com/ritiek/dotfiles/blob/f5b87e8fcd23ca6eb05ac79a2143319dbd9967a6/machines/pilab/compose/navidrome.nix).

This setup has freed up 1-2GB of physical memory (or 7-8GB accounting for zram compression) when services are idle. That's significant on an 8GB machine. I've extended this pattern to several other services like Mealie (recipe management) and HomeBox (inventory tracking).

The user experience is alrightish. These services usually start fast enough.

## Exposing services securely

Sometimes I need to share a service running on my RPi5 with friends or family who aren't part of my Tailscale network. For these cases, I run a reverse proxy using Nginx on my personal VPS, which routes requests through my RPi5 over my Headscale connection.

The VPS also runs NixOS. I can hand out a subdomain to friends, and they can access my service without needing special software or VPN access. More details about my VPS setup and how I use nixos-anywhere to install NixOS on providers that don't officially support it are [here](https://github.com/ritiek/dotfiles/tree/f5b87e8fcd23ca6eb05ac79a2143319dbd9967a6/machines/clawsiecats) (Vultr and HostVDS for now).

## Future plans: Wi-Fi router functionality

This is still an idea needing research, but I'm considering running a wireless access point from my RPi5. The goal would be to route all connected devices through a VPN automatically, avoiding the need to configure VPN on each device individually. I'd also like to explore OpenWrt-style features like VLANs for isolating sketchy IoT devices.

This appeals to me because I have a basic router and would rather avoid buying new hardware if I can integrate something like this into my RPi5 itself. It's currently connected to the Internet via an Ethernet cable anyway, so an access point off with this setup shouldn't be so bad I guess. NixOS on top should help me keep router-specific configuration manageable. I might do a post if this ever happens.

## Power consumption and hardware setup

My current setup includes three SSDs attached to my RPi5 and a few other peripherals:

1. First NVMe using the Pimoroni NVMe Base (for primary data storage)
2. Second NVMe in a USB enclosure via USB 3.0 (for on-site backups)
3. Third external SSD via USB 3.0 (for storing Attic build cache)
4. Official active cooler (minimal power draw)
5. USB 2.0 Wi-Fi dongle (for experimental Wi-Fi router functionality)

This entire setup consumes about 7.5-8.0W at idle (measured with a local Kill-A-Watt equivalent) and peaks at 11-13W under load.

When the two external drives suspend after periods of inactivity, power consumption further drops to around 6.5-7.2W at idle. I haven't seen it exceed 14W under load in real-world usage, which I'm happy with for the compute it provides.

## The NixOS advantage for homelabs

Simple things that used to require research and manual setup are now just configuration options. Take zram (memory compression) as an example: on other distributions, I'd need to find a userspace program, set up systemd services, and hope it all works together.

With NixOS, zram is a simple `zramSwap.enable = true;` or watchdog is `systemd.settings.Manager.RuntimeWatchdogSec = 360;` in my configuration. Although, this is not to say it's all glitters. It definitely has it quirks, but those somewhat make sense too when looking at them through the lens of NixOS trying to be as reproducible as possible.
