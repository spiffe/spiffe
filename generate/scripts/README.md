# Generate Intermediate Certificates 


## Create Dockerfile

```bash
$ make setup
$ make build 
```

The generated docker container can run the generate script.  The 
container will generate the self signed root, intermediate and leaf certs 
in the mounted directory.

## Run command
```bash
$ make generate
```

# To run on container 
```
$ make clean setup
$ docker run -v ${PWD}/../.certs:/spiffe/certs  -v ${PWD}/conf:/spiffe/conf -it spiffe/gne/bash /bin/bash 
$ ./generate_ca.sh acme.com blog ${PWD}/../.certs ${PWD}/conf
```

## Next steps

Right now the configuration files are hard coded to the acme.com 
domain.

Need to determine how to pass the SPIFFE id configuration to the
(SAN name and name constraints) into the OpenSSL CLI and or OpenSSL configuration files
 
 
```bash

$ generate_ca.sh  acme.com blog /spiffe/certs /spiffe/conf 

```  


OpenSSL parsing.

Name Constraints for URI should not have a scheme, the current 
parsing will not remove the "scheme" from the name constraint string 
when matching it. 
 
Wild cards are "." symbol 

```bash
scheme:[//[user[:password]@]host[:port]][/path][?query][#fragment]

example
spiffe://acme.com 

spiffe//.acme.com

```



