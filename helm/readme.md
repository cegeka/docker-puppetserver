# Helm



## secrets
Copy secrets.yaml.template to secrets.yaml & fill in all values.

## Config

Modify values.yaml and specify which puppetserver environments you want to deploy. If 'cloud' is specified, an autosigning puppetserver will be deployed.

## deploy
```
oc login
oc project $yourproject
helm install ./docker-puppetserver --generate-name --values=docker-puppetserver/secrets.yaml
```

## List current deployments
```
helm ls
```

## Upgrade deployment
```
helm upgrade docker-puppetserver-1578649813 ./docker-puppetserver --values=docker-puppetserver/secrets.yaml
```

## clean up old deployment
```
helm uninstall docker-puppetserver-1578650001
```

