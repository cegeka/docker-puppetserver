#!/bin/bash

PROJECT=$1
GITHUBORG=$2
if [ $# -ne 2 ]
then
  echo "project should be \$1, Gitgub organization \$2"
  exit 100
fi
## Use latest Jenkins container to fix credential-sync-plugin
# oc import-image jenkins-2-rhel7 --from=registry.access.redhat.com/openshift3/jenkins-2-rhel7:v3.11.346-2 --confirm

## Customize the the image imported above with all the build tools we need
oc new-build -n ${PROJECT} -D $'FROM registry.access.redhat.com/openshift3/jenkins-2-rhel7:latest\n
      USER root\n
      RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet \
        && yum-config-manager --enable rhel-server-rhscl-7-rpms \
        && yum -y install https://yum.puppet.com/puppet7/el/7/x86_64/puppet7-release-7.0.0-1.el7.noarch.rpm \
        && yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
        && yum -y install puppet-agent gcc zlib-devel gcc-c++ rh-ruby25-ruby-devel rh-git29 python36-pip \
        && yum clean all \
        && pip3 install yamllint \
        && gem install --source "https://rubygems.org" --no-ri --no-rdoc bundler:2.0.1 json puppet-lint
      USER jenkins\n
      WORKDIR /var/lib/jenkins' --name=puppet-jenkins -e=PATH=\$PATH:/opt/rh/rh-ruby25/root/usr/bin -e=LD_LIBRARY_PATH=/opt/rh/rh-ruby25/root/usr/lib64

## Define Jenkins customization in config map
oc create -n ${PROJECT} configmap jenkins-configuration \
    --from-literal=casc_jenkins.yaml="`cat config/jenkins_configuration/casc_jenkins.yaml |sed -e "s/\\${PROJECT}/${PROJECT}/g"`" \
    --from-literal=config.groovy="`cat config/jenkins_configuration/config.groovy |sed -e "s/\\${PROJECT}/${PROJECT}/g" -e "s/\\${GITHUBORG}/${GITHUBORG}/g"`" \
    --from-file=yamllint.conf=config/jenkins_configuration/yamllint.conf

## Set of additional plugins to install. Github branch source plugin is installed by default
JENKINS_PLUGINS=`cat config/jenkins_configuration/jenkins.plugins`

## Deploy the Openshift built-in Jenkins template with the newly build image.
oc process openshift//jenkins-persistent -p JENKINS_IMAGE_STREAM_TAG=puppet-jenkins:latest NAMESPACE=${PROJECT} -p VOLUME_CAPACITY=10Gi | oc create -f -

## Pause rollouts to proceed with additional configuration
oc rollout -n ${PROJECT} pause dc jenkins

## Up memory & cpu to get a responsive Jenkins
oc patch -n ${PROJECT}  dc jenkins -p '{"spec":{"template":{"spec":{"containers":[{"name":"jenkins","resources":{"requests":{"cpu":"1","memory":"1Gi"},"limits":{"cpu":"2","memory":"4Gi"}}}]}}}}'
oc set env dc/jenkins MEMORY_LIMIT=2Gi

oc set env -n ${PROJECT} dc/jenkins DISABLE_ADMINISTRATIVE_MONITORS=true
oc set env -n ${PROJECT} dc/jenkins INSTALL_PLUGINS="${JENKINS_PLUGINS}"
oc set env -n ${PROJECT} dc/jenkins CASC_JENKINS_CONFIG="/var/lib/jenkins/init.groovy.d/casc_jenkins.yaml"
oc set env -n ${PROJECT} dc/jenkins PATH="/opt/rh/rh-git29/root/usr/bin:/opt/rh/rh-ruby25/root/usr/local/bin:/opt/rh/rh-ruby25/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
oc set env -n ${PROJECT} dc/jenkins LD_LIBRARY_PATH="/opt/rh/rh-ruby25/root/usr/lib64:/opt/rh/httpd24/root/usr/lib64"

oc set volumes -n ${PROJECT} dc/jenkins --add --configmap-name=jenkins-configuration --mount-path='/var/lib/jenkins/init.groovy.d/' --name "jenkins-config"
oc set volumes -n ${PROJECT} dc/jenkins --add --configmap-name=jenkins-configuration --mount-path='/var/lib/jenkins/.config/yamllint' --name "yamllint-config"

oc patch dc -n ${PROJECT} jenkins -p '{"spec":{"template":{"spec":{"volumes":[{"configMap":{"items":[{"key":"yamllint.conf","path":"config"}],"name":"jenkins-configuration"},"name":"yamllint-config"}]}}}}'
oc patch dc -n ${PROJECT} jenkins -p '{"spec":{"revisionHistoryLimit": 2}}'

oc rollout -n ${PROJECT} resume dc jenkins
