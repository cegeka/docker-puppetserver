#!/bin/bash

set -e

# default variables
JAVA_ARGS="${JAVA_ARGS:--Xms2g -Xmx2g}"

# copied from SystemD unit provided by puppet server
exec /usr/bin/java -Xms512m -Xmx1g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger -Djava.security.egd=/dev/urandom -XX:OnOutOfMemoryError=kill -9 %%p -cp /opt/puppetlabs/server/apps/puppetserver/puppet-server-release.jar:/opt/puppetlabs/server/apps/puppetserver/jruby-1_7.jar:/opt/puppetlabs/server/data/puppetserver/jars/* clojure.main -m puppetlabs.trapperkeeper.main --config /etc/puppetlabs/puppetserver/conf.d --bootstrap-config /etc/puppetlabs/puppetserver/services.d/,/opt/puppetlabs/server/apps/puppetserver/config/services.d/ --restart-file /opt/puppetlabs/server/data/puppetserver/restartcounter
