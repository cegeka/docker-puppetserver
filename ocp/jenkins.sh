#!/bin/bash

PROJECT=$1
GITHUBORG=$2
if [ $# -ne 2 ]
then
  echo "project should be \$1, Gitgub organization \$2"
  exit 100
fi
## Use latest Jenkins container to fix credential-sync-plugin
oc import-image jenkins-2-rhel7 --from=registry.access.redhat.com/openshift3/jenkins-2-rhel7:v3.11.82-4 --confirm

## Customize the the image imported above with all the build tools we need
oc new-build -D $'FROM jenkins-2-rhel7:latest \n
      USER root\nRUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && yum install -y python-setuptools puppet rubygem-puppet-lint && yum clean all && easy_install pip && pip install yamllint\n
      USER 1001' --name=puppet-jenkins

## Define Jenkins customization in config map
oc create configmap jenkins-configuration \
    --from-literal=casc_jenkins.yaml="unclassified:
                   gitHubPluginConfig:
                     configs:
                       - credentialsId: "${PROJECT}-github-api-token"
                         manageHooks: false
                         name: 'Github'" \
    --from-literal=config.groovy="import static jenkins.model.Jenkins.instance as jenkins
import jenkins.model.JenkinsLocationConfiguration

import jenkins.branch.OrganizationFolder
import org.jenkinsci.plugins.github_branch_source.GitHubSCMNavigator
import org.jenkinsci.plugins.github_branch_source.BranchDiscoveryTrait
import org.jenkinsci.plugins.github_branch_source.OriginPullRequestDiscoveryTrait
import org.jenkinsci.plugins.github_branch_source.ForkPullRequestDiscoveryTrait

try {

    def githubOrg = '${GITHUBORG}'

    // Delete Openshift demo-job
    def matchedJobs = jenkins.items.findAll { job ->
      job.name =~ /OpenShift Sample/
    }

    if (!matchedJobs.isEmpty()) {
        println '--> Deleting following jobs:'
        matchedJobs.each { job ->
            println job.name
            job.delete()
        }
    }

    // Configure Github Branch Source plugin
    println '--> Creating organization folder'
    // Create the top-level item if it doesn't exist already.
    def folder = jenkins.items.isEmpty() ? jenkins.createProject(OrganizationFolder, 'Cegeka') : jenkins.items[0]
    // Set up GitHub source.
    def navigator = new GitHubSCMNavigator(githubOrg)
    navigator.credentialsId = '${PROJECT}-github-credentials' // Loaded above in the GitHub section.

    navigator.traits = [
        // Too many repos to scan everything. This trims to a svelte 265 repos at the time of writing.
        new jenkins.scm.impl.trait.WildcardSCMSourceFilterTrait('puppet-monorepo', ''),
        new jenkins.scm.impl.trait.RegexSCMHeadFilterTrait('(^PR-.*)|master'), // we're only interested in PR branches, nothing else
        new BranchDiscoveryTrait(3),
        new ForkPullRequestDiscoveryTrait(2,new ForkPullRequestDiscoveryTrait.TrustContributors()),
        new OriginPullRequestDiscoveryTrait(2) // Take only head
    ]

    folder.navigators.replace(navigator)


    def jenkinsLocationConfiguration = JenkinsLocationConfiguration.get()
    jenkinsLocationConfiguration.setUrl('https://jenkins-${PROJECT}.apps.openshift.cegeka.com')
    jenkinsLocationConfiguration.save()


    println '--> Saving Jenkins config'
    jenkins.save()

    println '--> Scheduling GitHub organization scan'

    Thread.start {
        sleep 30000 // 30 seconds
        println '--> Running GitHub organization scan'
        folder.scheduleBuild()
    }

    println '--> Configuration of jenkins is done'
}
catch(Throwable exc) {
    println '!!! Error configuring jenkins'
    org.codehaus.groovy.runtime.StackTraceUtils.sanitize(new Exception(exc)).printStackTrace()
    println '!!! Shutting down Jenkins to prevent possible mis-configuration from going live'
    jenkins.cleanUp()
    System.exit(1)
}" \
    --from-file=yamllint.conf=../jenkins_configuration/yamllint.conf

## Set of additional plugins to install. Github branch source plugin is installed by default
JENKINS_PLUGINS=`cat config/jenkins.plugins`

## Deploy the Openshift built-in Jenkins template with the newly build image.
oc process openshift//jenkins-ephemeral -p JENKINS_IMAGE_STREAM_TAG=puppet-jenkins:latest NAMESPACE=${PROJECT} | oc create -f -

## Pause rollouts to proceed with additional configuration
oc rollout pause dc jenkins

## Up memory & cpu to get a responsive Jenkins
oc patch dc jenkins -p '{"spec":{"template":{"spec":{"containers":[{"name":"jenkins","resources":{"requests":{"cpu":"1","memory":"1Gi"},"limits":{"cpu":"1","memory":"1Gi"}}}]}}}}'
oc set env dc/jenkins MEMORY_LIMIT=1Gi

oc set env dc/jenkins DISABLE_ADMINISTRATIVE_MONITORS=true
oc set env dc/jenkins INSTALL_PLUGINS="${JENKINS_PLUGINS}"
oc set env dc/jenkins CASC_JENKINS_CONFIG="/var/lib/jenkins/init.groovy.d/casc_jenkins.yaml"
oc set volumes dc/jenkins --add --configmap-name=jenkins-configuration --mount-path='/var/lib/jenkins/init.groovy.d/' --name "jenkins-config"
oc set volumes dc/jenkins --add --configmap-name=jenkins-configuration --mount-path='/var/lib/jenkins/.config/yamllint' --name "yamllint-config"
oc patch dc jenkins -p '{"spec":{"template":{"spec":{"volumes":[{"configMap":{"items":[{"key":"yamllint.conf","path":"config"}],"name":"jenkins-configuration"},"name":"yamllint-config"}]}}}}'

oc rollout resume dc jenkins
oc expose svc/jenkins
