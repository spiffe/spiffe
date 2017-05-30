# Generate Leaf certificates 

Run a Python Docker container that will generate VSID leaf 
certificates in a mouted output directory 


The make script has to be supplied two ENV variables 

SECRET is the Intermediate Secret 
PASSPHRASE Is the secret used on the generated key for the leaf certificate

```bash

$ make build 

$ make SECRET={secret} PASSPHARSE={passphrase} generate

```


