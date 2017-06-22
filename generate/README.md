# pki-scratch


## Building the CA with a root and intermediates

To build the root and intermediate CA infrastructure and an example client and server cert run the following commands:
NOTE: you will need openssl installed for this to work including the command line tools.

Make sure Docker image is built before running.

```bash
$ cd scripts
$ make setup
$ make build 
$ make generate
$ make clean_exited
```

Follow the prompts and you will get a directory called `org/<org_name>` in the scripts directory. This contains all the root and intermediate certs and private keys, as well as the ca-chain.

## Building a spiffe cert that is signed by the intermediate

Run the following commands.
NOTE: The security standing of the python cryptography library used in the example is not known. It was chosen for its API
not its cryptographic guarantees. Here are its documented limitations -> https://cryptography.io/en/latest/limitations/
NOTE: This script is python3 only.

```bash
$ cd generate/python
$ make build 
$ make SECRET={secret} PASSPHRASE={passphrase} generate
$ make clean_exited
```
You should get two files in generate/.certs, `frontend.dev.acme.com.cert.pem` and 
`frontend.dev.acme.com.key.pem` which is your public cert and private key. To view a readable output of the spiffe cert run the following command
```
$ cd generate/.certs
$ openssl x509 -in frontend.dev.acme.com.cert.pem -text -noout
```


Directory layout for generated certificates 

```bash

$ .certs/
$ .certs/org/<domain>/
$ .certs/org/<domain>/ca
$ .certs/org/<domain>/ca/certs
$ .certs/org/<domain>/ca/crl
$ .certs/org/<domain>/ca/newcerts
$ .certs/org/<domain>/ca/private
$ .certs/org/<domain>/intermediate
$ .certs/org/<domain>/leaf

```


The cert bundle is in the directory 

```bash

$ .certs/org/<domain>/intermediate/certs 

```


## Leaf Certificate 

```bash
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            36:0d:2e:43:19:c4:36:14:83:b1:1e:93:15:62:c4:82:c3:1a:bb:40
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: O=acme.com, CN=acme.com Intermediate CA
        Validity
            Not Before: Jun  1 06:22:08 2017 GMT
            Not After : Jun 11 06:22:08 2017 GMT
        Subject: C=US, ST=CA, L=San Francisco, O=SPIFFE_CO, CN=Blog
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:f2:67:d0:e0:e5:1a:ef:bf:4d:56:47:49:6e:5c:
                    f9:b8:5b:f1:73:65:1a:0c:e1:b4:bd:14:60:5d:30:
                    c1:1f:f6:bb:ee:57:7d:50:6b:59:da:4a:fc:77:77:
                    7d:61:d8:c2:e5:0d:df:60:3f:d9:df:2b:ce:04:ea:
                    ce:1e:88:c0:e8:bd:1b:bb:c1:fc:00:e5:f1:56:82:
                    e3:5e:71:77:d9:3b:eb:c6:59:dd:93:1a:b7:12:9c:
                    a3:50:43:9d:eb:dd:16:48:52:42:0c:50:17:9f:4f:
                    44:2f:fa:f3:75:4b:9d:7b:62:d6:aa:da:cb:8e:c4:
                    be:1c:9e:4e:d7:6d:96:bb:9d:79:0a:cc:7a:73:d6:
                    65:cd:1d:75:d9:9b:42:26:69:27:3c:13:6c:11:09:
                    61:c3:ea:52:e9:9b:08:3e:fd:94:37:2b:36:77:b1:
                    00:f0:5c:38:a5:42:c2:b5:44:9a:fe:b1:22:1a:95:
                    70:3d:3a:1e:0a:d3:af:41:80:52:8d:72:4a:21:0e:
                    56:09:fa:36:f6:e5:12:a6:40:3b:84:ed:5e:22:b7:
                    c8:df:35:eb:00:ea:a4:96:84:54:36:4f:e6:92:31:
                    84:e8:5d:52:b3:e6:6d:b8:a8:41:04:6c:30:ae:8b:
                    89:5b:58:08:b1:75:a6:c4:f4:11:12:83:42:81:b9:
                    90:13
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Alternative Name: 
                URI:spiffe://dev.acme.com/blog/frontend
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication, TLS Web Server Authentication
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Key Agreement
            X509v3 Subject Key Identifier: 
                E3:D9:F9:22:99:E4:C5:64:06:4E:DF:82:90:A3:D6:F2:3D:FB:7D:4D
            X509v3 Authority Key Identifier: 
                keyid:DE:16:C5:15:DF:EC:53:E6:A6:04:80:C7:8F:2F:FC:40:2B:CE:D3:7F

    Signature Algorithm: sha256WithRSAEncryption
         36:cc:02:fa:88:bf:ec:06:af:26:8b:73:2e:e6:86:19:b1:c9:
         c8:56:d5:97:5b:74:0d:73:a7:d2:f5:e6:f2:21:98:1d:a8:5a:
         7d:52:e7:ae:38:ec:63:90:57:7c:3e:66:74:df:55:2c:ec:aa:
         63:b1:ec:ef:51:61:0f:7c:b4:44:c0:b3:ba:07:57:01:9d:6f:
         c0:5d:df:06:05:8c:c2:45:70:58:04:78:15:67:37:61:40:cc:
         b9:f2:2a:bf:0b:51:2d:b3:fd:34:65:f3:4c:07:c5:46:12:cb:
         5a:d7:85:b4:c2:f5:83:6e:54:e7:5d:4e:ce:0a:5d:d2:8c:db:
         4c:7d:c2:24:b1:2c:d0:67:8a:54:91:55:b0:99:12:f9:97:c6:
         8e:76:8e:2e:bc:34:ba:94:a2:a5:5d:fc:0b:3e:e3:12:57:be:
         3e:a5:7d:ef:e9:c4:5d:0e:df:04:07:f8:a9:e6:33:d0:19:31:
         7c:74:bf:a7:97:d2:26:50:00:b1:d6:70:3b:f1:9c:2d:70:f4:
         4a:82:92:57:8f:ff:82:f0:e4:5e:40:31:22:07:b4:6e:d8:ba:
         08:55:57:fd:da:87:f2:66:1d:20:f4:ec:8d:bd:81:9d:ba:9f:
         80:bf:48:b3:d5:e0:50:41:25:d0:12:42:af:bf:5e:c6:a1:ae:
         ae:75:84:4a:8d:1e:bd:2b:59:c5:aa:1c:c5:44:24:88:30:7e:
         35:c7:a8:86:d4:55:33:7c:b7:36:b3:75:8e:4d:b7:e7:74:ce:
         a9:ec:6f:14:ae:47:ac:84:ca:86:08:0c:bf:b5:55:cc:bc:bb:
         50:6a:29:c6:f4:a7:0b:98:77:c6:6f:0d:8b:04:00:29:4b:44:
         9b:43:4f:4a:e6:23:08:02:a5:57:b2:24:57:2e:da:71:90:41:
         45:37:4c:21:32:16:5b:6b:4f:20:37:59:c3:72:8e:d4:60:87:
         64:d1:62:c9:f0:21:30:7d:5d:c5:da:67:f4:d0:f3:18:ed:88:
         5f:fd:bd:15:3f:85:4e:cf:eb:08:15:6b:0f:a8:f7:84:93:dc:
         3b:4d:c4:7d:c8:79:97:7a:2a:4e:2e:46:cd:b7:10:a4:8c:a7:
         ff:11:f7:0a:be:c8:a5:f6:16:15:df:a0:56:15:f7:90:2f:bb:
         70:ca:7c:02:28:a3:96:5e:97:5c:bc:36:af:aa:ea:61:e3:5b:
         6e:92:4a:de:bb:98:08:78:be:ba:32:39:c2:08:2a:e7:58:a1:
         98:14:14:f1:58:4f:39:a4:b6:1a:4f:e2:e0:c7:7a:84:80:cf:
         95:84:62:4a:b4:8b:ef:6c:43:45:08:85:85:5e:88:50:4c:0a:
         a2:27:ed:5c:e5:49:48:33

```


## The Intermediate Certificate 

```bash

Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 4096 (0x1000)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, O=test1.acme.com, CN=RootCA
        Validity
            Not Before: Jun 21 22:55:22 2017 GMT
            Not After : Sep 29 22:55:22 2017 GMT
        Subject: C=US, O=test1.acme.com, CN=IntermediaetCA
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
            RSA Public Key: (4096 bit)
                Modulus (4096 bit):
                    00:cb:a0:1b:2f:20:5b:62:e6:5c:f2:bb:af:e1:3b:
                    a1:ae:1a:68:96:ab:0b:11:d2:70:db:6e:63:16:38:
                    0b:51:50:c3:86:8f:67:d3:65:17:f8:2d:62:7a:b5:
                    12:9f:a6:13:b3:9a:ae:8c:a9:08:9a:ff:0f:50:5c:
                    83:b9:3f:b1:f1:5e:8a:a0:ff:50:e1:61:4c:98:8c:
                    fa:bf:c7:2b:06:a9:b2:91:f2:2a:6a:e9:5a:e4:d0:
                    40:db:91:75:12:e5:88:cc:f7:02:eb:83:44:c4:80:
                    1c:19:2c:dc:e0:e4:57:5e:a2:80:d2:ed:64:4b:74:
                    ed:65:d8:22:f0:80:26:37:c2:45:ec:df:ec:f2:d5:
                    c2:72:1f:a1:f1:7a:2f:ac:a5:78:31:f5:bc:45:b9:
                    97:2d:e9:4c:9a:13:94:70:97:d6:d6:73:78:43:c6:
                    70:ef:71:e9:f8:ca:af:b0:0f:e0:9d:22:6c:73:99:
                    85:89:35:d6:7c:25:57:83:93:75:9f:5f:8b:af:af:
                    68:b1:32:a7:f2:f5:a9:c7:be:2a:28:90:4b:9c:19:
                    02:be:e5:e2:8c:e9:57:54:90:9b:db:7f:2f:19:7b:
                    e0:76:5c:28:f2:77:2c:d5:7e:f3:2d:3f:e1:4c:54:
                    38:26:6e:be:f4:ac:3e:5f:19:ee:4c:35:9b:b1:0c:
                    46:23:67:8c:77:dc:5b:3b:56:17:3e:d6:08:7a:a8:
                    df:62:86:85:d9:73:27:30:fb:1a:f7:9b:13:76:5b:
                    f6:eb:ee:65:e9:65:66:3d:8a:7b:b1:ed:1c:64:0b:
                    8d:3e:a7:1a:7c:b9:ef:4b:eb:c5:f5:cd:57:cb:f0:
                    7e:2b:53:31:df:18:fb:9f:73:c6:4c:94:39:0b:57:
                    c3:7a:d2:58:86:b5:91:7c:67:d8:b8:53:c1:3f:68:
                    ee:c8:63:33:77:a1:59:31:54:3f:27:ed:fd:b7:63:
                    74:98:6f:95:ca:ab:f9:85:6a:9b:ee:94:1c:0f:79:
                    f0:19:ef:d1:74:5a:ca:7f:f4:5b:69:ec:09:92:52:
                    94:6e:80:34:11:a0:b0:be:7c:8d:90:92:fd:eb:dd:
                    2c:42:d8:2a:28:41:36:01:9c:71:c9:bc:a0:c7:90:
                    25:d0:65:ef:1c:2a:71:be:d4:d6:bb:70:13:1b:08:
                    0b:8a:eb:6a:4e:08:c9:6e:4a:28:0a:36:c0:31:39:
                    9d:34:f1:2b:d6:19:0c:51:8c:6d:2f:5e:ad:74:f2:
                    0d:22:c3:22:c3:fb:60:73:28:e7:6f:ac:00:75:44:
                    d1:e5:95:47:31:81:84:45:32:32:75:f8:16:f8:ef:
                    42:f3:23:0d:8b:79:15:27:5b:76:3a:6d:2b:97:d4:
                    bf:69:4d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                E0:FF:0F:D6:A3:2D:C1:78:06:D8:61:37:CA:B7:B6:63:B5:E2:0F:05
            X509v3 Authority Key Identifier: 
                keyid:6D:FA:F9:2A:B8:6C:5D:7B:B4:C3:07:E1:B4:DE:39:34:22:1C:FA:26

            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Key Usage: critical
                Digital Signature, Certificate Sign, CRL Sign
            X509v3 Name Constraints: critical
                Permitted:
                  URI:.dev.acme.com
                  URI:dev.acme.com

    Signature Algorithm: sha256WithRSAEncryption
        4b:52:3f:8c:9d:8b:df:6a:ac:2b:e4:83:3c:46:e4:0d:12:24:
        82:74:73:ec:1f:93:50:cc:0f:30:21:2a:1a:b7:00:34:a4:22:
        8b:ae:af:a0:f7:fe:fe:44:0d:88:7e:f4:83:ef:2a:4e:e4:af:
        ae:29:6f:15:d5:0b:ee:15:4b:a1:5d:53:16:c3:ad:17:7d:fb:
        1b:09:0b:9a:9a:0f:68:2a:9b:f5:d1:f4:f5:99:a0:44:a3:04:
        85:ae:cb:f2:f7:a3:d9:b6:90:af:52:35:98:e6:2b:eb:52:ed:
        2b:89:b9:ea:2b:9a:be:50:4a:cf:2a:83:37:63:7f:f7:71:94:
        89:d4:28:96:93:64:7a:9e:f3:e8:88:aa:e7:af:2a:a1:44:22:
        25:a7:dc:d3:28:6d:14:92:65:85:34:4d:d7:05:3a:66:dd:5c:
        39:33:bf:11:0c:ca:e0:97:1f:c9:96:1d:20:3f:4d:83:68:89:
        a2:d6:70:f5:6d:29:35:1f:98:5c:ec:8e:21:01:98:98:ce:88:
        e6:bf:cc:89:f0:47:49:f4:b0:8b:f1:ca:89:77:b7:3c:69:3f:
        c8:57:f3:fc:02:d0:44:25:9c:b2:4a:9b:df:e9:0a:4a:15:f7:
        7c:41:e1:df:3e:69:85:b0:d9:ec:95:cf:07:be:f5:09:3a:75:
        dc:ee:1c:fb:c1:ba:ec:9f:66:fc:e4:a4:5e:0e:46:cb:4c:42:
        53:20:0c:87:cb:2c:c9:ca:2b:4c:41:f7:a8:6d:9c:54:48:c9:
        77:87:b7:70:11:af:ff:a3:b3:2e:b7:e8:ed:9f:2f:1e:67:bb:
        f6:b5:7c:df:77:7c:ca:0d:de:c2:da:f3:4e:6a:85:72:d3:25:
        0e:4b:77:ec:cb:ca:27:f2:a5:66:ba:b5:92:78:ef:e9:73:96:
        31:c6:2f:c1:91:8f:a8:52:5a:58:28:e7:26:53:7a:74:fc:dd:
        43:94:30:52:1b:b1:a2:73:d6:56:7f:66:68:1f:14:aa:7f:96:
        04:f3:c5:5e:06:d3:f0:33:03:1b:b0:c0:50:8b:68:19:06:e0:
        ed:f3:0f:e2:24:a6:d4:15:f6:78:e1:08:4e:45:34:60:5c:c6:
        c0:a7:a1:72:6a:e6:99:dd:92:2a:7a:10:99:6d:14:97:9a:5b:
        04:8d:21:0c:e9:77:59:7b:86:96:f7:a4:fc:76:f7:f3:f7:78:
        36:bf:e0:ab:5e:4d:4d:96:c2:28:63:18:7c:00:cf:24:58:82:
        38:a7:cb:03:78:6c:00:36:93:c3:1c:b5:d8:52:65:71:ff:f4:
        39:9f:c1:13:e6:35:e2:1a:d5:aa:c3:17:60:70:c6:d1:9f:8e:
        cd:dc:70:5c:14:61:b8:6

```
