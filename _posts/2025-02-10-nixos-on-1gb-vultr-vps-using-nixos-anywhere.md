---
title: NixOS on 1 GB Vultr VPS using nixos-anywhere
date: 2025-02-10
layout: post
comments: false
tags:
  - linux
---

It seems we can override a machine's OS with a simple flake-based NixOS configuration using
nixos-anywhere, like so:

```bash
$ nix run github:nix-community/nixos-anywhere -- \
  --flake .#yummyflake root@12.121.212.121
```

What I mean by 'simple NixOS configuration' is - a configuration with none of these features:
LUKS encryption, impermanence, or secrets provisioning (sops-nix, agenix, etc.). Although, the 
configuration must perform some kind of disk partitioning using disko, for nixos-anywhere to do
its magic. Such an install should go smooth enough without the need of manual intervention at
any step during the process.

However, the flake-based NixOS configuration I'll be installing on a Vultr VPS is for a machine
that goes by clawsiecats. This machine configuration is publicly available here:

[https://github.com/ritiek/dotfiles/blob/2d99108/machines/clawsiecats](https://github.com/ritiek/dotfiles/blob/2d99108/machines/clawsiecats)

It enables all of the NixOS specific features mentioned above - BTRFS partitioning on LUKS,
impermanence, and secrets provisioning using sops-nix.

This is what makes things a little trickier. The rest of the post is mainly me talking about
setting up these features in NixOS configuration so that the configuration can be deployed using
nixos-anywhere with the least amount of manual intervention, on a Vultr VPS (adaptable to
other hosting providers usually, only difference should be the partitioning scheme [GPT/MBR]
used by the hosting provider).

If the reader is following this guide with care then it's recommended to open
the above link to my machine's configuration (which is Vultr ready including all these features)
and go through it side-by-side along with this
guide as there are a lot of references to it to help things make sense.


## Secrets Provisioning (sops-nix)

There's agenix and many more that seem nice. Up to you. I'm currently using sops-nix so I'll
dive into it here. Start by adding sops-nix as an input in your flake:

```nix
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

sops-nix allows to provision machine specific secrets, and I tie my secret key to my machine's
private SSH host key. I keep this private SSH host key unique for every machine configuration.

```nix
sops = {
  defaultSopsFile = ./../machines/${config.networking.hostName}/secrets.yaml;
  age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
};
```


```yaml
# ./machines/clawsiecats/secrets.yaml
#
# My version of this file can be found here:
# https://github.com/ritiek/dotfiles/blob/2d99108/machines/clawsiecats/secrets.yaml

jitsi.htpasswd: ENC[AES256_GCM,data:abc...,iv:xy...z=,tag:qwe...type:str]
tailscale.authkey: ENC[AES256_GCM,data:xy...z,iv:ab...c,tag:rty...,type:str]
sops:
    shamir_threshold: 1
    kms: []
    gcp_kms: []
    azure_kv: []
    hc_vault: []
    age:
    ...
```

`secrets.yaml` can be edited using the following:

```bash
$ nix run nixpkgs#sops edit ./machines/clawsiecats/secrets.yaml
```

Running this may prompt for 2FA on our key, if it's set up.


## Impermanence

This seems mostly to be a NixOS concept mainly achieved by mounting `/` as `tmpfs`.
The idea, is that we perform bind mounts or create symlinks inside `/` that point to the actual
persistent files and directories mounted somewhere else (this stuff we explicitly specify to
preserve).

This is supposed to help mitigate the lingering build up of files that could potentially get
in the way of purity of NixOS (we ideally wouldn't want a program to imperatively read and write
its config in `/etc/` in NixOS) as any residual files that get created in `/` will automatically
be cleaned up on reboot (since `/` is `tmpfs` living in memory or swap).

I use impermanence in my configuration setup. Impermanence can be set up using custom solutions
for syncing `/` from our persistent storage. Anyway, I'll be using the impermanence module
which seems to solve this pretty well (through bind mounts and symlinks). Add the module as an
input to your flake with:
```nix
impermanence.url = "github:nix-community/impermanence";
```

There are a few important files present under `/` that should be persisted, such as host SSH
keys which we'll be persisting in the next step and `/etc/machine-id` which is what many
processes depend on to identify themselves that they're running on the same machine in the
case the process restarts (we wouldn't want maybe ACME certificates to be re-generated on
every reboot since `/etc/machine-id` would be re-created if we were not to persist it).

For now, we'll generate a `/etc/machine-id` locally which we'll transfer to our target
machine later under the persistent storage.
Let's create a directory on our local machine first where we'll store all the files that we'd
like to transfer to our target machine when nixos-anywhere gets invoked:

```bash
$ export BASEDIR="$(pwd)/mnt"
```

```bash
$ systemd-machine-id-setup --root="$BASEDIR"/nix/persist/system/

# If impermanence weren't setup, then we'd have moved this file
# under /etc/, like so:
# $ systemd-machine-id-setup --root="$BASEDIR"/etc/
```


## BTRFS on LUKS

Now to set up encryption at partition level. List `disko` as an input in your flake if not
already:

```nix
disko = {
  url = "github:nix-community/disko";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

and configure an encrypted partition, for example:

```nix
disko.devices.disk.clawsiecats.device = lib.mkDefault "/dev/vda";
disko.devices.disk.clawsiecats.content = {
  type = "gpt";
  partitions.esp = {
    size = "200M";
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot";
    };
  };
  partitions.luks = {
    content = {
      type = "luks";
      name = "cryptnix";
      settings.allowDiscards = true;
      # We'll be providing this key when invoking nixos-anywhere.
      passwordFile = "/tmp/disk.key";
      # NOTE: Use `pbkdf2` instead of `argon2id` for a lower
      #       memory footprint.
      # extraFormatArgs = [ "--pbkdf pbkdf2" ];
      content = {
        type = "btrfs";
        mountpoint = "/nix";
        mountOptions = [
          "noatime"
          "compress-force=zstd:3"
        ];
        extraArgs = [ "-Lcryptnix -f" ];
      };
    };
  };
};
```

The way I currently deploy nixos-anywhere to handle LUKS using my configuration is - I first
generate a random SSH key pair and store the private key from this key pair on the target
NixOS machine, specifically here `/boot/ssh_host_ed25519_key`.

```bash
$ install -d -m755 "$BASEDIR"/boot/
$ ssh-keygen -t ed25519 -a 100 -N "" -f "$BASEDIR"/boot/ssh_host_ed25519_key
```

This private SSH key will be used for hosting a dropbear SSH server on initrd.
I'll connect to this server and provide the key to decrypt my LUKS block device. This will
allow the machine to boot into stage 2.

Add the following configuration to your target machine to setup the dropbear SSH server:

```nix
boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "sr_mod" "virtio_blk" "virtio_pci" "virtio_net" ];
boot.initrd.kernelModules = [ ];
boot.initrd.network = {
  enable = true;
  ssh = {
    enable = true;
    port = 2222;
    hostKeys = [ "/boot/ssh_host_ed25519_key" ];
    authorizedKeys = config.users.users.your_username.openssh.authorizedKeys.keys;
  };
  postCommands = ''
    echo 'cryptsetup-askpass' >> /root/.profile
  '';
};
```

I fetch my private SSH key for this machine which is also stored encrypted in my repository -
`./machines/secrets.yaml`. This file would look something like this:

```bash
# ./machines/secrets.yaml
#
# My version of this file can be found here:
# https://github.com/ritiek/dotfiles/blob/2d99108/machines/secrets.yaml

clawsiecats_ssh_host_ed25519_key: ENC[AES256_GCM,data:abcde...=,tag:xyz...==,type:str]
```

The file is encrypted through sops:
```
$ nix run nixpkgs#sops -- edit ./machines/secrets.yaml
```

I'll extract the private SSH key for the target configuration that I am to be deploying,
and also store it a file:

```bash
$ export BASEDIR="$(pwd)"/mnt
```

```bash
$ nix run nixpkgs#sops -- decrypt ./machines/secrets.yaml \
  --extract '["clawsiecats_ssh_host_ed25519_key"]' \
  --output "$BASEDIR"/nix/persist/system/etc/ssh/ssh_host_ed25519_key
$ chmod 600 "$BASEDIR"/nix/persist/system/etc/ssh/ssh_host_ed25519_key
```

We'll also store the public key corresponding to this private key:
```bash
$ ssh-keygen -y -f \
  "$BASEDIR"/nix/persist/system/etc/ssh/ssh_host_ed25519_key \
  > "$BASEDIR"/nix/persist/system/etc/ssh/ssh_host_ed25519_key.pub
```

We want NixOS on target machine to be able to access this decrypted private SSH key.
This step is important as this private key provides access to target machine configuration
specific secrets, listed in ./machines/clawsiecats/secrets.yaml

We'll need to push our LUKS key to the target machine so that the target machine can use it
to encrypt the disk. Looks like nixos-anywhere has an option for this
`--disk-encryption-keys`.


## Invoke nixos-anywhere

We'll be installing NixOS on a Vultr instance with only 1 GB RAM. When booting our 1 GB
instance with Debian, I've noticed that nixos-anywhere fails half-way due to target
machine running out of available memory.

This issue also happens if I boot the machine with official NixOS installer image, which is a
bit surprising since in this case nixos-anywhere doesn't even call `kexec`. My idea was that
since `kexec` tends to load NixOS in memory when the base OS is not NixOS (the case with
Debian), this leaves a bigger memory footprint. I was hoping it would be enough to start off
with the base OS as NixOS so that `kexec` doesn't get called, but alas.

With neither of these methods working, I tried writing my own minimal NixOS configuration with
ZRAM setup as linked below, which seems to work!
[https://github.com/ritiek/dotfiles/blob/2d99108/generators/minimal.nix](https://github.com/ritiek/dotfiles/blob/2d99108/generators/minimal.nix)

Replace `users.users.root.openssh.authorizedKeys.keys` in the above configuration with how
you'll be identifying yourself.

I build an ISO out of this configuration. This can be done by adding nix-generators as an
input in your flake.nix:
```nix
nixos-generators = {
  url = "github:nix-community/nixos-generators";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

and defining an output target, such as:
```nix
# My version of this file can be found here:
# https://github.com/ritiek/dotfiles/blob/2d99108/flake.nix#L265-L270

minimal-iso = inputs.nixos-generators.nixosGenerate {
  system = "x86_64-linux";
  modules = [ ./generators/minimal.nix ];
  specialArgs = { inherit inputs; };
  format = "iso";
};
```

and invoking:

```bash
$ nix build .#minimal-iso
```

should generate an image in `./result/iso/nixos-25.05.20250117.08a54ef-x86_64-linux.iso`.

It's possible to upload and boot from a custom ISO image through the Vultr dashboard and that's
what we'll do here with this generated image. We'll need to publicly host our image file
somehow since Vultr takes a URL to the custom image. Not covering this here.

We'll also need to remount the writable tmpfs nix store on our target machine to allocate more
space, otherwise nixos-anywhere tends to run out of space:
```bash
$ ssh root@12.121.212.121 "mount -o remount,size=512M /nix/.rw-store"
```

With all of this in place, invoking nixos-anywhere should now successfully do its thing!

This is how we'll invoke it so that it pushes the disk encryption key as well as the files
that we'd like to persist on our target NixOS machine:
```bash
$ export LUKS_PASSPHRASE="my_strong_password"

$ nix run github:nix-community/nixos-anywhere -- \
  --extra-files "$BASEDIR" \
  --flake .#clawsiecats root@12.121.212.121 \
  --disk-encryption-keys /tmp/disk.key <(echo "$LUKS_PASSPHRASE")
```

To avoid this work every time we are to be deploying the configuration on a new machine, I've
made a script that'll automatically create SSH keys and other necessary files, remount the nix
store, push the files on to our target machine, and invoke nixos-anywhere with the right
parameters:
[https://github.com/ritiek/dotfiles/blob/2d99108/machines/clawsiecats/anywhere.sh](https://github.com/ritiek/dotfiles/blob/2d99108/machines/clawsiecats/anywhere.sh)

Once we've the target machine booted into minimal NixOS ISO, we can call this script locally
using:
```bash
$ ./machines/clawsiecats/anywhere.sh .#clawsiecats-luks root@12.121.212.121 --luks
```

The installation should succeed and the machine should reboot automatically. We can now detach
our minimal ISO image using the Vultr dashboard and have the machine boot into the NixOS we
just installed. We'll need to SSH into port 2222 and enter the decryption key to move further
into the boot process:
```bash
$ ssh root@12.121.212.121 -p 2222
```

We should now be dropped onto all the tooling and fluffiness defined in our flake:
```bash
$ ssh your_username@12.121.212.121
```

That should be all!
