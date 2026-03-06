#!/bin/bash

set -e

# Check if CSR file path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-csr-file>"
    echo "Example: $0 /path/to/acm-ca.csr"
    exit 1
fi

# Convert to absolute path before changing directories
CSR_FILE=$(realpath "$1")

# Check if CSR file exists
if [ ! -f "$CSR_FILE" ]; then
    echo "Error: CSR file '$CSR_FILE' not found"
    exit 1
fi

echo "Signing AWS ACM subordinate CA CSR: $CSR_FILE"

# Navigate to CA directory
cd ~/ca

# Add subordinate CA extensions to config if not already present
if ! grep -q "v3_subordinate_ca" openssl.cnf; then
    echo "Adding subordinate CA extensions to config..."
    cat >> openssl.cnf << 'EOF'

[ v3_subordinate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:true,pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF
fi

# Add flexible policy for subordinate CAs if not already present
if ! grep -q "policy_anything" openssl.cnf; then
    echo "Adding flexible policy for subordinate CAs..."
    cat >> openssl.cnf << 'EOF'

[ policy_anything ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional
EOF
fi

# Sign the AWS ACM CSR
echo "Signing the CSR..."
openssl ca -config openssl.cnf -extensions v3_subordinate_ca \
    -policy policy_anything \
    -days 3650 -notext -md sha256 \
    -in "$CSR_FILE" \
    -out certs/acm-subordinate-ca-cert.pem

# Verify the certificate
echo "Verifying the signed certificate..."
openssl x509 -noout -text -in certs/acm-subordinate-ca-cert.pem
openssl verify -CAfile certs/ca-cert.pem certs/acm-subordinate-ca-cert.pem

# Create certificate chain for ACM
echo "Creating certificate chain..."
cat certs/ca-cert.pem > certs/acm-ca-chain.pem

echo ""
echo "AWS ACM subordinate CA signing complete!"
echo "Signed certificate: ~/ca/certs/acm-subordinate-ca-cert.pem"
echo "Root CA certificate: ~/ca/certs/ca-cert.pem"
echo "Certificate chain: ~/ca/certs/acm-ca-chain.pem"
echo ""
echo "Upload these files to AWS ACM:"
echo "1. Signed certificate: certs/acm-subordinate-ca-cert.pem"
echo "2. Root CA certificate: certs/ca-cert.pem"
