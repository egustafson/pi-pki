Generating x509 PEM Certs for Certificate Authority
===================================================

Root Certificate Authority
--------------------------

```
# generate a private key for a curve
openssl ecparam \
        -name prime256v1 \
        -genkey \
        -noout \
        -rand /dev/random \
        -out organization-key.pem

# create a self-signed certificate
openssl req \
        -x509 \
        -new \
        -days 18250 \
        -rand /dev/random \
        -config organization-ca.config \
        -extensions v3_ca \
        -key organization-key.pem \
        -out organization-crt.pem
```

Intermediate Certificate Authority
----------------------------------

```
# intermediate key (using step)
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
> cat stoneglen-org.json
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
    --set-file stoneglen-org.json \
    --ca troll-crt.pem \
    --ca-key troll-key.pem \
    "Stoneglen Intermediate CA" \
    stoneglen-intermediate-crt.pem \
    stoneglen-intermediate-key.pem

```

Alternative Intermediate Authority
----------------------------------

```
# intermediate key (using openssl)
openssl ecparam \
        -name prime256v1 \
        -genkey \
        -noout \
        -rand /dev/random \
        -out intermediate-key.pem

# intermediate cert
openssl req \
        -new \
        -config intermediate-key.pem \
        -key intermediate-key.pem \
        -out intermediate-crt.pem
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

