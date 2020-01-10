# Helm

## deploy

```
helm install ./docker-puppetserver --generate-name --values=docker-puppetserver/secrets.yaml
```

This will deploy all resources with a given suffix (timestamp)


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

