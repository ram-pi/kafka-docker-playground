#!/bin/bash

MDS_EP=http://localhost:8091
MDS_BA=c3VwZXJVc2VyOnN1cGVyVXNlcg==

#KAFKA_CLUSTER_ID=h0r1CE3LQYidma5HR0VhWg
KAFKA_CLUSTER_ID=$(docker exec -ti zookeeper zookeeper-shell zookeeper:2181 get /cluster/id 2> /dev/null | grep \"version\" | jq -r .id)
CONNECT=connect-cluster
SR=schema-registry
KSQLDB=ksql-cluster
C3=c3-cluster

# log MDS restarting
# [2022-10-26 08:57:44,939] DEBUG [io.confluent.security.store.kafka.coordinator.MetadataNodeManager clientId=_confluent-metadata-coordinator-1, groupId=_confluent-metadata-coordinator-group]Received successful Heartbeat response (io.confluent.security.store.kafka.coordinator.MetadataServiceCoordinator)

# debug on -> set -x 
# debug off -> set +x
set +x

ROLES=$(curl --request GET --url $MDS_EP/security/1.0/roleNames --header "Authorization: Basic ${MDS_BA}" 2> /dev/null | sed 's/[][]//g')
#echo "Available roles on the cluster are $ROLES"

# set comma as internal field separator for the string list
set +x
IFS=,
PRINCPALS=
for r in $ROLES;
do
  # strip quotes
  r="${r//\"/}"

  # get principals for each role
  ROLE_PRINCIPALS=
  ROLE_PRINCIPALS=$(curl --request POST --url $MDS_EP/security/1.0/lookup/role/${r} --header "Authorization: Basic ${MDS_BA}" --header 'Content-Type: application/json' \
  --data '{
    "clusters": {
        "kafka-cluster": "'"${KAFKA_CLUSTER_ID}"'"
      }
    }' 2> /dev/null | sed 's/[][]//g')
  #echo "Principal for $r are $ROLE_PRINCIPALS"
  PRINCPALS+=$ROLE_PRINCIPALS,
done

#echo "Found these principals: $PRINCPALS"

echo "principal,cluster,role,bindings"
bindings=0
for p in $PRINCPALS;
do
  for r in $ROLES;
  do
    if [ -z "$p" ] || [ -z "$r" ]
    then
        break
    fi

    # strip quotes
    p_strips_quotes="${p//\"/}"
    r="${r//\"/}"

    # get bindings per principal per role on kafka-cluster
    tmp=$(curl --request POST --url $MDS_EP/security/1.0/lookup/rolebindings/principal/$p_strips_quotes --header 'Authorization: Basic '"${MDS_BA}"'' --header 'Content-Type: application/json' --data '{
        "clusters": {
            "kafka-cluster": "'"${KAFKA_CLUSTER_ID}"'"
        }
    }
    ' 2> /dev/null | jq '.rolebindings.'"${p}"'.'"${r}"' | length')

    echo $p_strips_quotes,kafka_cluster,$r,$tmp
    bindings=`expr $bindings + $tmp`

    # get bindings per principal per role on schema-registry
    tmp=$(curl --request POST --url $MDS_EP/security/1.0/lookup/rolebindings/principal/$p_strips_quotes --header 'Authorization: Basic '"${MDS_BA}"'' --header 'Content-Type: application/json' --data '{
        "clusters": {
            "kafka-cluster": "'"${KAFKA_CLUSTER_ID}"'",
            "schema-registry-cluster": "'"${SR}"'"
        }
    }
    ' 2> /dev/null | jq '.rolebindings.'"${p}"'.'"${r}"' | length')

    echo $p_strips_quotes,schema-registry,$r,$tmp
    bindings=`expr $bindings + $tmp`

    # get bindings per principal per role on connect
    tmp=$(curl --request POST --url $MDS_EP/security/1.0/lookup/rolebindings/principal/$p_strips_quotes --header 'Authorization: Basic '"${MDS_BA}"'' --header 'Content-Type: application/json' --data '{
        "clusters": {
            "kafka-cluster": "'"${KAFKA_CLUSTER_ID}"'",
            "connect-cluster": "'"${CONNECT}"'"
        }
    }
    ' 2> /dev/null | jq '.rolebindings.'"${p}"'.'"${r}"' | length')

    echo $p_strips_quotes,connect,$r,$tmp
    bindings=`expr $bindings + $tmp`

    # get bindings per principal per role on ksql
    tmp=$(curl --request POST --url $MDS_EP/security/1.0/lookup/rolebindings/principal/$p_strips_quotes --header 'Authorization: Basic '"${MDS_BA}"'' --header 'Content-Type: application/json' --data '{
        "clusters": {
            "kafka-cluster": "'"${KAFKA_CLUSTER_ID}"'",
            "ksql-cluster": "'"${KSQL}"'"
        }
    }
    ' 2> /dev/null | jq '.rolebindings.'"${p}"'.'"${r}"' | length')

    echo $p_strips_quotes,ksql,$r,$tmp
    bindings=`expr $bindings + $tmp`
  done
done

echo all,all,all,$bindings


# curl --request POST --url http://localhost:8091/security/1.0/lookup/rolebindings/principal/Group:KafkaDevelopers --header 'Authorization: Basic c3VwZXJVc2VyOnN1cGVyVXNlcg==' --header 'Content-Type: application/json' --data '{
#     "clusters": {
#         "kafka-cluster": "h0r1CE3LQYidma5HR0VhWg"
#     }
# }
# ' 2> /dev/null | jq '.rolebindings."Group:KafkaDevelopers".ResourceOwner | length'
