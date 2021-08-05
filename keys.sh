#!/bin/bash

my_server=""
if [[ $# -eq 1 ]] ; then
    my_server=${1}
fi
if [ "" = "${my_server}" ]; then
  echo -e "\tERROR: Define the server at least.."
  exit 1
fi

cat ~/.ssh/id_rsa.pub | ssh ${my_server} "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && chmod -R go= ~/.ssh && cat >> ~/.ssh/authorized_keys"
