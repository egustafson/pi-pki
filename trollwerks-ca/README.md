Generating x509 PEM Certs for Certificate Authority
===================================================

This document abstracts the organization name in a number of places,
and in others it may explicitly use the example organization and
intermediate names.  Throughout this document you will find:

    ${ORG} = Trollwerks  ## The top level organization
    ${OU}  = Stoneglen   ## Intermediate organizational unit

Root Certificate Authority
--------------------------

```
> cat ${ORG}-ca.config
[ req ]
x509_extensions = v3_ca
prompt = no
distinguished_name = dn

[ dn ]
O = Trollwerks
CN = Trollwerks Root Authority

[ v3_ca ]
basicConstraints = critical, CA:true, pathlen:1
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
subjectKeyIdentifier = hash
#
# generate a private key for a curve
> openssl ecparam \
          -name prime256v1 \
          -genkey \
          -noout \
          -rand /dev/random \
          -out ${ORG}-ca-key.pem

# create a self-signed certificate
> openssl req \
          -x509 \
          -new \
          -days 18250 \
          -rand /dev/random \
          -config ${ORG}-ca.config \
          -extensions v3_ca \
          -key ${ORG}-ca-key.pem \
          -out ${ORG}-ca-crt.pem
```

Load Root CA into YubiKey
-------------------------

The YubiKey will hold both the Organization's Root CA and the
Intermediate.  The two certificate-key pairs will be loaded into the
YubiKey as follows:

    Slot 9a:  Organization Root CA   (Trollwerks)
    Slot 9c:  Intermediate Cert/Key  (Stoneglen)

_Warning:_ The YubiKey defaults to a PIN of `123456`.  This default is
used throughout these instructions.  You should change the PIN,
hopefully that is obvious.  From the "Tiny CA" guide:

> You should change your YubiKey PIN, PUK, and management key if you
> haven't already! [Learn how in this
> guide](https://developers.yubico.com/PIV/Guides/Device_setup.html).

```
> ykman piv certificates import 9a ${ORG}-ca-crt.pem
...
> ykman piv keys import 9a ${ORG}-ca-key.pem
...
> ykman piv info
... info showing 9a holds the imported certificate ...
```

Intermediate Certificate Authority
----------------------------------

Generate an intermediate CA using the YubiKey as the Key Management
System (KMS).

```
# intermediate key (using step and YubiKey)
> cat intermediate.tpl
{
    "subject": {
        "commonName": {{toJson .Subject.CommonName }},
        "organizationalUnit": {{ toJson .Insecure.User.organizationalUnit }},
        "organization": {{ toJson .Insecure.User.organization }}
    },
    "keyUsage": ["certSign", "crlSign"],
    "basicConstraints": {
        "isCA": true,
        "maxPathLen": 0
    }
}
#
> cat ${OU}-ou.json
{
    "organizationalUnit": "Stoneglen",
    "organization": "Trollwerks"
}
#
# (2 year expiration = 17520h)
#
> step certificate create \
    --no-password \
    --insecure  \
    --not-after 17520h \
    --template intermediate.tpl \
    --set-file ${OU}-ou.json \
    --ca-kms 'yubikey:pin-value=123456'
    --ca-key 'yubikey:slot-id=9a' \
    --ca ${ORG}-crt.pem \
    "Stoneglen Intermediate CA" \
    ${OU}-crt.pem \
    ${OU}-key.pem
```

Load Intermediate CA into YubiKey
---------------------------------

The intermediate Cert and Key go in slot 9c.

```
> ykman piv certificates import 9c ${OU}-crt.pem
...
> ykman piv keys import 9c ${OU}-crt.pem
...
> ykman piv info
... info showing 9c holds the imported certificate ...
```


Alternative Methods
-------------------

### Intermediate Certificate Authority (no YubiKey)

For reference, the following details generating the intermediate with
`step`, but not using the YubiKey as the KMS.

```
# intermediate key (using step)
#
# Files: intermediate.tpl and ${OU}-ou.json as defined above.
#
# 2 year expiration = 17520h
#
> step certificate create \
    --no-password \
    --insecure  \
    --not-after 17520h \
    --template intermediate.tpl \
    --set-file ${OU}-ou.json \
    --ca ${ORG}-crt.pem \
    --ca-key ${ORG}-key.pem \
    "Stoneglen Intermediate CA" \
    ${OU}-crt.pem \
    ${OU}-key.pem
```

### Alternative Intermediate Authority

```
# intermediate key (using openssl)
> openssl ecparam \
          -name prime256v1 \
          -genkey \
          -noout \
          -rand /dev/random \
          -out ${OU}-key.pem

# intermediate cert
> openssl req \
          -new \
          -config ${OU}-ca.config \
          -key ${OU}-key.pem \
          -out ${OU}-crt.pem
```


References
----------

* [Creating Elliptic Curve Keys using
  OpenSSL](https://www.scottbrady91.com/openssl/creating-elliptical-curve-keys-using-openssl)
* [Creating a Certificate Using
  OpenSSL](https://sockettools.com/kb/creating-certificate-using-openssl/)
* [OpenSSL: x509v3_config](https://www.openssl.org/docs/manmaster/man5/x509v3_config.html)
* [Basics: The Key Usage Certificate
  Extension](https://www.gradenegger.eu/en/basics-the-key-usage-certificate-extension/)

