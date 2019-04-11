#!/bin/bash

PROJECT=$1
CUSTOMER=$2
DOCKERREPO=$3
MONOREPO=$4
if [ $# -ne 4 ]
then
  echo "4 parameters - > project should be \$1, customer \$2, docker puppetserver repo \$3, monorepo \$4"
  exit 100
fi

#Prerequisites:
# Files:
# opc/config/foreman.yaml
# ocp/config/thycotic.conf
# ocp/config/secrets.template
#

oc create -f config/templates/secrets.template

oc create configmap puppetserver-configuration --from-file=puppet.conf=./config/puppet.conf --from-file=foreman.yaml=./config/foreman.yaml --from-file=thycotic.conf=./config/thycotic.conf -n ${PROJECT}

#Create ImageStreams
oc create is puppetserver -n ${PROJECT}
oc create is puppetserver-code -n ${PROJECT}

ENVIRONMENTS='dev acc prd drp'
for environment in $ENVIRONMENTS
do
  oc create is puppetserver-code-${environment} -n ${PROJECT}

  oc process -f config/templates/puppetmaster.template -p ENVIRONMENT=${environment} -p CUSTOMER=${CUSTOMER} -p PROJECT=${PROJECT} -p DOCKERREPO=${DOCKERREPO} -p MONOREPO=${MONOREPO} | oc create -f - -n ${PROJECT}
  echo "Create a DNS records for ${environment}-${CUSTOMER}.openshift-puppetmaster.cegeka.be"
done
