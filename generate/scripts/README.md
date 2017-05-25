# Generate Intermediate Certificates 


## Create Dockerfile
```bash

docker build -t svig_gen_inter . 


```

## Run command
```bash

dockder run -it -v ${PWD}/../.cert:/spiffe/certs -v ${PWD}/conf:/spiffe/conf svig_gen_inter /bin/bash

```

## Next steps