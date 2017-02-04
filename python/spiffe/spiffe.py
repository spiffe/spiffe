from datetime import datetime, timedelta
import sys

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.primitives import hashes

def generate_spiffe(identity,
                    passphrase,
                    intermediate_path,
                    intermediate_secret):

    key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )

    csr = x509.CertificateSigningRequestBuilder().subject_name(x509.Name([
        x509.NameAttribute(NameOID.COUNTRY_NAME, u"US"),
        x509.NameAttribute(NameOID.STATE_OR_PROVINCE_NAME, u"CA"),
        x509.NameAttribute(NameOID.LOCALITY_NAME, u"San Francisco"),
        x509.NameAttribute(NameOID.ORGANIZATION_NAME, u"Twilio"),
        x509.NameAttribute(NameOID.COMMON_NAME, u"PA Spiffe Cert"),
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

    cert = x509.CertificateBuilder().subject_name(
        csr.subject
    ).issuer_name(
        intermediate_cert.subject
    ).public_key(
        key.public_key()
    ).serial_number(
        x509.random_serial_number()
    ).not_valid_before(
        datetime.utcnow()
    ).not_valid_after(
        # Our certificate will be valid for 10 days
        datetime.utcnow() + timedelta(days=10)
    ).add_extension(
        x509.SubjectAlternativeName([x509.UniformResourceIdentifier(identity)]),
        critical=False,
        # Sign our certificate with our private key
    ).sign(intermediate_key, hashes.SHA256(), default_backend())


    private_out = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.BestAvailableEncryption(passphrase))

    certificate = cert.public_bytes(serialization.Encoding.PEM)

    return private_out, certificate

def generate_spiffe_to_file(private_key, certificate, file_prefix):
    with open("{}.key.pem".format(file_prefix), 'wb') as f:
        f.write(private_key)

    with open("{}.cert.pem".format(file_prefix), 'wb') as f:
        f.write(certificate)


if __name__ == '__main__':
    path_to_ca = sys.argv[1]
    p_key, certificate = generate_spiffe("urn:spiffe:service:acme.com:acme-dev:foo-service",
                                         b"secret",
                                         path_to_ca,
                                         b'secret')
    generate_spiffe_to_file(p_key, certificate, 'spiffe')


# to check csr run $ openssl req -in spiffe.csr.pem -noout -text
# to check private key run $ openssl rsa -in spiffe.key.pem -check
# to check a certificate run $ openssl x509 -in certificate.crt -text -noout
