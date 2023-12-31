Setup Hardware, Install Software
================================

This document details the setup and software installation onto the
hardware to be used as the PKI device.  These instructions are written
specifically for the [Big Tree Tech](https://bigtree-tech.com/)
[PI4B+CB1](https://biqu.equipment/collections/control-board/products/pi4b-adapter-v1-0)
(arm64), a Raspberry Pi clone.
These instructions should translate fairly easily to other platforms,
including x86_64, based on Linux.  Performance should not be a
limiting factor; 32 bit architectures should be sufficient, although
compiling some of the packages may require more work on 32 bit, which
has not been tested by me.

Bootstrap Board
---------------

* Download and install Armbian-CLI for BigTreeTech-CB1
  * https://docs.armbian.com/User-Guide_Getting-Started/
  * https://www.armbian.com/bigtreetech-cb1/  (latest "CLI" image)
  * (user: root  //  pass: 1234)
  * (re)set root password and shell
  * create regular user account
  * set timezone, language, locale

* Create `/etc/apt/apt.conf.d/90aptproxy` -> local apt-proxy (optional)

* Update firmware and packages
  * `apt update; apt upgrade`

* `armbian-config` -> change hostname to `pki.elfwerks`
  * https://docs.armbian.com/User-Guide_Armbian-Config/

* Install Ansible, vim, and git
  * `apt install ansible vim git`

* Uninstall email server exim
  * `apt purge exim4-daemon-light exim4-config`
  * `apt autoremove -y`

* Install regular user environment (optional)
  * Clone https://github.com/egustafson/env
  * `cd ~/env/ansible; ansible-playbook -i localhost ericg.yml -K`

* Reboot - mostly to check all of the install thus far, but does force
  kernel and daemons to be restarted.

## Host Configuration

* Verify hostname is set properly:  `hostnamectl set-hostname`
* NTP - (`timedatectl)
  * (if necessary)
    * edit `/etc/systemd/timesyncd.conf`
    * `systemctl restart systemd-timesyncd`
* `apt install prometheus-node-exporter`

Install Supporting Software
---------------------------

## Yubikey Manager and dependency `pcscd`

```
> sudo apt install yubikey-manager  # pcscd is included
> ykman info`                  # with a YubiKey inserted
... <output> ...
> sudo systemctl enable pcscd       # enable and start pcscd service
> sudo systemctl start pcscd
```

## `step` and `step-kms-plugin`

### Download and install `step` from GitHub
```
> curl -LO https://github.com/smallstep/cli/releases/download/<ver>/step_cli_<ver>_arm64.deb
> sudo apt install ./step_cli_<ver>_arm64.deb
> step version
```

### Download and install `step-kms-plugin` from GitHub
```
> curl -LO https://github.com/smallstep/step-kms-plugin/releases/download/<ver>/step-kms-plugin_<ver>_arm64.deb
> sudo apt install ./step-kms-plugin_<ver>_amd64.deb
> step kms version
```

## Build `step-ca` from source with YubiKey support enabled

The `step-ca` binary distribution does not include support for YubiKey
compiled in.  YubiKey support must be added by compiling the
executable from Golang source with the appropriate libraries
(libpcsclite) present.  `step-ca` will be installed in
`/usr/local/bin`

Additionally, the SD card used as root is very inefficient for such
compilation.  The following sequence of steps details an SSD drive
attached through USB and mounted on `/srv` for use in compiling
`step-ca`.

### Attach SSD for use as tmp drive

* attach an appropriately sized SSD to the USB
* partition the disk with `fdisk`
* format the partition with `mke2fs -T ext4 ...`
* add entry to `/etc/fstab` placing the partition on `/srv`
  * `mount -a`
* create and soft-link
  * `/srv/<username>/go`       <- `/home/<username>/go`
  * `/srv/<username>/infnoise` <- `/home/<username>/infnoise`
  * `/srv/<username/step-ca`   <- `/home/<username>/step-ca`
  * `/srv/<username>/go-cache` # no soft-link
  * `/srv/go`                  # no soft-link
  * `/srv/tmp`                 # no soft-link (`chmod 1777`)

### Install Golang for compilation

```
> curl -LO https://go.dev/dl/go<version>.linux-arm64.tar.gz
> sudo tar -C /srv/go -xzf go<version>.linux-arm64.tar.gz
> (cd /usr/local; sudo ln -s /srv/go/go .)
## ensure your golang env vars are set properly
## add the following to your environment
> export GOTMPDIR /srv/tmp
> export GOCACHE /srv/ericg/go-cache
> go version`
```

### Download `step-ca` and prerequisites, and build

```
> sudo apt install -y libpcsclite-dev gcc make pkg-config
> cd ~  # ensure we're in $HOME, where step-ca is a symlink
> curl -LO https://github.com/smallstep/certificates/releases/download/<ver>/step-ca_<ver>.tar.gz
> tar -C step-ca step_ca_<ver>.tar.gz
> cd step-ca
> make bootstrap
> make build GOFLAGS=""
> bin/step-ca version
```

### Install `step-ca`

```
> cd ~/step-ca
> sudo cp bin/step-ca /usr/local/bin
> sudo setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/step-ca
```

### Install drivers for Infinite Noise TRNG

```
> sudo apt install -y libftdi-dev libusb-dev
> cd ~
> curl -LO https://github.com/leetronics/infnoise/archive/refs/tags/<ver>.tar.gz
> tar -xvf <ver>.tar.gz
> mv infnoise-<ver>/* infnoise  ## copies onto /srv partition
> cd infnoise/software
> make -f Makefile.linux
> sudo make -f Makefile.linux install
...
> infnoise --version
```

Plugin the TRNG and reboot.

```
> sudo systemctl status infnoise
... output from systemctl showing the service is running ...

> infnoise --debug --no-output
... output showing the TRNG is present and running
^C
```

### Clean-up "scratch" (SSD) Disk

1. Remove entry for `/srv/` from `/etc/fstab`
2. Reboot  (remove attached SSD during reboot)
3. Remove

```
cd ~
rm go infnoise step-ca
```
