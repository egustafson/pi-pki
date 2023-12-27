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
