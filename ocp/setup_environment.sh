#!/bin/bash

PROJECT=$1
ENVIRONMENT=$2
CUSTOMER=$3
DOCKERREPO=$4
MONOREPO=$5
if [ $# -ne 5 ]
then
  echo "5 parameters - > project should be \$1, environment \$2, customer \$3, docker puppetserver repo \$4, monorepo \$5"
  exit 100
fi

#Prerequisites:
# Files:
# opc/config/foreman.yaml
# ocp/config/thycotic.conf
# ocp/config/secrets.template
#

oc create configmap puppetserver-configuration --from-file=puppet.conf=./config/puppet.conf --from-file=foreman.yaml=./config/foreman.yaml --from-file=thycotic.conf=./config/thycotic.conf -n ${PROJECT}

#Create ImageStreams
oc create is puppetserver -n ${PROJECT}
oc create is puppetserver-code -n ${PROJECT}

oc create is puppetserver-code-${ENVIRONMENT} -n ${PROJECT}

#Create Build Configs
oc process -f config/bc_puppetmaster.template -p DOCKERREPO=${DOCKERREPO} -p MONOREPO=${MONOREPO} | oc create -f -
# Create DeploymentConfig
oc process -f config/dc_puppetmaster_env.template -p ENVIRONMENT=${ENVIRONMENT} -p PROJECT=${PROJECT}| oc create -f - -n ${PROJECT}

#Create Service
oc process -f config/service.template -p ENVIRONMENT=${ENVIRONMENT} | oc create -f - -n ${PROJECT}

#Create Route
oc process -f config/route.template -p ENVIRONMENT=${ENVIRONMENT} -p CUSTOMER=${CUSTOMER} | oc create -f - -n ${PROJECT}

echo "Create a DNS records for ${ENVIRONMENT}-${CUSTOMER}.openshift-puppetmaster.cegeka.be"

