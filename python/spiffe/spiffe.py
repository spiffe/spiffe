"""Spiffe Leaf PKI.

Usage:
  spiffe.py --id=<spiffe_id> --path=<cert_path> --pass=<pass> --secret=<secret> --config=<config>
  spiffe.py (-h | --help)
  spiffe.py --version

Options:
  -h --help     Show this screen.
  --version               Show version.
  --id=<spiffe_id>        SPIFFE ID to user in certificate.
  --path=<cert_path>      Path to intermediate certificates
  --pass=<pass>           Passpharse for certificate
  --secret=<secret>       Secret for intermediate certificates
  --config=<config file>  Config File that loads all configurations for SPIFFE
                          certificate generation


"""
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes

from datetime import datetime, timedelta
from docopt import docopt

import sys
from config import SpiffeConfig

def generate_spiffe(spiffe_config,
                    identity,
                    passphrase,
                    intermediate_path,
                    intermediate_secret):
    """
    """

    key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )

    csr = x509.CertificateSigningRequestBuilder().subject_name(x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, spiffe_config.country),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, spiffe_config.state_or_province),
        x509.NameAttribute(NameOID.LOCALITY_NAME, spiffe_config.locality),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, spiffe_config.organization),
        x509.NameAttribute(NameOID.COMMON_NAME, spiffe_config.common_name),
    ])).add_extension(
        x509.SubjectAlternativeName([
            # Describe what sites we want this certificate for.
            x509.UniformResourceIdentifier(identity),
        ]),
        critical=False,
        # Sign the CSR with our private key.
    ).sign(key, hashes.SHA256(), default_backend())


    # sign the csr with the intermediate cert
    intermediate_key = None
    with open("{}/private/intermediate.key.pem".format(intermediate_path), 'rb') as f:
        intermediate_key = default_backend().load_pem_private_key(f.read(), intermediate_secret)

    intermediate_cert = None
    with open("{}/certs/intermediate.cert.pem".format(intermediate_path), 'rb') as f:
        intermediate_cert = x509.load_pem_x509_certificate(f.read(), default_backend())

    cert = x509.CertificateBuilder().subject_name(csr.subject)

    cert = cert.issuer_name(intermediate_cert.subject)
    cert = cert.public_key(key.public_key())

    cert = cert.serial_number(x509.random_serial_number())

    cert = cert.not_valid_before(datetime.utcnow())
    cert = cert.not_valid_after(
        # Our certificate will be valid for 10 days
        datetime.utcnow() + timedelta(days=10))


    # x509 Extensions
    cert = cert.add_extension(
        x509.SubjectAlternativeName([x509.UniformResourceIdentifier(identity)]),
        critical=False,)

    cert = cert.add_extension(x509.BasicConstraints(ca=False,path_length=None),
                              critical=True)

    name_constraints = []
    for constraint in spiffe_config.name_contraints:

        name_constraints.append(x509.UniformResourceIdentifier(constraint))

    cert = cert.add_extension(x509.NameConstraints(permitted_subtrees=name_constraints,
                                                   excluded_subtrees=None),
                              critical=False)

    cert.add_extension(x509.ExtendedKeyUsage([x509.oid.ExtendedKeyUsageOID.CLIENT_AUTH,
                                                    x509.oid.ExtendedKeyUsageOID.SERVER_AUTH]),
                              critical=False)

    cert.add_extension(x509.SubjectKeyIdentifier(),
                       critical=False)

    cert.add_extension(x509.AuthorityKeyIdentifier(),
                       critical=False)
    # Sign our certificate with our private key
    cert = cert.sign(intermediate_key, hashes.SHA256(), default_backend())


    private_out = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.BestAvailableEncryption(passphrase))

    certificate = cert.public_bytes(serialization.Encoding.PEM)

    return private_out, certificate

def generate_spiffe_to_file(private_key,
                            certificate,
                            file_prefix):
    """
    """
    with open("{}.key.pem".format(file_prefix), 'wb') as f:
        f.write(private_key)

    with open("{}.cert.pem".format(file_prefix), 'wb') as f:
        f.write(certificate)


if __name__ == '__main__':

    args = docopt(__doc__, version='Spiffe PKI 1.0')

    print(args)

    spiffe_local_config = SpiffeConfig(args["--config"])
    spiffe_local_config.load()

    # "urn:spiffe:service:acme.com:acme-dev:foo-service"
    p_key, certificate = generate_spiffe(spiffe_config=spiffe_local_config,
                                         identity=args["--id"],
                                         passphrase=bytes(args["--pass"], 'utf-8'),
                                         intermediate_path=args["--path"],
                                         intermediate_secret=bytes(args["--secret"], 'utf-8'))

    generate_spiffe_to_file(p_key, certificate, 'spiffe')


# to check csr run $ openssl req -in spiffe.csr.pem -noout -text
# to check private key run $ openssl rsa -in spiffe.key.pem -check
# to check a certificate run $ openssl x509 -in certificate.crt -text -noout
