#!/bin/sh

## Create data/log folders
for i in 1 2 3
do
  mkdir "data-kafka-$i"
  mkdir "data-zk-data-$i"
  mkdir "data-zk-log-$i"
done

openssl req -new -nodes \
   -x509 \
   -days 365 \
   -newkey rsa:2048 \
   -keyout ca.key \
   -out ca.crt \
   -config ca.cnf

cat ca.crt ca.key > ca.pem

clusters=(1 2 3)

# Loop through each cluster
for cluster in "${clusters[@]}"
do
    echo "Processing $cluster..."

    # Generate the key and certificate signing request (CSR)
    openssl req -new \
        -newkey rsa:2048 \
        -keyout secrets-$cluster/kafka-$cluster.key \
        -out secrets-$cluster/kafka-$cluster.csr \
        -config secrets-$cluster/kafka-$cluster.cnf \
        -nodes

    # Sign the CSR with the CA to generate the certificate
    openssl x509 -req \
        -days 3650 \
        -in secrets-$cluster/kafka-$cluster.csr \
        -CA ca.crt \
        -CAkey ca.key \
        -CAcreateserial \
        -out secrets-$cluster/kafka-$cluster.crt \
        -extfile secrets-$cluster/kafka-$cluster.cnf \
        -extensions v3_req

    # Export the certificate and key to a PKCS#12 file
    openssl pkcs12 -export \
        -in secrets-$cluster/kafka-$cluster.crt \
        -inkey secrets-$cluster/kafka-$cluster.key \
        -chain \
        -CAfile ca.pem \
        -name kafka-$cluster \
        -out secrets-$cluster/kafka-$cluster.p12 \
        -password pass:confluent

    keytool -importkeystore \
        -deststorepass confluent \
        -destkeystore secrets-$cluster/kafka.kafka-$cluster.keystore.pkcs12 \
        -srckeystore secrets-$cluster/kafka-$cluster.p12 \
        -deststoretype PKCS12  \
        -srcstoretype PKCS12 \
        -noprompt \
        -srcstorepass confluent

    echo "confluent" > secrets-$cluster/kafka-${cluster}_sslkey_creds
    echo "confluent" > secrets-$cluster/kafka-${cluster}_keystore_creds
    echo "Finished processing cluster $cluster."
done






