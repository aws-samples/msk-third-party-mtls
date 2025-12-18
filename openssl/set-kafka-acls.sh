#!/bin/bash

set -e

echo "Setting Kafka ACLs for User:CN=application"

# Allow creating topics
echo "Granting Create permission on topics..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add --allow-principal User:CN=application \
  --operation Create --topic "*"

# Allow writing to topics
echo "Granting Write permission on topics..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add --allow-principal User:CN=application \
  --operation Write --topic "*"

# Allow reading from topics
echo "Granting Read permission on topics..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add --allow-principal User:CN=application \
  --operation Read --topic "*"

# Allow reading from consumer groups
echo "Granting Read permission on consumer groups..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $KAFKA_BROKERS --command-config kafka-admin-ssl.properties \
  --add --allow-principal User:CN=application \
  --operation Read --group "*"

echo ""
echo "ACL setup complete for User:CN=application"
echo "Permissions granted:"
echo "- Create topics"
echo "- Write to topics"
echo "- Read from topics"
echo "- Read from consumer groups"
echo "- Cannot list topics (no Describe permission)"
