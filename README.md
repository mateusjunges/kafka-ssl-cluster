# Kafka SSL Cluster

This repository provides a docker compose file to create a Kafka cluster with SSL enabled.

## Installation

### Clone the repository and `cd` into the directory:

```bash
git@github.com:mateusjunges/kafka-ssl-cluster.git 
cd kafka-ssl-cluster
```

### Create the certificates

```bash
./bootstrap.sh
```

Start docker with

```bash
docker compose up -d
```

Now, the cluster is ready to use. You can start a terminal in the container with the following command:

```bash
docker compose exec -it kafka-1 bash
```

And then, you can create topics using 

```bash
kafka-topics --bootstrap-server localhost:19092 --create --topic messages203 --replica-assignment 101:102:103 
```

## Using with Laravel Kafka

You can create a consumer and connect to the cluster using SSL. Here is an example of how to do it:

```php
$consumer = Kafka::consumer(brokers: 'localhost:19093')
    ->subscribe('messages')
    ->withOptions([
        'ssl.ca.location' => 'path-to/ca.crt'),
        'ssl.certificate.location' => 'path-to/ca.pem',
        'ssl.key.location' => 'path-to/ca.key',
        'ssl.key.password' => 'confluent',
        'enable.ssl.certificate.verification' => 'true',
        'security.protocol' => 'ssl',
    ])
    ->withSecurityProtocol('SSL')
    ->withHandler(function (ConsumedMessage $message, MessageConsumer $messageConsumer) {
        $log = [
            'body' => $message->getBody(),
            'partition' => $message->getPartition(),
            'key' => $message->getKey(),
            'topic' => $message->getTopicName(),
        ];

        $this->info(json_encode($log));
    })
    ->onStopConsuming(function () {
        $this->line('Consumer stopped.');
        $this->newLine();
    })->build();

$consumer->consume();
```
