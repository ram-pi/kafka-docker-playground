#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

. ${DIR}/functions.sh

KAFKA_CLUSTER_ID=$(get_kafka_cluster_id_from_container)
MDS_URL=http://broker:8091
CONNECT=connect-cluster
SR=schema-registry
KSQLDB=ksql-cluster
C3=c3-cluster

SUPER_USER=superUser
SUPER_USER_PASSWORD=superUser
SUPER_USER_PRINCIPAL="User:$SUPER_USER"
KAFKA_DEVELOPPERS_GROUP="Group:KafkaDevelopers"

mds_login $MDS_URL ${SUPER_USER} ${SUPER_USER_PASSWORD} || exit 1

LIMIT=$1

echo $TOPIC
echo "Creating $LIMIT role bindings"

for (( n=1; n<=$LIMIT; n++ ))
do
  #TOPIC=`echo $RANDOM | base64 | head -c 10; echo;`
  TOPIC=$(openssl rand -hex 6)
  confluent iam rolebinding create \
  --principal $KAFKA_DEVELOPPERS_GROUP \
  --role ResourceOwner \
  --resource Topic:$TOPIC \
  --kafka-cluster-id $KAFKA_CLUSTER_ID
done

