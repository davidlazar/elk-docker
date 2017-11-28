#!/bin/bash
set -e

EASYRSA_VERSION=3.0.3

if [ -z "$ELK_HOST" ]; then
    echo "ELK_HOST is not set"
    exit 1
fi

if [ -z "$KIBANA_PW" ]; then
    echo "KIBANA_PW is not set"
    exit 1
fi

mkdir -p elasticsearch/data
mkdir -p nginx/htpasswd

echo "Creating .env"
echo "ELK_HOST=${ELK_HOST}" > .env

echo "Setting password for Kibana user kbadmin"
sudo docker run --rm -it xmartlabs/htpasswd kbadmin "$KIBANA_PW" > "nginx/htpasswd/$ELK_HOST"

echo "Fetching EasyRSA $EASYRSA_VERSION"
wget -N https://github.com/OpenVPN/easy-rsa/releases/download/v${EASYRSA_VERSION}/EasyRSA-${EASYRSA_VERSION}.tgz
tar xf EasyRSA-$EASYRSA_VERSION.tgz

easyrsa="EasyRSA-$EASYRSA_VERSION/easyrsa --pki-dir=pki --batch"

echo "Creating PKI and CA certificate"
$easyrsa init-pki
$easyrsa build-ca nopass

echo "Creating logstash server certificate"
$easyrsa build-server-full $ELK_HOST nopass

mkdir -p logstash/sslkeys
cp -iv "pki/ca.crt" logstash/sslkeys/ca.crt
cp -iv "pki/issued/$ELK_HOST.crt" logstash/sslkeys/server.crt
cp -iv "pki/private/$ELK_HOST.key" logstash/sslkeys/server.key
