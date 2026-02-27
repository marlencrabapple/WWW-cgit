#!/usr/bin/env ksh

set -Ce

[ "${DEBUG:-0}" -gt 0 ] && set -x

echo "▶ Creating self-signed x509v3 certificate..."

pkeyalgo="${PKEY_ALGO:-RSA}"
fnbase="${1:-$(hostname)}"

typeset -a pkeyopt=() _

if [[ $pkeyalgo = 'RSA' ]]; then

	pkeyopt=(--pkeyopt rsa_keygen_bits)
fi
openssl genpkey -genparam \
	-algorithm EC \
	-out "${fnbase}_ec_params" \
	-pkeyopt ec_paramgen_curve:secp384r1 \
	-pkeyopt ec_param_enc:named_curve

openssl genpkey -paramfile "${fnbase}_ec_params" \
	-out "$fnbase-key.pem"

csrfile="$fnbase-csr.pem"

openssl req -verbose -new -subj "/C=${SUBJ_C:-US}/CN=${SUBJ_CN:-$(whoami)@$(hostname)}" \
	-addext "subjectAltName=$SAN" \
	-key "$fnbase-key.pem" \
	-out "$csrfile"

openssl x509 -req -in "$csrfile" -key "$fnbase-key.pem" -out "$fnbase.pem"
