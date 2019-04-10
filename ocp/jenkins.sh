#!/bin/bash

PROJECT=$1
if [ $# -ne 1 ]
then
  echo "Only one parameter - > project should be \$1"
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

    def githubOrg = 'cegeka'

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
JENKINS_PLUGINS="ace-editor:1.1,apache-httpcomponents-client-4-api:4.5.5-3.0,authentication-tokens:1.3,blueocean-autofavorite:1.2.3,blueocean-bitbucket-pipeline:1.13.1,blueocean-commons:1.13.1,blueocean-config:1.13.1,blueocean-core-js:1.13.1,blueocean-dashboard:1.13.1,blueocean-display-url:2.2.0,blueocean-events:1.13.1,blueocean-github-pipeline:1.13.1,blueocean-git-pipeline:1.13.1,blueocean:1.13.1,blueocean-i18n:1.13.1,blueocean-jira:1.13.1,blueocean-jwt:1.13.1,blueocean-personalization:1.13.1,blueocean-pipeline-api-impl:1.13.1,blueocean-pipeline-editor:1.13.1,blueocean-pipeline-scm-api:1.13.1,blueocean-rest:1.13.1,blueocean-rest-impl:1.13.1,blueocean-web:1.13.1,branch-api:2.1.2,cloudbees-bitbucket-branch-source:2.4.2,cloudbees-folder:6.7,conditional-buildstep:1.3.6,config-file-provider:3.5,credentials-binding:1.18,credentials:2.1.18,display-url-api:2.3.0,docker-commons:1.13,docker-workflow:1.17,durable-task:1.29,favorite:2.3.2,git-client:2.7.6,git:3.9.3,github-api:1.95,github-branch-source:2.4.2,github:1.29.4,github-organization-folder:1.6,git-server:1.7,handlebars:1.1.1,handy-uri-templates-2-api:2.1.7-1.0,htmlpublisher:1.18,jackson2-api:2.9.8,jenkins-design-language:1.13.1,jira:3.0.5,job-dsl:1.71,jquery-detached:1.2.1,jsch:0.1.55,kubernetes:1.14.8,lockable-resources:2.4,mailer:1.23,mapdb-api:1.0.9.0,matrix-auth:2.3,matrix-project:1.13,mercurial:2.5,momentjs:1.1.1,openshift-client:1.0.27,openshift-login:1.0.16,openshift-pipeline:1.0.55,openshift-sync:1.0.31,parameterized-trigger:2.35.2,pipeline-build-step:2.7,pipeline-github-lib:1.0,pipeline-graph-analysis:1.9,pipeline-input-step:2.9,pipeline-milestone-step:1.3.1,pipeline-model-api:1.3.5,pipeline-model-declarative-agent:1.1.1,pipeline-model-definition:1.3.5,pipeline-model-extensions:1.3.5,pipeline-rest-api:2.10,pipeline-stage-step:2.3,pipeline-stage-tags-metadata:1.3.5,pipeline-stage-view:2.10,pipeline-utility-steps:2.2.0,plain-credentials:1.5,pubsub-light:1.12,run-condition:1.2,scm-api:2.3.0,script-security:1.53,sse-gateway:1.17,ssh-credentials:1.14,structs:1.17,subversion:2.12.1,token-macro:2.6,variant:1.2,workflow-aggregator:2.6,workflow-api:2.33,workflow-basic-steps:2.14,workflow-cps-global-lib:2.13,workflow-cps:2.63,workflow-durable-task-step:2.29,workflow-job:2.31,workflow-multibranch:2.20,workflow-remote-loader:1.4,workflow-scm-step:2.7,workflow-step-api:2.19,workflow-support:3.2,configuration-as-code:1.7,kubernetes-credentials:0.4.0,pipeline-github:2.5,jdk-tool:1.2,command-launcher:1.3,bouncycastle-api:2.17,junit:1.27,javadoc:1.4,maven-plugin:3.2"

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
