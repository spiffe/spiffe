# Generate Leaf certificates 

Run a Python Docker catainer that will generate VSID leaf 
certificates in a mouted directory 

```bash


docker build -t svid_gen_python .

docker run -it -v ${PWD}/../.cert:/spiffe/certs svig_gen_python /bin/bash
```
