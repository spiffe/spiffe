# Generate Intermediate Certificates 

This directory creates code to *generate* SVIDs using a range of tools.

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

## Libraries 

| mustache | https://github.com/mustache/spec.git spec | Library to handle Mustache templates in Bash |
| csv | https://github.com/geoffroy-aubry/awk-csv-parser.git | | 


