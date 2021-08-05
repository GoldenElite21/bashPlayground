#!/bin/bash

my_server=""
my_port=443
my_public=0
my_finger=0
my_expire=0

function usage {
    echo -e "
    \tFlags:
    \t\t-s|-server : server (subdomain.domain.com)
    \t\t-p|-port   : port   (443, defaults if not provided)
    \t\t-c|--public : public cert, flag
    \t\t-f|--finger : fingerprint, flag
    \t\t-e|--expire : expiration date, flag
    \t\t-n|--sans   : all sans, flag
    \t\t-r|--serial : serial, flag
    \t\t-t|--schannel : Available SSL/TLS + CipherSuites 
    
    \tExample Usage:
    \t\t${0} my_server
    \t\t${0} -s my_server.domain.com -f
    \t\t${0} -s my_server.domain.com -p 8443 -f -e -c
    "
    exit 1
}


if [[ $# -eq 1 ]] ; then
    my_server=${1}
    my_port=443
    my_public=1
    my_finger=1
    my_expire=1
    my_sans=1
    my_serial=1
    my_schannel=1
else
   while test $# != 0
   do
       case "$1" in
           -s|-server)    shift; my_server=${1} ;;
           -p|-port)      shift; my_port=${1} ;;
           -c|--public)   my_public=1 ;;
           -f|--finger)   my_finger=1 ;;
           -e|--expire)   my_expire=1 ;;
           -n|--sans)     my_sans=1 ;;
           -r|--serial)   my_serial=1 ;;
           -t|--schannel) my_schannel=1 ;;
           *)  usage ;;
       esac
       shift
   done
fi

if [ "" = "${my_server}" ]; then
  echo -e "\n\tERROR: Define the server at least.."
	usage
	exit 1
fi
if [ "" = "${my_port}" ]; then
  echo -e "\n\tERROR: Define the port.."
  usage
  exit 1
fi

if [[ $(($my_public + $my_finger + $my_expire)) == 0 ]]; then
	echo -e "\n\tERROR: Pass a flag for action.."
fi

## Print the Server and Port, but still allow redirect of output to a file
(>&2 echo "Server: [${my_server}] on port [${my_port}]")

if [[ ${my_public} -eq 1 ]]; then
	openssl x509 -in <(openssl s_client -servername ${my_server} -connect ${my_server}:${my_port} -prexit 2>/dev/null) | grep -v "^-"
fi

if [[ ${my_finger} -eq 1 ]]; then
        (>&2 echo -e -n "\nFingerprint: ")
	openssl s_client -connect ${my_server}:${my_port} </dev/null 2>/dev/null | openssl x509 -noout -fingerprint | cut -d'=' -f2 | tr -d ':'
fi

if [[ ${my_serial} -eq 1 ]]; then
        (>&2 echo -e -n "\nSerial: ")
        openssl s_client -connect ${my_server}:${my_port} </dev/null 2>/dev/null | openssl x509 -noout -serial | cut -d '=' -f2
fi

if [[ ${my_expire} -eq 1 ]]; then
        (>&2 echo -e -n "\nExpires: ")
        openssl s_client -connect ${my_server}:${my_port} </dev/null 2>/dev/null | openssl x509 -noout -enddate | cut -d '=' -f2
fi

if [[ ${my_sans} -eq 1 ]]; then
        (>&2 echo -e -n "\nSANS:\n")
        openssl s_client -connect ${my_server}:${my_port} </dev/null 2>/dev/null | openssl x509 -noout -text | grep DNS | sed 's/DNS\://g' | sed 's/, /\n/g' | sed 's/^[ ]*//'
fi

if [[ ${my_schannel} -eq 1 ]]; then
       (>&2 echo -e -n "\nSSL/CipherSuites:\n") 
       for v in ssl2 ssl3 tls1 tls1_1 tls1_2; do
        for c in $(openssl ciphers 'ALL:eNULL' | tr ':' ' '); do
        openssl s_client -connect ${my_server}:${my_port} \
        -cipher $c -$v < /dev/null > /dev/null 2>&1 && echo -e "$v:\t$c"
        done
       done
fi

