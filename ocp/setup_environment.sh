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
oc process -f bc_puppetmaster_temlate.yaml -p DOCKERREPO=${DOCKERREPO} -p MONOREPO=${MONOREPO} | oc create -f -
# Create DeploymentConfig
oc process -f dc_puppetmaster_env.template -p ENVIRONMENT=${ENVIRONMENT} -p PROJECT=${PROJECT}| oc create -f - -n ${PROJECT}

#Create Service

echo "apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: puppetserver-code-${ENVIRONMENT}
  name: puppetserver-code-${ENVIRONMENT}
spec:
  ports:
  - name: 443-tcp
    port: 443
    protocol: TCP
    targetPort: 8140
  selector:
    deploymentconfig: puppetserver-code-${ENVIRONMENT}
  sessionAffinity: None
  type: ClusterIP
status:
  loadBalancer: {}" | oc create -f - -n ${PROJECT}

#Create Route
echo "apiVersion: route.openshift.io/v1
kind: Route
metadata:
  annotations:
  labels:
    app: puppetserver-code-${ENVIRONMENT}
  name: puppetserver-code-${ENVIRONMENT}
  namespace: ${PROJECT}
spec:
  host: ${ENVIRONMENT}-${CUSTOMER}.openshift-puppetmaster.cegeka.be
  port:
    targetPort: 443-tcp
  tls:
    termination: passthrough
  to:
    kind: Service
    name: puppetserver-code-${ENVIRONMENT}
    weight: 100
  wildcardPolicy: None" | oc create -f - -n ${PROJECT}

echo "Create a DNS records for ${ENVIRONMENT}-${CUSTOMER}.openshift-puppetmaster.cegeka.be"

