#!/usr/bin/env ksh

set -Ce

[ "${DEBUG:-0}" -gt 0 ] && set -x

echo "▶ Creating self-signed x509v3 certificate..."

pkeyalgo="${PKEY_ALGO:-RSA}"
fnbase="${1:-$(hostname)}"

typeset -a pkeyopt=()

if [[ $pkeyalgo == 'RSA' ]]; then
	pkeyopt=(--algorithm RSA
		--pkeyopt "rsa_keygen_bits:${PKEY_BITS:-4096}")
elif [[ $pkeyalgo == 'EC' ]]; then
	ec_paramfile="${fnbase}_ec_params"
	ec_paramgen_curve="${PKEY_CURVE:-secp384r1}"

	openssl genpkey -genparam \
		-algorithm EC \
		-out "$ec_paramfile" \
		-pkeyopt "ec_paramgen_curve:$ec_paramgen_curve" \
		-pkeyopt ec_param_enc:named_curve

	pkeyopt=(--paramfile "$ec_paramfile")
fi

openssl genpkey -verbose "${pkeyopt[@]}" \
	-out "$fnbase-key.pem"

csrfile="$fnbase-csr.pem"

openssl req -new -subj "/C=${SUBJ_C:-US}/CN=${SUBJ_CN:-$(whoami)@$(hostname)}" \
	-addext "subjectAltName=$SAN" \
	-key "$fnbase-key.pem" \
	-out "$csrfile"

openssl x509 -req -in "$csrfile" -copy_extensions copy -key "$fnbase-key.pem" -out "$fnbase.pem"
