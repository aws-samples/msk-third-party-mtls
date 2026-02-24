#!/bin/bash

set -e

# Set Kafka brokers
export KAFKA_BROKERS="localhost:9093"

echo "Granting super user ACL powers to User:CN=admin"

~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --remove --force \
  --topic '*' \
  --resource-pattern-type any


# Grant all cluster operations
echo "Granting all cluster operations..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add --allow-principal ${dn} \
  --operation All --cluster

~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add --deny-principal ${dp} \
  --operation All --cluster

~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add \
  --deny-principal ${dp} \
  --operation Describe \
  --topic '*'

~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add \
  --allow-principal ${dn} \
  --operation Describe \
  --topic '*'


# Grant all topic operations
echo "Granting all topic operations..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add --allow-principal $dn \
  --operation Write --topic "test"


# Grant all topic operations
echo "Granting all topic operations..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add --allow-principal $dn \
  --operation All --topic "*"

# Grant all consumer group operations
echo "Granting all consumer group operations..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add --allow-principal $dn \
  --operation All --group "*"

# Grant all transactional ID operations (for exactly-once semantics)
echo "Granting all transactional ID operations..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add --allow-principal User:CN=kafka \
  --operation All --transactional-id "*"

# Grant delegation token operations
echo "Granting delegation token operations..."
~/kafka/bin/kafka-acls.sh --bootstrap-server $brokersiam \
  --command-config /tmp/kafka/client.properties_iam \
  --add --allow-principal User:CN=kafka \
  --operation All --delegation-token "*"

echo ""
echo "Super user ACL powers granted to User:CN=admin"
echo "Admin user now has full permissions on:"
echo "- All cluster operations"
echo "- All topic operations"
echo "- All consumer group operations"
echo "- All transactional ID operations"
echo "- All delegation token operations"
echo ""
echo "Admin can now manage ACLs for other users."
