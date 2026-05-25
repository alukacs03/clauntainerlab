# Arista cEOS

Arista's containerized EOS. Free to use, but the image is gated behind an Arista account — must be downloaded manually, then `docker import`-ed on the VM.

## One-time: get an Arista account

1. Register at <https://www.arista.com/en/user-registration> (free, just an email + a few profile fields — "self-study / lab" is a fine role).
2. Wait for the activation email, then log in.

## Download the cEOS tarball

1. Go to <https://www.arista.com/en/support/software-download>.
2. Under **EOS** → **cEOS-lab**, pick a recent stable release (e.g. `cEOS-lab-4.32.x.x.tar` — avoid `-INT` and `-F` builds for first labs; pick a regular `.tar`).
3. Download it to your laptop. Note the exact version string in the filename — you'll use it as the Docker tag.

## Copy the tarball to the VM

From your laptop:

```bash
scp cEOS-lab-4.32.2F.tar root@<vm-ip>:/root/
```

(Adjust user and path to your VM. Example below assumes `/root/`.)

## Import as a Docker image

On the VM:

```bash
cd /root
docker import cEOS-lab-4.32.2F.tar ceos:4.32.2F
docker images | grep ceos
```

The tag (`4.32.2F` here) is what you'll reference in `topology.clab.yml`. Keep the tarball around if you want to re-import after a Docker prune; otherwise you can delete it.

## Use in a containerlab topology

```yaml
name: ceos-demo
topology:
  nodes:
    sw1:
      kind: arista_ceos
      image: ceos:4.32.2F
    sw2:
      kind: arista_ceos
      image: ceos:4.32.2F
  links:
    - endpoints: ["sw1:eth1", "sw2:eth1"]
```

Containerlab knows the `arista_ceos` kind and will handle the cEOS-specific startup ceremony (mounting `flash`, initial `EOS-startup-config`, etc.).

## Notes & gotchas

- cEOS uses ~1 GB RAM per node when idle. Two switches = ~2 GB. Plan topology sizes accordingly.
- First boot is slow (~30–60s) while EOS initializes. `containerlab deploy` will wait.
- The startup-config (`startup-config: configs/sw1.cfg` in the topology) runs at boot — perfect for declarative VLAN/interface setup in labs.
- If you ever need a newer cEOS, repeat the import with a new tag (e.g. `ceos:4.33.0F`) and bump the `image:` in your labs. Don't reuse a tag across versions.
