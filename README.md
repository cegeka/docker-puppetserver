# Puppetserver on Openshift

## Goal

Having a Puppetserver running as a container on Openshift. Using autoscaling the Puppetserver can dynamically adapt to differences in load.

Todo: create a build-pipeline with promotion towards different environments.

## Usage

* Copy ocp/secrets.template to ocp/secrets.yaml and configure your certificates & deploy key in the base64 format. The certificates are used to configure the Puppetserver CA. The public key of the deploy key should be added to the git-repo containing all the puppet code.

* Deploy the secrets

```
oc create -f ocp/config/secrets.template
```

* Setup environments

```
cd ocp; ./setup_environment.sh $PROJECT $ENVIRONMENT $CUSTOMER $DOCKERREPO $MONOREPO $METRICSSERVER
```

* Setup Jenkins

```
cd ocp; ./jenkins.sh $PROJECT
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
