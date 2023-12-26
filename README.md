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

# Initial install
