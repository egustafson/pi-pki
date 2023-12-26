Installation Notes - pki.elfwerks
=================================

# Initial install

1. Boot from SD
2. armbian-config -> change hostname to pki.elfwerks
3. Reboot, login as ericg
4. create /etc/apt/apt.conf.d/90aptproxy
5. apt update; apt upgrade
6. apt install vim ansible
7. Clone http://github.com/egustafson/env
8. cd ~/env/ansible; ansible-playbook -i localhost ericg -K
9. logout/login

# Host Config

* Hostname is set properly (hostnamectl set-hostname)
* NTP - (timedatectl)
  * If necessary:
  * edit /etc/systemd/timesyncd.conf
  * systemctl restart systemd-timesyncd
* apt install prometheus-node-exporter

# YubiKey

* apt install yubikey-manager
* ykman info
