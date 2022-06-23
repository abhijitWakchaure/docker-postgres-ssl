#!/usr/bin/env bash
# Author: Abhijit Wakchaure <awakchau@tibco.com>

# arg1: error message
# [arg2]: exit code
function exit_with_error {
    printf '\n%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2-1}" ## Return a code specified by $2, or 1 by default.
}

RUNNING_ON_HOST=$(grep 'docker\|lxc' /proc/1/cgroup)

if [ -z "$RUNNING_ON_HOST" ]; then
  exit_with_error "No need to run this script manually on host machine. Certificates are already generated and used"
fi

if [ -z "$CERTS_ROOT" ]; then
  exit_with_error "Env var CERTS_ROOT is undefined"
fi

cd $CERTS_ROOT
rm -rf certs
mkdir -p certs
pushd certs

# Check if curl is installed
if ! [ -x "$(command -v curl)" ]; then
  echo 'cURL is not installed...installing cURL now'
  apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
fi

# Get hostname from EC2 Instance Metadata Service
DOMAINNAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)

if [ -z "$DOMAINNAME" ]; then
  # read -p 'Enter Domain Name [FQDN]: ' DOMAINNAME
  exit_with_error "Failed to get hostname/FQDN from EC2 Instance Metadata Service"
else
  echo "Autodected FQDN for EC2: ${DOMAINNAME}"
fi

# Constants
COUNTRY="IN"
STATE="MH"
LOCALITY="Pune"
ORGNAME="TIBCO"
ORGUNIT="Connectors"
COMMONNAMEFQDN=$DOMAINNAME

# File names
ROOT_CA_KEY="rootCA.key.pem"
ROOT_CA_CRT="rootCA.crt.pem"
SERVER_KEY="server.key.pem"
SERVER_CRT="server.crt.pem"
CLIENT_KEY="client.key.pem"
CLIENT_CRT="client.crt.pem"

cat <<EOF >server.csr.cnf
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=$COUNTRY
ST=$STATE
L=$LOCALITY
O=$ORGNAME
OU=$ORGUNIT
emailAddress=admin@$DOMAINNAME
CN=$DOMAINNAME
EOF

cat <<EOF >client.csr.cnf
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn

[dn]
C=$COUNTRY
ST=$STATE
L=$LOCALITY
O=$ORGNAME
OU=$ORGUNIT
emailAddress=client@$DOMAINNAME
CN=$DOMAINNAME
EOF

cat <<EOF >server.ext
authorityKeyIdentifier = keyid,issuer
basicConstraints       = CA:FALSE
keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement, keyCertSign
subjectAltName         = @alt_names
issuerAltName          = issuer:copy

[alt_names]
DNS.1=$DOMAINNAME
DNS.2=*.$DOMAINNAME
EOF


echo -e '\n*******  STEP 1/10: Creating private key for root CA  *******\n'
openssl genrsa -out $ROOT_CA_KEY 2048

echo -e '\n*******  STEP 2/10: Creating root CA certificate  *******\n'
cat <<__EOF__ | openssl req -new -x509 -nodes -days 1024 -key $ROOT_CA_KEY -sha256 -out $ROOT_CA_CRT
$COUNTRY
$STATE
$LOCALITY
$ORGNAME
$ORGUNIT
$COMMONNAMEFQDN
admin@rootca.$DOMAINNAME
__EOF__

echo -e '\n*******  STEP 3/10: Creating private key for server  *******\n'
openssl genrsa -out $SERVER_KEY 2048

echo -e '\n*******  STEP 4/10: Creating CSR for server  *******\n'
openssl req -new -key $SERVER_KEY -out server.csr -config <(cat server.csr.cnf)

echo -e '\n*******  STEP 5/10: Creating server certificate  *******\n'
openssl x509 -req -in server.csr -CA $ROOT_CA_CRT -CAkey $ROOT_CA_KEY -CAcreateserial -out $SERVER_CRT -days 1024 -sha256 -extfile server.ext

echo -e '\n*******  STEP 6/10: Creating private key for client  *******\n'
openssl genrsa -out $CLIENT_KEY 2048

echo -e '\n*******  STEP 7/10: Creating CSR for client  *******\n'
openssl req -new -key $CLIENT_KEY -out client.csr -config <(cat client.csr.cnf)

echo -e '\n*******  STEP 8/10: Creating client certificate  *******\n'
openssl x509 -req -in client.csr -CA $ROOT_CA_CRT -CAkey $ROOT_CA_KEY -CAcreateserial -out $CLIENT_CRT -days 1024 -sha256

# echo -e '\n*******  STEP 9/10: Converting all keys in PKCS1 format for backward compatibility  *******\n'
# openssl rsa -in $ROOT_CA_KEY -out rootCA.pkcs1.key
# openssl rsa -in $SERVER_KEY -out server.pkcs1.key
# openssl rsa -in $CLIENT_KEY -out client.pkcs1.key

echo -e '\n*******  STEP 10/10: Deleting extra files  *******\n'
rm -f *.csr *.ext *.srl *.cnf

popd