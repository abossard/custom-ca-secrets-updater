#!/bin/bash
# https://unix.stackexchange.com/a/487546
HOSTNAME=$1
MY_PORT=${PORT:-443}
YAML_FOLDER=secrets/
mkdir $YAML_FOLDER

openssl s_client -showcerts -verify 5 -connect $HOSTNAME:$PORT < /dev/null |
   awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN CERTIFICATE/){a++}; out="cert"a".crt"; print >out}'
for cert in *.crt; do 
        newname=$(openssl x509 -noout -subject -in $cert | sed -nE 's/.*CN ?= ?(.*)/\1/; s/[ ,.*]/_/g; s/__/_/g; s/_-_/-/; s/^_//g; s/[\/=]//g; p' | tr '[:upper:]' '[:lower:]').crt
        echo "${newname}"; mv "${cert}" "${newname}" 
done

for cert in *.crt; do
        secret_name="${cert%.*}"
        kubectl create secret generic "${secret_name}" --from-file="${cert}"="${cert}" --dry-run=client -o yaml >! "${YAML_FOLDER}${secret_name}.yaml"
done
rm -rf *.crt