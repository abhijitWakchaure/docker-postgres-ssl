#!/bin/bash

if [ -z "$CERTS_ROOT" ]; then
  CERTS_ROOT="$(pwd)"
  echo -e "\nEnv var CERTS_ROOT is not defined...using PWD ($CERTS_ROOT) as CERTS_ROOT"
fi

if [ "$DEV_MODE" != "true" ]; then
  # Check if curl is installed
  if ! [ -x "$(command -v curl)" ]; then
    echo -e "\ncURL is not installed...installing cURL now"
    apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
  fi
  # Get hostname from EC2 Instance Metadata Service
  DOMAINNAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
  echo -e "\nAutodected FQDN for EC2: ${DOMAINNAME}"
else
  DOMAINNAME="${DOMAINNAME:-localhost}"
  echo -e "\nDEV_MODE is enabled...using DOMAINNAME as '${DOMAINNAME}'"
fi

if [ -z "$DOMAINNAME" ]; then
  # read -p 'Enter Domain Name [FQDN]: ' DOMAINNAME
  exit_with_error "Failed to get hostname/FQDN from EC2 Instance Metadata Service" 
fi

IP="${DOMAINNAME}"
SUBJECT_CA="/C=IN/ST=MH/L=Pune/O=TIBCO/OU=CA/CN=$IP"
SUBJECT_SERVER="/C=IN/ST=MH/L=Pune/O=TIBCO/OU=Server/CN=$IP"
SUBJECT_CLIENT="/C=IN/ST=MH/L=Pune/O=TIBCO/OU=Client/CN=$IP"

# File names
ROOT_CA_KEY="rootCA.key.pem"
ROOT_CA_CRT="rootCA.crt.pem"
SERVER_KEY="server.key.pem"
SERVER_CRT="server.crt.pem"
CLIENT_KEY="client.key.pem"
CLIENT_CRT="client.crt.pem"

function generate_CA () {
   echo "$SUBJECT_CA"
   openssl req -x509 -nodes -sha256 -newkey rsa:2048 -subj "$SUBJECT_CA"  -days 365 -keyout ${ROOT_CA_KEY} -out ${ROOT_CA_CRT}
}

function generate_server () {
   echo "$SUBJECT_SERVER"
   openssl req -nodes -sha256 -new -subj "$SUBJECT_SERVER" -keyout ${SERVER_KEY} -out server.csr
   openssl x509 -req -sha256 -in server.csr -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} -CAcreateserial -out ${SERVER_CRT} -days 365
}

function generate_client () {
   echo "$SUBJECT_CLIENT"
   openssl req -new -nodes -sha256 -subj "$SUBJECT_CLIENT" -out client.csr -keyout ${CLIENT_KEY} 
   openssl x509 -req -sha256 -in client.csr -CA ${ROOT_CA_CRT} -CAkey ${ROOT_CA_KEY} -CAcreateserial -out ${CLIENT_CRT} -days 365
}

cd $CERTS_ROOT
rm -rf certs
mkdir -p certs
pushd certs
    generate_CA
    generate_server
    generate_client

    rm -f *.csr *.ext *.srl *.cnf
popd