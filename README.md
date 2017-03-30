# pki-scratch


## Building the CA with a root and intermediates

To build the root and intermediate CA infrastructure and an example client and server cert run the following commands:
NOTE: you will need openssl installed for this to work including the command line tools.
```
$ cd scripts
$ ./generate_ca.sh
```

Follow the prompts and you will get a directory called `root` in the scripts directory. This contains all the root and intermediate certs and private keys, as well as the ca-chain.

## Building a spiffe cert that is signed by the intermediate

Run the following commands.
NOTE: The security standing of the python cryptography library used in the example is not known. It was chosen for its API
not its cryptographic guarantees. Here are its documented limitations -> https://cryptography.io/en/latest/limitations/

```
$ cd python
$ make python_env
$ make dev_requirements
$ python spiffe/spiffe.py ../scripts/root/ca/intermediate/

$ python --config=sample_config.ini  --pass=<pass> --secret=<intermediate_pass> --path=../scripts/org/acme.com/ca/intermediate
```
You should get two files, `spiffe.cert.pem` and `spiffe.key.pem` which is your public cert and private key. To view a readable output of the spiffe cert run the following command

```
$ openssl x509 -in spiffe.cert.pem -text -noout
```

Which should get you something like

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            60:98:1b:80:56:e9:d7:81:58:a0:45:58:02:10:aa:eb:a7:68:bb:56
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=acme.com, CN=acme.com Intermediate CA
        Validity
            Not Before: Mar 28 03:04:40 2017 GMT
            Not After : Apr  7 03:04:40 2017 GMT
        Subject: C=US, ST=CA, L=San Francisco, O=SPIFFE_CO, CN=Blog
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
            RSA Public Key: (2048 bit)
                Modulus (2048 bit):
                    00:da:4d:a3:53:5b:7d:ee:4c:42:4e:88:71:83:7c:
                    f6:e2:00:27:34:3d:8f:f6:54:8c:90:3b:2e:aa:3a:
                    ab:f5:9a:aa:2a:9f:2a:e0:25:5f:60:f4:f5:22:b8:
                    d1:e3:b5:bb:12:b9:12:93:25:83:21:73:d9:4e:a6:
                    72:2d:ce:b4:5c:91:5e:f9:60:57:86:cb:04:7e:9a:
                    4b:1b:f8:66:db:b8:c2:b7:3a:a2:9c:11:63:db:a7:
                    ca:51:e0:be:64:73:4a:d3:5e:bc:97:0e:de:23:34:
                    8d:5d:4c:2f:dc:4f:26:3e:a4:20:58:6f:4b:4b:97:
                    b2:f3:4f:c3:82:31:2a:45:6b:94:b8:b6:1f:00:5d:
                    95:22:6a:29:db:e1:d5:50:47:3b:22:84:39:20:8f:
                    3c:ef:54:97:d7:c9:26:bb:5f:b9:94:8b:09:53:26:
                    4a:d0:21:a7:25:4b:e6:2d:01:41:4c:99:d2:2a:12:
                    c2:ff:14:aa:18:2b:25:58:0f:68:da:63:06:86:ff:
                    90:d1:f9:5b:c2:e8:56:67:8f:5e:14:6d:7c:14:e6:
                    b2:ac:32:66:51:ce:26:03:97:47:6c:f7:28:96:65:
                    00:36:a9:65:5e:37:34:2a:60:6f:c5:7f:9e:f4:da:
                    73:d9:d8:f1:2e:00:c3:a5:36:ed:20:33:17:36:7c:
                    cb:3b
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Alternative Name:
                URI:spiffe:service:acme.com:acme-dev:foo-service?version=1.0, DNS:foo-service.acme-dev.acme.com
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Name Constraints:
                Permitted:
                  URI:spiffe:acme.com:acme-dev:.
                  URI:spiffe:acme.com:.

            X509v3 Extended Key Usage:
                TLS Web Client Authentication, TLS Web Server Authentication
            X509v3 Subject Key Identifier:
                64:56:52:B2:7B:DF:86:EC:AD:5D:89:86:5C:C8:FD:F7:4D:FE:B5:73
            X509v3 Authority Key Identifier:
                keyid:4E:E5:C3:6D:4F:CB:1F:63:6C:B4:B7:72:EB:C6:CC:1D:D9:7F:1D:B0

    Signature Algorithm: sha256WithRSAEncryption
        5a:02:87:aa:c4:92:76:72:0e:30:43:e7:4f:e2:b0:bd:46:5f:
        83:fa:5d:dd:10:1a:b4:8c:7c:ab:85:bb:d5:06:40:c7:d2:73:
        0c:ae:ea:3a:61:46:c8:d6:e4:e9:5e:b0:14:eb:70:02:8c:87:
        9a:10:6f:bf:24:23:be:aa:e3:1a:01:78:17:1f:7a:d8:db:ec:
        61:10:87:7e:27:ab:0d:89:60:8b:6b:29:91:83:72:9e:6b:b4:
        3e:03:fc:1e:13:6a:67:72:d7:9e:fe:ff:a1:37:e2:bd:e6:f3:
        5f:55:a3:7f:e1:b2:d3:75:05:00:6b:f5:4c:31:ec:6c:78:41:
        24:b9:f3:e8:14:43:a1:45:01:59:fc:14:1f:f3:83:f8:5d:70:
        a8:cd:00:a1:69:db:a2:72:6c:21:e9:9c:2a:e3:40:ff:d0:d3:
        4c:92:25:6e:fd:22:01:2c:13:12:6c:5c:39:a7:ee:71:8e:9d:
        4d:3b:a9:d8:c9:54:75:69:06:48:c3:e2:63:05:dd:d6:ba:dd:
        5e:15:28:99:93:4e:63:c8:ea:14:5d:2d:14:8e:fe:fe:82:f4:
        66:77:75:d5:56:3e:fa:fa:44:ab:3a:d3:dc:50:92:3a:90:1f:
        70:0f:7c:6f:22:e5:eb:77:76:39:b2:d3:04:06:40:9c:d1:d5:
        9b:80:b0:01:d1:7c:0c:96:82:01:38:2d:33:ac:ac:e0:24:90:
        7e:3c:4a:2c:de:b7:a8:bc:ea:fb:23:ae:ad:fd:13:12:c3:ed:
        7e:d1:a4:f6:d4:f7:18:c9:67:c0:ca:72:b8:15:06:3d:fb:a9:
        35:7e:e6:58:c6:74:85:b0:22:99:e0:b2:0b:8b:88:9a:45:2a:
        ee:e4:ae:85:b4:46:09:15:8b:05:c2:e1:93:f2:1a:af:41:65:
        bc:b9:ce:1d:bc:7d:79:98:fd:19:c6:73:50:b5:df:7a:be:ab:
        66:39:7c:0d:ae:f4:e7:12:97:26:db:ad:43:d7:cf:eb:c2:25:
        70:43:71:f7:49:02:80:9e:9a:82:0b:ea:ac:a2:11:53:63:51:
        be:fe:4c:d6:00:50:51:96:d2:78:4a:e9:7c:21:58:5c:51:23:
        2d:fb:19:c5:0f:86:68:ad:49:92:ee:28:43:6a:be:02:15:3d:
        71:1a:a5:67:11:22:f6:33:9f:9a:72:e4:43:f4:da:a0:ab:54:
        ea:7c:45:c6:c4:b8:23:49:ea:4a:df:3d:cb:10:ee:51:7a:a2:
        0f:d1:a2:fb:7f:95:be:93:df:3b:4f:76:90:9c:1c:8a:fe:5b:
        a8:a0:c1:6a:02:b0:bd:09:09:30:1d:ed:68:1d:5d:80:03:3e:
        3c:d9:02:d6:1b:4b:37:6d