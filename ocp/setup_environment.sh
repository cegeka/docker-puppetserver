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
oc create configmap puppet-ca --from-file=ca.cfg=./config/ca.cfg -n ${PROJECT}
oc create configmap thycotic.conf --from-file=thycotic.conf=./config/thycotic.conf -n ${PROJECT}
oc create configmap hiera.yaml --from-file=hiera.yaml=./config/hiera.yaml -n ${PROJECT}
cat ./config/templates/thycotic_pvc.yaml | oc create -f -n ${PROJECT}
cat ./config/templates/puppetmaster_facts_pvc.yaml | oc create -f -n ${PROJECT}

#Create ImageStreams
oc create is puppetserver -n ${PROJECT}
oc create is puppetserver-code -n ${PROJECT}

oc process -f config/templates/bc_puppetmaster.template -p DOCKERREPO=${DOCKERREPO} -p MONOREPO=${MONOREPO} | oc create -f - -n ${PROJECT}

ENVIRONMENTS='dev acc prd drp cloud'
for environment in $ENVIRONMENTS
do
  oc create is puppetserver-code-${environment} -n ${PROJECT}

  oc create configmap fileserver-${environment} \
    --from-literal=fileserver.conf="`cat config/fileserver.conf |sed -e "s/\\${ENVIRONMENT}/${environment}/g"`" -n ${PROJECT}

  if ${environment} != 'cloud'
  then

    PUPPET_CONF="config/puppet.conf"
    PUPPETSERVER_TEMPLATE="config/templates/puppetmaster.template"

  else
    PUPPET_CONF="config/puppet-${environment}.conf"
    PUPPETSERVER_TEMPLATE="config/templates/puppetmaster-${environment}.template"

      oc create configmap hiera-${environment}.yaml --from-file=hiera.yaml=./config/hiera-${environment}.yaml -n ${PROJECT}

      oc create configmap puppet-ca-${environment} --from-file=ca.cfg=./config/ca-${environment}.cfg -n ${PROJECT}
      #first set up CA certificates in config/templates/cloud-ca-pem.template
      oc create -f config/templates/${environment}-ca-pem.template -n ${PROJECT}

  fi

  oc create configmap puppetserver-configuration-${environment} \
      --from-literal=metrics.conf="`cat config/puppetserver/metrics.conf |sed -e "s/\\${ENVIRONMENT}/${environment}/g"`" \
      --from-file=web-routes.conf=config/puppetserver/web-routes.conf \
      --from-file=global.conf=config/puppetserver/global.conf \
      --from-file=ca.conf=config/puppetserver/ca.conf \
      --from-file=webserver.conf=config/puppetserver/webserver.conf \
      --from-file=puppetserver.conf=config/puppetserver/puppetserver.conf \
      --from-file=auth.conf=config/puppetserver/auth.conf \
      --from-file=logback.xml=config/puppetserver/logback.xml
      --from-file=registration_credentials.yaml=config/registration_credentials.yaml

  oc create configmap puppet-conf-${environment} \
    --from-literal=puppet.conf="`cat ${PUPPET_CONF} |sed -e "s/\\${ENVIRONMENT}/${environment}/g"`" -n ${PROJECT}

  oc process -f $PUPPETSERVER_TEMPLATE -p ENVIRONMENT=${environment} -p ZONE=${ZONE} -p PROJECT=${PROJECT} | oc create -f - -n ${PROJECT}

  echo "Create a DNS records for ${environment}.${ZONE}"
done

#Build cronjob container
oc new-build -D $'FROM rhel7:latest\n
      USER root\n
      RUN yum-config-manager --enable rhel-server-rhscl-7-rpms \
        && yum -y install rh-ruby25 \
        && yum clean all && mkdir -p /opt/puppetlabs/server/data/puppetserver/yaml/ && mkdir /etc/puppet && gem install facter &&  yum -y install hostname' \
 --name=puppet-facts -e=PATH=\$PATH:/opt/rh/rh-ruby25/root/usr/bin -e=LD_LIBRARY_PATH=/opt/rh/rh-ruby25/root/usr/lib64 --to docker-registry.default.svc:5000/ci00053160-puppetserver/rhel7:latest -n ${PROJECT}

#Create cronjob to push facts
oc create -f config/templates/batch.template -n ${PROJECT}
