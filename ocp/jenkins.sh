#!/bin/bash


oc new-build  -D $'FROM jenkins:latest\n
      USER root\nRUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && yum install -y python-setuptools puppet rubygem-puppet-lint && yum clean all && easy_install pip && pip install yamllint\n
      USER 1001' --name=puppet-jenkins


## to fix:
JENKINS_PLUGINS="GitHub+Branch+Source+Plugin:2.4.1"

oc new-app jenkins -p MEMORY_LIMIT=1Gi ENABLE_OAUTH=true DISABLE_ADMINISTRATIVE_MONITORS=true INSTALL_PLUGINS="${JENKINS_PLUGINS}"
oc patch dc jenkins -p '{"spec": {"template": {"spec": {"containers": [{"name": "jenkins","resources": {"requests": {"cpu": "1", "memory": "1Gi"}, "limits": {"cpu": "1", "memory": "1Gi}}}]}}}}'
oc expose svc/jenkins




