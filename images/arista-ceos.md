# Arista cEOS

Arista's containerized EOS. Free to use, but the image is gated behind an Arista account — must be downloaded manually, then `docker import`-ed on the VM.

## One-time: get an Arista account

1. Register at <https://www.arista.com/en/user-registration> (free, just an email + a few profile fields — "self-study / lab" is a fine role).
2. Wait for the activation email, then log in.

## Download the cEOS tarball

1. Go to <https://www.arista.com/en/support/software-download>.
2. Under **EOS** → **cEOS Lab**, pick the latest `M` (Maintenance) release of a recent train — e.g. `4.35.4M`. Avoid `F` (Feature) builds for stable labs.
3. Download the **`cEOS64-lab-<version>.tar.xz`** variant (64-bit x86_64). Also grab the matching `.sha512sum` file for integrity checking.
   - `cEOS64-...` → x86_64 (this is what you want for a Proxmox VM)
   - `cEOS-...` (no suffix) → 32-bit x86, legacy, skip
   - `cEOSarm-...` → ARM (Pi, Apple Silicon native)

## Copy the tarball to the VM

From your laptop:

```bash
scp cEOS64-lab-4.35.4M.tar.xz cEOS64-lab-4.35.4M.tar.xz.sha512sum root@<vm-ip>:/root/
```

## Import as a Docker image

On the VM:

```bash
cd /root
sha512sum -c cEOS64-lab-4.35.4M.tar.xz.sha512sum
docker import cEOS64-lab-4.35.4M.tar.xz ceos:4.35.4M
docker images | grep ceos
```

`docker import` reads `.tar.xz` directly — no need to decompress first. The tag (`4.35.4M` here) is what you reference in `topology.clab.yml`. Keep the tarball if you want to re-import after a Docker prune; otherwise delete it to save the ~500 MB.

## Use in a containerlab topology

```yaml
name: ceos-demo
topology:
  nodes:
    sw1:
      kind: arista_ceos
      image: ceos:4.35.4M
    sw2:
      kind: arista_ceos
      image: ceos:4.35.4M
  links:
    - endpoints: ["sw1:eth1", "sw2:eth1"]
```

Containerlab knows the `arista_ceos` kind and will handle the cEOS-specific startup ceremony (mounting `flash`, initial `EOS-startup-config`, etc.).

## Notes & gotchas

- cEOS uses ~1 GB RAM per node when idle. Two switches = ~2 GB. Plan topology sizes accordingly.
- First boot is slow (~30–60s) while EOS initializes. `containerlab deploy` will wait.
- The startup-config (`startup-config: configs/sw1.cfg` in the topology) runs at boot — perfect for declarative VLAN/interface setup in labs.
- If you ever need a newer cEOS, repeat the import with a new tag (e.g. `ceos:4.33.0F`) and bump the `image:` in your labs. Don't reuse a tag across versions.
