# Puppetserver on Openshift

## Goal

Having a Puppetserver running as a container on Openshift. Using autoscaling the Puppetserver can dynamically adapt to differences in load.

Todo: create a build-pipeline with promotion towards different environments.

## Usage

* Copy `ocp/config/templates/secrets.template` to `ocp/config/secrets.yaml` and configure your certificates & deploy key in the base64 format. The certificates are used to configure the Puppetserver CA. The public key of the deploy key should be added to the git-repo containing all the puppet code.
* Configure foreman configuration: `opc/config/foreman.yaml`
* Configure PIM configuration: `ocp/config/thycotic.conf`

* Deploy the secrets
```
oc create -f ocp/config/secrets.yaml
```

* Setup environments
** PROJECT = The OpenShift project to create the puppetserver deployment
** ZONE = The DNS ZONE that will host your puppetserver. Used to create Routes (<environment>.openshift-puppetmaster.domain.tld)
** DOCKERREPO = The GitHub repository hosting this code (https://github.com/<organisation>/docker-puppetserver.git)
** MONOREPO = The GitHub repository hosting your puppet code (git@github.com:<organisation>/puppet-monorepo.git)
** METRICSSERVER = The Grapite server to send puppetserver metrics to

```
cd ocp
./setup_environment.sh $PROJECT $ZONE $DOCKERREPO $MONOREPO $METRICSSERVER
```

* Setup Jenkins

```
cd ocp
./jenkins.sh $PROJECT
```

## Contents

The following modules will be configured within your Openshift project:

* Imagestreams for:
    - The RHEL7 base image
    - The puppetserver base image
    - All subsequent puppetserver images containing puppet code

* Buildconfig for:
    - Building the puppetserver image
    - S2I build from the repository containing your puppet code

* DeploymentConfig for:
    - Deploying the puppet server image
    - Healthchecks to see if the puppetserver is up & running

* Service for:
    - Portforwarding the public port 443 towards 8140 in the container

* Route for:
    - Exposing the service to the internet with a custom hostname

## Tips

Deployment pipelines can be created in openshift itself, see this video for more information on how to do this:
[![Using OpenShift Pipelines with Webhook Triggers](http://img.youtube.com/vi/kY6227QxqOA/0.jpg)](http://www.youtube.com/watch?v=kY6227QxqOA)
