+++
title = "Quirks of self-hosting an overlay networking tool (ft. Headscale)"
date = 2026-03-06
path = "2026/03/06/quirks-of-self-hosting-an-overlay-networking-tool-ft-headscale"
template = "blog/page.html"
[taxonomies]
tags = []
+++

I self-host headscale on a VPS through the built-in NixOS module to remotely access a handful of personal devices
and I find it works well. Within the last month, my headscale stopped working somehow due to a database migration
issue resulting in a schema mismatch after I updated my nixpkgs flake input. Looking up, I wasn't able to find anyone
with a similar issue recently, so it seemed like a one-off issue that happened to me somehow. Also, booting into
a previous generation or rebuilding the config from the previous commit didn't help as it wouldn't revert the
migration (which is expected since headscale's `db.sqlite` isn't tracked by the NixOS module). I track the `master`
branch on nixpkgs for my updates. I had to purge headscale's database to start over and re-connect all my personal
devices through a new pre-authkey. Luckily I had physical access or alternate means to reach all my personal
devices that I wanted to re-connect, but this could've otherwise ended up badly for me.

## Lack of complete declarability

The core idea of why I lean towards NixOS is the ability to reproduce the machine state entirely through my flake
config. I guess this comes down to a matter of perspective and the gray area of what one considers as machine state
versus runtime state.

The headscale NixOS module defines its options [here](https://search.nixos.org/options?channel=unstable&query=headscale) and this module lacks the options to declare clients, which 
makes sense since it's currently not even possible to declare clients in headscale itself. It seems this capability
is not currently planned for after going through headscale's issue tracker ([#662](https://github.com/juanfont/headscale/issues/662), [#666](https://github.com/juanfont/headscale/pull/666), [#1855](https://github.com/juanfont/headscale/issues/1855)).

This makes things a lil problematic to me. It means I cannot immediately re-spin another VPS exactly as it was in
case my VPS goes down for whatever reason. I could keep a backup of my headscale DB (as well as `derp_server_private.key`
and `noise_private.key` which are used for identification purposes) somewhere. But I don't wanna introduce another
component into my homelab environment entirely for the sake of storing a DB that takes up few hundred KBs of storage.
And I also can’t store the DB backup on my personal devices. Reaching those devices remotely requires Headscale itself,
which creates a chicken-and-egg problem. It looks like at the moment there is no overlay networking tool around that
provides complete declarability except for [Nebula](https://github.com/slackhq/nebula), which unfortunately doesn't provide MagicDNS-like functionality and exit-node relays convenience features which I really like (happy to learn if there exists one that is both declarable
enough and provides these convenience functionality!). I guess I could glue my own DNS and iptables rules but I think
I'd rather lean on a battle-tested solution for now. I also got to try out NetBird and read about Netmaker and ZeroTier
but these suffer from same lack of client-level declarability.

So for now, I decided to sops-nix encrypt my `db.sqlite` as well headscale keys into my NixOS config ([here](https://github.com/ritiek/dotfiles/blob/171a942263668558000207dcde8b52e195a8dca5/machines/clawsiecats/services/headscale/default.nix)) which works well for now! I've tried setting up my personal devices into my headscale network and then deleting
my `/var/lib/headscale`. This brings the control plane back online after a reboot, and my client devices reconnect
without any manual intervention.

## Cloud-based overlay networking tool as a fallback

This incident scared me off a little. So I decided to have a cloud-based overlay networking tool as a fallback just
in case something goes wrong with my self-hosted headscale. I've been using NetBird for this and I like it. This is
a nice-to-have as there may be more scenarios that I may not have thought of or have accounted for at present. This to
me seems like a nice balance between not relying entirely on a cloud-based overlay networking tool while also having
complete control of my own networks.
