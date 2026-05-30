# Proxmox VM Setup for Containerlab

Checklist to provision the VM that will host containerlab.

## 1. VM Sizing

| Resource | Recommended | Notes |
|---|---|---|
| OS | Debian 12 or Ubuntu 24.04 LTS | Both work; Ubuntu has slightly newer Docker repo |
| vCPU | 4 | Bump to 6–8 for larger topologies |
| RAM | 8 GB | cEOS ~1 GB/node, SR Linux ~600 MB/node |
| Disk | 40 GB+ | NOS images are 500 MB–2 GB each |
| Network | Bridged to LAN (`vmbr0`) | So you can SSH and reach mgmt IPs |
| Nested virt | Not required | Containerlab uses containers, not VMs |

> **Watch where `/var` lives.** Docker's data-root is `/var/lib/docker`, so the
> images (cEOS ~2.6 GB + multitool/FRR/tacacs/prometheus/grafana for the later
> labs ≈ 5 GB total) land on whatever volume holds `/var`. A default Debian LVM
> install often puts `/var` on a **small separate logical volume** that fills up
> and gives `failed to register layer: no space left on device` on `docker pull`
> — even when `df -h /` shows plenty free. Check with `df -h /var`. If it's small
> and the volume group has free extents (or the disk has unpartitioned space you
> can `growpart`/`sfdisk -N` the PV partition into), extend it online:
>
> ```bash
> # if the disk has unpartitioned space after the PV partition, grow it first:
> #   sfdisk -N <n> --no-reread --force /dev/sda   (start unchanged, size to end)
> #   partx -u /dev/sda && pvresize /dev/sdaN
> sudo lvextend -L +40G /dev/vg0/var      # or -l +100%FREE
> sudo resize2fs /dev/mapper/vg0-var
> ```

## 2. Proxmox VM Creation

1. Upload Debian 12 / Ubuntu 24.04 cloud image or ISO to Proxmox.
2. Create VM:
   - BIOS: OVMF (UEFI) or SeaBIOS — either works
   - Machine: q35
   - SCSI controller: VirtIO SCSI single
   - Network: `virtio`, bridge `vmbr0`
3. Boot, install OS, set static IP or DHCP reservation on your router.
4. Enable SSH, add your public key, disable password auth.

## 3. Host Packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl ca-certificates gnupg lsb-release iproute2 tcpdump
```

## 4. Install Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# log out and back in
docker run --rm hello-world
```

## 5. Install Containerlab

```bash
bash -c "$(curl -sL https://get.containerlab.dev)"
containerlab version
```

## 6. Deploy This Repo to the VM

Pick one:

### Option A — Pull from GitHub (simplest)

```bash
cd ~
git clone <repo-url> containerlab
cd containerlab
```

Updates: `git pull`.

### Option B — Bare repo + post-receive hook (push directly from laptop)

On the VM:

```bash
mkdir -p ~/repos/containerlab.git && cd ~/repos/containerlab.git
git init --bare
mkdir -p ~/containerlab
cat > hooks/post-receive <<'EOF'
#!/bin/sh
GIT_WORK_TREE=$HOME/containerlab git checkout -f main
EOF
chmod +x hooks/post-receive
```

On the laptop:

```bash
git remote add vm ssh://user@vm-ip/~/repos/containerlab.git
git push vm main
```

## 7. NOS Images

Free / no-registration:
- **FRR** (`frrouting/frr`) — open-source routing suite, great for L3 fundamentals
- **Nokia SR Linux** (`ghcr.io/nokia/srlinux`) — fully free, full-featured
- **SONiC** (`docker-sonic-vs`) — open NOS, datacenter-flavored

Registration / vendor-gated:
- **Arista cEOS** — free with Arista account, download tarball, `docker import`
- **Cisco XRd / 8000v** — Cisco account required

Document image-specific notes under `images/<vendor>.md` as we use them.

## 8. Sanity Test

Once containerlab is installed, try the built-in demo:

```bash
mkdir -p ~/scratch && cd ~/scratch
containerlab generate --name test --kind nokia_srlinux --nodes 2 --image ghcr.io/nokia/srlinux:latest > test.clab.yml
sudo containerlab deploy -t test.clab.yml
sudo containerlab destroy -t test.clab.yml --cleanup
```

If both nodes come up and you can SSH into them, the VM is ready.
