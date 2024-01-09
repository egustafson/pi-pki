Configure `step-ca` Server
==========================

Overview of setting the
[`step-ca`](https://smallstep.com/docs/step-ca/configuration/) server
software:

0. Initialize Root and Intermediate Certificates and store them in
   your KMS(YubiKey):  [step 2 - Create Certificates](2_ROOT_CA.md)
1. Create `step` user and `/etc/step-ca` in preparation of
   initializing a CA on the host.
2. Initialize the CA with `step ca init`
3. Swap initialization root and intermediate certs official root and
   intermediate certs.
4. Manually start `step-ca` and validate installation by generating a
   host cert.
5. Configure `systemd` to start the CA when YubiKey is present.

1 - Prepare host for CA installation
------------------------------------

```
> sudo adduser step
> sudo passwd -l step
> sudo mkdir /etc/step-ca
> export STEPPATH=/etc/step-ca
```

A later step, (#3), will change ownership of `/etc/step-ca` to the
`step` user.


2 - Initialize CA on the host
-----------------------------

```
> export STEPPATH=/etc/step-ca
> sudo --preserve-env step ca init \
    --name="Stoneglen Trollwerks CA" \
    --dns="pki.elfwerks" \
    --address=":443" \
    --provisioner="ea-pki@elfwerks.org" \
    --deployment-type standalone \
    --remote-management
Choose a password for you CA keys and first provisioner.
✔ [leave empty and we'll generate one]: ↩
# <generated-password>                     <-- copy and save
...
Root fingerprint: 01234567890abcdefg01234567890abcdef...
...
Your PKI is ready to go. ...
```

*Note:*  make sure to copy and save the generated password.  This
password is needed, and used to authenticate remote use of the CA.

*Also:* In step 4, the fingerprint of the final root certificate is
needed.  This will be a different value than what is printed during
initialization.  The root certificate fingerprint will be printed in
step 3.


3 - Load and configure official certificates
--------------------------------------------

In step 2, the CA was initialized and both Root and Intermediate
certificates were automatically generated during the process.  This
step will replace the automatic certificates and keys with both a Root
and Intermediate provided by you.  The keys will be provided through a
YubiKey which will be configured into the `step-ca` configuration.

In this example, the official certificates and keys are located as
follows:

* Root Certificate:  /tmp/root-cert.pem
* Intermediate Certificate:  /tmp/intermediate-cert.pem

* Root Key:  YubiKey slot 9a
* Intermediate Key:  Yubikey slot 9c

The following file, `/etc/step-ca/config/ca.json` should replace the
default configuration from step 2:

```
{
    "root": "/etc/step-ca/certs/root_ca.crt",
    "federatedRoots": [],
    "crt":  "/etc/step-ca/certs/intermediate_ca.crt",
    "key": "yubikey:slot-id=9c",
    "kms": {
        "type": "yubikey",
        "pin":  "12345"      # replace with actual pin
    },
    "address": ":443",
    "dnsNames": [ "pki.elfwerks" ],
    "logger": { "format": "text" },
    "db": {
        "type": "badgerv2",
        "dataSource": "/etc/step-ca/db"
    },
    "authority": {
        "enableAdmin": true,
        "claims": {
            "minTLSCertDuration": "720h",
            "maxTLSCertDuration": "17520h",
            "defaultTLSCertDuration": "8660h",
        }
    },
    "tls": {
        "cypherSuites": [
            "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256",
            "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
        ],
        "minVersion": 1.2,
        "maxVersion": 1.3,
        "renegotiation": false
    }
}
```

Update `step-ca` configuration:

```
> sudo cp /tmp/root-crt.pem /etc/step-ca/certs
> sudo cp /tmp/intermediate-crt.pem /etc/step-ca/certs
> sudo rm -rf /etc/step-ca/secrets
> sudo cp ca.json /etc/step-ca/config/ca.json

> sudo chown -R step:step /etc/step-ca

```

Finally, capture the fingerprint of the root certificate.  This value
is needed in step 4.  The fingerprint does not need to be held onto
long term, nor is it a secret -- it's just the fingerprint of the root
certificate.

```
> step certificate fingerprint /tmp/root-crt.pem
31338704...54d87a    # <-- root certificate fingerprint
```


4 - Manual start and test of `step-ca`
--------------------------------------

Manually start `step-ca` in a separate terminal window:

```
> sudo -u step step-ca /etc/step-ca/config/ca.json
```

Then bootstrap the CA into the local user account:

```
> cd
> step ca bootstrap \
    --ca-url "https://pki.elfwerks" \
    --fingerprint 31338704...54d87a
The root certificate has been saved in /home/<username>/.step/certs/root_ca.crt
Your configuration has been saved in /home/<username>/.step/config/defaults.json
```

Finally, generate a certificate for `localhost` to verify the CA will
generate certificates.  In this step, `step` will prompt you for a
"password to decrypt the provisioner key", this is the password that
was saved in step 2 when the CA was initialized.

```
> step ca certificate "localhost" localhost.crt localhost.key
✔ Provisioner: ea-pki@elfwerks.org (JWK) [kid: <key-id>]
✔ Please enter the password to decrypt the provisioner key:   # <-- password
...
```

Perform any validation you wish to on the output files,
`localhost.crt` and `localhost.key`.

Exit out of `step-ca` run in the alternate window with ctrl-C.


5 - Configure `systemd` to start the CA
---------------------------------------

Create the file `75-yubikey.rules`:

```
ACTION=="add" \
, SUBSYSTEM=="usb" \
, ENV{PRODUCT}=="1050/407/*" \
, TAG+="systemd" \
, SYMLINK+="yubikey"

ACTION=="remove" \
, SUBSYSTEM=="usb" \
, ENV{PRODUCT}=="1050/407/*" \
, TAG+="systemd"
```

and install the rules file:

```
> sudo cp 75-yubikey.rules /etc/udev/rules.d/75-yubikey.rules
> sudo udevadm control --reload-rules
```

Then create a `systemd` unit file for `step-ca` named `step-ca.service`:

```
[Unit]
Description=step-ca PKI
Documentation=https://github.com/egustafson/pi-pki
BindsTo=dev-yubikey.device
After=dev-yubikey.devicexs

[Service]
Type=simple
Restart=on-failure
RestartSec=10
User=step
Group=step
ExecStart=/bin/sh -c '/usr/local/bin/step-ca /etc/step-ca/config/ca.json'

[Install]
WantedBy=multi-user.target
```

and install the unit file as follows:

```
> sudo cp step-ca.service /etc/systemd/system/step-ca.service
> sudo systemctl daemon-reload
> sudo systemctl enable step-ca
```

finally, verify the service is running.

```
> sudo systemctl status step-ca
...
```
