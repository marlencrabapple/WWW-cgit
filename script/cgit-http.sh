#!/usr/bin/env ksh

[[ -z "$BS_CGITROOT" ]] \
  && >&2 echo "《❌️》 BS_CGITROOT must be set for this script to execute properly" \
  && exit $?

cd "$BS_CGITROOT" || (echo STDERR "《❌️》 Could not change directory to '$BS_CGITROOT'!!" && exit 1) 

PERL5LIB="$HOME/Frame/lib:./local/lib/perl5" \
 FRAME_DEBUG=1 \
 DEBUG=1 \
 PLACK_ENV=development \
 CGIT_CONFIG=./etc/frame-app-cgitrc \
 sudo script/cgit.pl -- -s Starlet -p 1526

