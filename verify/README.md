
# Verification 

Test generated bundle of certs against different platforms 


| Test | SAN | Name Constraint | Pass | Description |
|:------:|:-------:|:-------:|:---------------:|:----------:|
| valid    | URI:spiffe://dev.acme.com/path/service | URI:.acme.com | PASS | NameConstraint domain matches SAN domain  |
| no match | URI:spiffe://dev.tech.com/path/service | URI:.acme.com | FAIL | SAN and NameConstraint domains are not equal |
| NS type  | URI:spiffe://dev.acme.com/path/service | DNS:.acme.com | ? | <todo> | 
| NS wildcard | URI:spiffe://dev.acme.com/path/service | URI:acme.com | ? | <todo> |
 
 

