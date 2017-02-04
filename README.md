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

Run the following commands

```
$ cd python
$ virtualenv venv
$ source venv/bin/activate
$ pip install -r requirements.txt
$ python spiffe/spiffe.py ../scripts/root/ca/intermediate/
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
            69:e8:b6:c3:4d:86:27:b4:b4:b5:e0:4c:ee:07:1d:27:80:ff:61:37
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, ST=California, O=Spiffe, CN=intermediate
        Validity
            Not Before: Feb  4 04:27:00 2017 GMT
            Not After : Feb 14 04:27:00 2017 GMT
        Subject: C=US, ST=CA, L=San Francisco, O=Twilio, CN=PA Spiffe Cert
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
            RSA Public Key: (2048 bit)
                Modulus (2048 bit):
                    00:a5:87:28:c7:cd:0f:2a:02:b1:ef:57:42:06:16:
                    81:e1:f7:08:6c:71:09:5a:bb:d3:5b:28:5c:ef:fa:
                    66:5d:9a:04:6e:d6:34:67:38:23:f0:3e:0e:bb:25:
                    77:a7:d6:f3:fc:58:15:17:dc:a5:79:de:6f:fb:75:
                    12:5f:4f:aa:b5:f3:a9:95:ae:5c:00:fc:78:9e:3f:
                    32:fe:d2:7b:82:18:e9:22:37:77:9e:ad:a1:b9:41:
                    3e:67:fe:30:89:24:cf:99:fe:42:6f:57:cc:df:19:
                    c2:a4:3d:bf:b9:3d:05:57:73:3a:bd:32:ce:c6:91:
                    c9:52:fd:4f:ab:f6:5f:22:f1:ce:de:0a:c2:96:1f:
                    cf:c4:d2:15:63:af:6b:b2:0d:ee:10:a6:ac:96:ef:
                    2b:4f:ad:05:57:72:5a:eb:a7:32:d8:00:73:4e:e3:
                    c2:2b:e9:7f:97:a5:8a:af:8f:f5:d8:2b:f5:62:37:
                    9f:2a:f6:33:c9:e7:52:7f:33:54:47:20:68:e2:e0:
                    bf:96:6f:d7:7f:79:4c:19:8b:f3:59:62:78:4c:30:
                    0b:90:eb:ae:2c:c4:5b:2b:03:11:7b:3e:a7:a2:26:
                    a3:24:b9:41:59:78:e5:cd:bf:b8:ed:6d:8a:88:9d:
                    30:52:2e:28:a6:00:cd:9f:ed:ce:44:f7:81:0e:5d:
                    cd:f9
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Alternative Name:
                URI:urn:spiffe:service:acme.com:acme-dev:foo-service
    Signature Algorithm: sha256WithRSAEncryption
        34:96:f8:e0:4f:1f:0b:99:08:3f:ba:35:6c:3e:2e:31:f3:1d:
        57:5f:6f:8d:f8:db:48:d8:14:61:37:ac:67:94:45:e8:d7:5d:
        91:e1:fd:0a:5a:2d:6f:9b:0b:e7:ca:93:f1:78:2b:a7:2d:a0:
        0e:06:85:7c:15:22:de:04:df:65:2d:dd:be:05:30:4a:fc:ee:
        d8:30:a2:a3:cc:37:a9:31:9d:f8:13:19:74:f6:b9:f8:fe:06:
        98:ac:5d:6d:b6:68:90:36:85:56:e9:18:33:ed:b8:5b:b9:bc:
        0f:b6:c2:ea:fa:4f:2b:c4:15:65:aa:e2:4e:2a:83:77:05:c0:
        86:36:0a:eb:a1:e5:b5:2e:86:8f:64:dc:ca:ce:50:99:3d:5f:
        af:2f:28:08:54:43:4e:de:8b:f3:09:2c:e9:43:54:6b:da:ee:
        f1:ef:13:c2:12:03:21:5e:ac:e8:26:2e:df:bd:8a:cb:c8:d9:
        00:b4:fe:cb:bf:ef:f8:87:9e:5b:af:0b:83:79:e9:92:50:50:
        06:9f:67:83:ca:37:a6:54:ed:da:81:fa:7d:80:e1:7f:99:c7:
        f7:fe:eb:76:0c:22:e0:30:f2:cd:77:05:0a:d3:af:19:f5:a0:
        88:a4:92:91:67:89:d6:95:50:9d:18:41:85:5e:4d:ff:08:e7:
        5a:7c:48:f8:7e:e7:3b:70:bd:9f:44:aa:49:6e:e5:a7:7c:04:
        4a:e0:ad:e3:ae:8c:3e:55:2f:a2:81:0f:6b:8d:2f:96:5b:28:
        43:3e:d1:d6:66:1f:32:8d:cb:33:82:b4:21:e3:74:79:a6:45:
        69:0b:c8:8e:ff:91:a6:d5:ba:fc:0e:8f:80:5d:66:9d:be:26:
        e3:35:3e:5e:e5:09:93:8f:10:8e:2a:ab:71:aa:c8:31:22:99:
        74:65:ec:b4:f2:3d:04:9e:cb:dd:91:16:ab:e6:6e:35:cb:06:
        04:8f:db:6d:19:2e:48:eb:38:18:e5:f4:d0:8a:ea:59:c0:4a:
        c0:02:b0:35:09:f3:d6:17:02:ab:c8:50:2c:e8:c6:06:34:dd:
        cf:10:30:b4:b0:a3:e1:a0:4c:59:ce:41:ac:a8:c2:54:3b:fd:
        eb:b0:3c:9e:6c:0f:07:e9:ae:65:cc:bf:46:28:c9:5a:eb:30:
        19:f5:fc:4f:cf:6d:80:f3:d3:7e:a6:3e:e7:30:c0:7e:9c:6d:
        e4:3f:6b:a7:48:7a:68:29:66:37:cd:c1:c4:5a:86:8f:36:6e:
        13:ef:6f:a4:2a:fa:1a:df:b0:1a:74:e0:db:c7:54:fd:66:27:
        a6:ab:84:7f:af:ac:91:06:11:51:18:fb:94:4f:88:6b:df:40:
        8b:63:af:65:fb:bc:e6:9e
```
