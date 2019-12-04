#!/bin/bash

set -e

LOG_APPENDER="-Dlogappender=STDOUT"

source /etc/sysconfig/puppetserver

/usr/bin/java ${JAVA_ARGS} \
  -XX:OnOutOfMemoryError="kill -9 %p" \
  -cp ${INSTALL_DIR}/puppet-server-release.jar \
  clojure.main \
  -m puppetlabs.trapperkeeper.main \
  --config "${CONFIG}" \
  --bootstrap-config "${BOOTSTRAP_CONFIG}"  \
  ${@}
