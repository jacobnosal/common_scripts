#!/usr/bin/env sh
#
# Purpose:
#   Given a PKCS#12 (.pfx file bundle), creates the files needed
#   to configure SSL for a kubernetes ingress resource. 
#
# Outputs: A .crt and .key file for use with `kubectl create secret tls`
#
# Arguments:
#   -f Input .pfx file.
#   -p File prefix for constructing output file names.
#   -o Output Directory.
#
# Operation:
#   This script doesn't handle the case where the pfx_file is password protected.
#   As a result, this script requires entering any passwords at the terminal.


while getopts f:p:o: flag
do
    case "${flag}" in
        f) pfx_file=${OPTARG};;
        p) prefix=${OPTARG};;
        o) output=${OPTARG};;
    esac
done

encrypted_key_file="${output}/${prefix}.enc.key"
unencrypted_key_file="${output}/${prefix}.key"
cer_file="${output}/${prefix}.cer"
crt_file="${output}/${prefix}.crt"

openssl pkcs12 -in $pfx_file -nocerts -out $encrypted_key_file
openssl rsa -in $encrypted_key_file -outform PEM -out $unencrypted_key_file
openssl pkcs12 -in $pfx_file -clcerts -nokeys -out $cer_file
openssl pkcs12 -in $pfx_file -nodes -nokeys -nomac -out $crt_file

cat <<EOF
Example Command to create a tls secret in kubernetes:

kubectl create secret tls ${prefix}-tls --namespace <your-namespace> --key=${unencrypted_key_file} --cert=${crt_file}
EOF