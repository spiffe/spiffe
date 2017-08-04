package main

import (
	"crypto/x509"
	"encoding/pem"
	"errors"
	"io/ioutil"
	"log"
	// "github.com/spiffe/go-spiffe"
)

func ReadLeafCert(leafPath string) (*x509.Certificate, error) {
	leafCertBytes, err := ioutil.ReadFile(leafPath)
	if err != nil {
		return nil, err
	}

	decodedCert, _ := pem.Decode(leafCertBytes)
	if decodedCert == nil {
		return nil, errors.New("Could not decode PEM certificate")
	}

	cert, err := x509.ParseCertificate(decodedCert.Bytes)
	if err != nil {
		return nil, err
	}

	return cert, nil
}

func ReadTrustBundle(bundlePath string) (*x509.CertPool, error) {
	trustBundleBytes, err := ioutil.ReadFile(bundlePath)
	if err != nil {
		return nil, err
	}

	bundle := x509.NewCertPool()
	ok := bundle.AppendCertsFromPEM(trustBundleBytes)
	if !ok {
		return nil, errors.New("Could not load trust bundle...")
	}

	return bundle, nil
}

// TODO: Revisit this once name constraints are working in Go
func main() {
	leafCert, err := ReadLeafCert("/cert/leaf.cert.pem")
	if err != nil {
		log.Fatal(err)
	}

	rootBundle, err := ReadTrustBundle("/cert/ca-chain.cert.pem")
	if err != nil {
		log.Fatal(err)
	}

	options := &x509.VerifyOptions{
		Roots: rootBundle,
	}

	_, err = leafCert.Verify(*options)
	if err != nil {
		log.Fatal(err)
	} else {
		log.Print("Success!")
	}
}
