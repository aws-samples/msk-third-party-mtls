#!/bin/bash

set -e

# Check if client name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <client-name>"
    echo "Example: $0 john.doe"
    exit 1
fi

CLIENT_NAME="$1"

echo "Generating client certificate for: $CLIENT_NAME"

# Navigate to CA directory
cd ~/ca

# Add client certificate extensions if not already present
if ! grep -q "usr_cert" openssl.cnf; then
    echo "Adding client certificate extensions..."
    cat >> openssl.cnf << 'EOF'

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
EOF
fi

# Generate client private key
echo "Generating client private key..."
openssl genrsa -out private/${CLIENT_NAME}-key.pem 2048
chmod 400 private/${CLIENT_NAME}-key.pem

# Generate client certificate request
echo "Generating client certificate request..."
openssl req -config openssl.cnf -key private/${CLIENT_NAME}-key.pem \
    -new -sha256 -out ${CLIENT_NAME}.csr \
    -subj "/CN=${CLIENT_NAME}"

# Sign the client certificate
echo "Signing client certificate..."
openssl ca -config openssl.cnf -extensions usr_cert \
    -policy policy_anything \
    -days 375 -notext -md sha256 \
    -in ${CLIENT_NAME}.csr \
    -out certs/${CLIENT_NAME}-cert.pem

# Verify the client certificate
echo "Verifying client certificate..."
openssl x509 -noout -text -in certs/${CLIENT_NAME}-cert.pem
openssl verify -CAfile certs/ca-cert.pem certs/${CLIENT_NAME}-cert.pem

# Create PKCS#12 bundle (optional)
echo "Creating PKCS#12 bundle..."
openssl pkcs12 -export -out certs/${CLIENT_NAME}.p12 \
    -inkey private/${CLIENT_NAME}-key.pem \
    -in certs/${CLIENT_NAME}-cert.pem \
    -certfile certs/ca-cert.pem

# Clean up CSR
rm ${CLIENT_NAME}.csr

echo ""
echo "Client certificate generation complete!"
echo "Certificate: ~/ca/certs/${CLIENT_NAME}-cert.pem"
echo "Private key: ~/ca/private/${CLIENT_NAME}-key.pem"
echo "PKCS#12 bundle: ~/ca/certs/${CLIENT_NAME}.p12"
echo ""
echo "Certificate details:"
openssl x509 -noout -subject -dates -in certs/${CLIENT_NAME}-cert.pem
