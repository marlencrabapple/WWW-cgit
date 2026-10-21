#!/usr/bin/env ksh

[[ $DEBUG -eq 1 ]] && set -x -ofunctrace

workdir="$(mktemp -d)"
cd "$workdir" || exit $?

(
  export CATOP="/bs/trust/x509/CA/server"
  export CAROOT="/bs/trust/x509/CA"

  env SUBJ_CN="" \
    CA_CERT="$CATOP/systems@cincotuf.lan_Server_Auth_RSA_G1.pem" \
    CA_KEY="$CATOP/private/systems@cincotuf.lan_Server_Auth_RSA_G1-key.pem" \
    SAN="DNS.0:cgit.cincotuf.lan,DNS.1:git.d8574.pennyfoss.org,DNS.2:localhost,IP.0:192.168.1.155,IP.1:192.168.86.145,IP.2:127.0.0.1,IP.3:::1" \
    newcert.sh "cgit.cincotuf.lan"
)

sudo chown http:http ./*.pem

for pem in ./*.pem; do
  [[ -f "../$(basename "$pem")" ]] \
    && mv "../$(basename "$pem")" "../$(basename "$pem").old-$(epoch)"
  mv -v "$pem" ../
done
