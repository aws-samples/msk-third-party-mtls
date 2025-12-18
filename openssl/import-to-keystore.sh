#!/bin/bash

set -e

# Check if p12 file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <p12-file> [keystore-name] [alias]"
    echo "Example: $0 john.doe.p12"
    echo "Example: $0 john.doe.p12 my-keystore.jks"
    echo "Example: $0 john.doe.p12 my-keystore.jks my-cert"
    exit 1
fi

P12_FILE="$1"
KEYSTORE_NAME="$(basename "${2:-kafka.client.truststore.jks}")"
ALIAS="${3:-client-cert}"

# Create config directory if it doesn't exist
mkdir -p config

# Check if p12 file exists
if [ ! -f "$P12_FILE" ]; then
    echo "Error: P12 file '$P12_FILE' not found"
    exit 1
fi

# Copy Java cacerts to create truststore if it doesn't exist
if [ ! -f "config/$KEYSTORE_NAME" ]; then
    echo "Copying Java cacerts to create truststore..."
    # Amazon Corretto 17 (Amazon Linux 2023)
    if [ -f "/usr/lib/jvm/java-17-amazon-corretto/lib/security/cacerts" ]; then
        cp /usr/lib/jvm/java-17-amazon-corretto/lib/security/cacerts config/$KEYSTORE_NAME
    # Amazon Corretto 11
    elif [ -f "/usr/lib/jvm/java-11-amazon-corretto/lib/security/cacerts" ]; then
        cp /usr/lib/jvm/java-11-amazon-corretto/lib/security/cacerts config/$KEYSTORE_NAME
    # OpenJDK 8 (Amazon Linux 2)
    elif [ -f "/usr/lib/jvm/java-1.8.0-openjdk/jre/lib/security/cacerts" ]; then
        cp /usr/lib/jvm/java-1.8.0-openjdk/jre/lib/security/cacerts config/$KEYSTORE_NAME
    else
        echo "ERROR: JVM cacerts not found. Please locate your Java installation."
        exit 1
    fi
    # Make the copied file writable
    chmod 644 config/$KEYSTORE_NAME
else
    echo "Truststore already exists: config/$KEYSTORE_NAME"
fi

echo "Importing $P12_FILE into truststore: config/$KEYSTORE_NAME"

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "Error: keytool not found. Please install Java JDK"
    exit 1
fi

# Import p12 into truststore
echo "Importing certificate..."
keytool -importkeystore \
    -srckeystore "$P12_FILE" \
    -srcstoretype PKCS12 \
    -destkeystore "config/$KEYSTORE_NAME" \
    -deststoretype JKS \
    -noprompt

# Rename the imported alias if it's not already the desired alias
echo "Setting alias to: $ALIAS"
keytool -changealias \
    -keystore "config/$KEYSTORE_NAME" \
    -alias "1" \
    -destalias "$ALIAS" \
    -noprompt 2>/dev/null || true

# List truststore contents
echo ""
echo "Truststore contents:"
keytool -list -keystore "config/$KEYSTORE_NAME"

echo ""
echo "Import complete!"
echo "Truststore file: config/$KEYSTORE_NAME"
echo ""
echo "To use in Java applications:"
echo "  -Djavax.net.ssl.trustStore=config/$KEYSTORE_NAME"
echo "  -Djavax.net.ssl.trustStorePassword=changeit"
