pi-pki
======
Raspberry Pi (clone) based Hardware PKI

This project details the specific steps to create my PKI.  The PKI is
a hardware-esque solution that uses a RPi clone (PI4B w/ CB1) from Big
Tree Tech.  The specific hardware is:

* [Big Tree Tech](https://bigtree-tech.com)
  * [PI4B+CB1](https://biqu.equipment/collections/control-board/products/pi4b-adapter-v1-0)
* [YubiKey 4 Nano](https://support.yubico.com/hc/en-us/articles/360013714599-YubiKey-4)
* Infinite Noise TRNG
  * https://www.crowdsupply.com/leetronics/infinite-noise-trng
  * https://github.com/waywardgeek/infnoise

The project is _HEAVILY_ inspired (i.e. mostly copied) from Carl
Tashian's excellent article:
[Build a Tiny Certificate Authority For Your
Homelab](https://smallstep.com/blog/build-a-tiny-ca-with-raspberry-pi-yubikey/)
using [Smallstep](https://smallstep.com/)'s open source certificate
manager software:  [Step CLI](https://smallstep.com/docs/step-cli/)
and [Step CA](https://smallstep.com/docs/step-ca/)

# Basic Install of Board

## Bootstrap Board

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

# Install Supporting Software

## Yubikey Manager

* `apt install yubikey-manager`
* `ykman info` # with a YubiKey inserted

## `step` and `step-kms-plugin`

* Download `step` from GitHub
  * `curl -LO https://github.com/smallstep/cli/releases/download/<ver>/step_cli_<ver>_arm64.deb`
  * `apt install ./step_cli_<ver>_arm64.deb`
  * `step version`

* Download `step-kms-plugin` from GitHub
  * `curl -LO https://github.com/smallstep/step-kms-plugin/releases/download/<ver>/step-kms-plugin_<ver>_arm64.deb`
  * `apt install ./step-kms-plugin_<ver>_amd64.deb`
  * `step kms version`

### Build `step-ca` from source with YubiKey support enabled

The `step-ca` binary distribution does not include support for YubiKey
compiled in.  YubiKey support must be added by compiling the
executable from Golang source with the appropriate libraries
(libpcsclite) present.

Additionally, the SD card used as root is very inefficient for such
compilation.  The following sequence of steps details an SSD drive
attached through USB and mounted on `/srv` for use in compiling `step-ca`.

