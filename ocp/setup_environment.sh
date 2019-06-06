#!/bin/bash

PROJECT=$1
ZONE=$2
DOCKERREPO=$3
MONOREPO=$4
if [ $# -ne 4 ]
then
  echo "4 parameters - > project should be \$1, DNS Zone \$2, docker puppetserver repo \$3, monorepo \$4"
  exit 100
fi

#Prerequisites:
# Files:
# opc/config/foreman.yaml
# ocp/config/thycotic.conf
# ocp/config/secrets.template
#

oc create -f config/templates/secrets.template

oc create configmap foreman.yaml --from-file=foreman.yaml=./config/foreman.yaml -n ${PROJECT}
oc create configmap thycotic.conf --from-file=thycotic.conf=./config/thycotic.conf -n ${PROJECT}
oc create configmap hiera.yaml --from-file=hiera.yaml=./config/hiera.yaml -n ${PROJECT}
cat ./config/templates/thycotic_pvc.yaml | oc create -f -n ${PROJECT}

#Create ImageStreams
oc create is puppetserver -n ${PROJECT}
oc create is puppetserver-code -n ${PROJECT}

oc process -f config/templates/bc_puppetmaster.template -p DOCKERREPO=${DOCKERREPO} -p MONOREPO=${MONOREPO} | oc create -f - -n ${PROJECT}

ENVIRONMENTS='dev acc prd drp'
for environment in $ENVIRONMENTS
do
  oc create configmap puppet-conf-${environment} \
    --from-literal=puppet.conf="`cat config/puppet.conf |sed -e "s/\\${ENVIRONMENT}/${environment}/g"`" -n ${PROJECT}
  oc create configmap fileserver-${environment} \
    --from-literal=fileserver.conf="`cat config/fileserver.conf |sed -e "s/\\${ENVIRONMENT}/${environment}/g"`" -n ${PROJECT}

oc create configmap puppetserver-configuration-${ENVIRONMENT} \
    --from-literal=metrics.conf="`cat config/puppetserver/metrics.conf |sed -e "s/\\${ENVIRONMENT}/${ENVIRONMENT}/g"`" \
    --from-file=web-routes.conf=config/puppetserver/web-routes.conf \
    --from-file=global.conf=config/puppetserver/global.conf \
    --from-file=ca.conf=config/puppetserver/ca.conf \
    --from-file=webserver.conf=config/puppetserver/webserver.conf \
    --from-file=puppetserver.conf=config/puppetserver/puppetserver.conf \
    --from-file=auth.conf=config/puppetserver/auth.conf

  oc create is puppetserver-code-${environment} -n ${PROJECT}

  oc process -f config/templates/puppetmaster.template -p ENVIRONMENT=${environment} -p ZONE=${ZONE} -p PROJECT=${PROJECT} -p DOCKERREPO=${DOCKERREPO} -p MONOREPO=${MONOREPO} | oc create -f - -n ${PROJECT}
  echo "Create a DNS records for ${environment}.${ZONE}"
done
