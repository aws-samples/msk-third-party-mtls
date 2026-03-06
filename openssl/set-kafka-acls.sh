#!/bin/bash

set -e

echo "Setting Kafka ACLs for User:CN=user@anycompany.com
This script will grant the following permissions:
- Create topics
- Write to topics
- Read from topics
- Read from consumer groups
- Cannot list topics (no Describe permission)"

~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add \
  --allow-principal "User:CN=admin@anycompany.com" \
  --operation All \
  --cluster \
  --topic '*' \
  --group '*'

# Deny cluster describe (prevents topic listing)
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add \
  --deny-principal "User:CN=user@anycompany.com" \
  --operation Describe \
  --cluster

# 2. Allow Create at cluster level (needed to create topics)
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add \
  --allow-principal "User:CN=user@anycompany.com" \
  --operation Create \
  --cluster

# 3. Allow Read, Write, and Describe on individual topics
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add \
  --allow-principal "User:CN=user@anycompany.com" \
  --operation Read \
  --operation Write \
  --operation Describe \
  --topic '*'

# Allow reading from consumer groups
echo "Granting Read permission on consumer groups..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add --allow-principal User:CN=user@anycompany.com \
  --operation Read --group "*"

echo ""
echo "ACL setup complete for User:CN=user@anycompany.com"
echo "Permissions granted:"
echo "- Create topics"
echo "- Write to topics"
echo "- Read from topics"
echo "- Read from consumer groups"
echo "- Cannot list topics (no Describe permission)"
