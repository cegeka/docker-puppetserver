#!/bin/bash

set -e

LOG_APPENDER="-Dlogappender=STDOUT"

source /etc/sysconfig/puppetserver

/usr/bin/java ${JAVA_ARGS} ${LOG_APPENDER} \
         -cp ${INSTALL_DIR}/puppet-server-release.jar:${INSTALL_DIR}/jruby-9k.jar:/opt/puppetlabs/puppet/lib/ruby/vendor_ruby/facter.jar:${INSTALL_DIR}/jars/* \
         clojure.main -m puppetlabs.trapperkeeper.main \
         --config ${CONFIG} --bootstrap-config ${BOOTSTRAP_CONFIG} \
         ${@}
