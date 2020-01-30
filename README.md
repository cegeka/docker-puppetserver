# Puppetserver on Openshift

## Goal

Having a Puppetserver running as a container on Openshift. Using autoscaling the Puppetserver can dynamically adapt to differences in load.

Todo: create a build-pipeline with promotion towards different environments.

## Usage

See the helm-chart in docker-puppetserver/helm.

## Contents

The following modules will be configured within your Openshift project:

* Imagestreams for:
    - The RHEL8 base image
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
