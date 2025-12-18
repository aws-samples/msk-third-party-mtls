#!/bin/bash

set -e

echo "Setting up OpenSSL Private CA on Amazon Linux 2..."

# Install OpenSSL
echo "Installing OpenSSL..."
sudo yum update -y
sudo yum install -y openssl openssl-devel

# Create CA directory structure
echo "Creating CA directory structure..."
mkdir -p ~/ca/{private,certs,newcerts,crl}
cd ~/ca
echo 1000 > serial
touch index.txt

# Create CA configuration file
echo "Creating OpenSSL configuration..."
cat > openssl.cnf << 'EOF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = .
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
private_key       = $dir/private/ca-key.pem
certificate       = $dir/certs/ca-cert.pem
default_days      = 365
default_md        = sha256
policy            = policy_strict

[ policy_strict ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF

# Generate CA private key
echo "Generating CA private key..."
openssl genrsa -aes256 -out private/ca-key.pem 4096
chmod 400 private/ca-key.pem

# Create CA certificate
echo "Creating CA certificate..."
openssl req -config openssl.cnf -key private/ca-key.pem \
    -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -out certs/ca-cert.pem

# Verify CA certificate
echo "Verifying CA certificate..."
openssl x509 -noout -text -in certs/ca-cert.pem

echo ""
echo "Private CA setup complete!"
echo "CA certificate: ~/ca/certs/ca-cert.pem"
echo "CA private key: ~/ca/private/ca-key.pem"
echo ""
echo "To sign a certificate request:"
echo "openssl ca -config openssl.cnf -extensions server_cert -days 375 -notext -md sha256 -in server.csr -out server.crt"
