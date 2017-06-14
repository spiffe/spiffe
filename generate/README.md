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
$ .certs/org/<domain>/intermediate
$ .certs/org/<domain>/leaf

```



Which should get you something like

```
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
