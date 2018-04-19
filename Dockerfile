FROM registry.redhat.io/rhel7:latest
ENV PUPPET_SERVER_VERSION="5.3.0" DUMB_INIT_VERSION="1.2.1" PUPPETSERVER_JAVA_ARGS="-Xms256m -Xmx256m" PATH=/opt/puppetlabs/server/bin:/opt/puppetlabs/puppet/bin:/opt/puppetlabs/bin:$PATH PUPPET_HEALTHCHECK_ENVIRONMENT="production"

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN yum -y install puppetserver wget && \
  yum clean all -y
RUN wget -O /usr/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_amd64
RUN chmod +x /usr/bin/dumb-init

#RUN apt-get update && \
#    apt-get install -y wget=1.17.1-1ubuntu1 && \
#    wget https://apt.puppetlabs.com/puppet5-release-"$UBUNTU_CODENAME".deb && \
#    wget https://github.com/Yelp/dumb-init/releases/download/v"$DUMB_INIT_VERSION"/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
#    dpkg -i puppet5-release-"$UBUNTU_CODENAME".deb && \
#    dpkg -i dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
#    rm puppet5-release-"$UBUNTU_CODENAME".deb dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
#    apt-get update && \
#    apt-get install --no-install-recommends git -y puppetserver="$PUPPET_SERVER_VERSION"-1"$UBUNTU_CODENAME" && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* && \
#    gem install --no-rdoc --no-ri r10k

#COPY puppetserver /etc/default/puppetserver
#COPY logback.xml /etc/puppetlabs/puppetserver/
#COPY request-logging.xml /etc/puppetlabs/puppetserver/

#RUN puppet config set autosign true --section master

COPY docker-entrypoint.sh /

EXPOSE 8140

ENTRYPOINT ["dumb-init", "/docker-entrypoint.sh"]
CMD ["foreground" ]

HEALTHCHECK --interval=10s --timeout=10s --retries=90 CMD \
  curl --fail -H 'Accept: pson' \
  --resolve 'puppet:8140:127.0.0.1' \
  --cert   $(puppet config print hostcert) \
  --key    $(puppet config print hostprivkey) \
  --cacert $(puppet config print localcacert) \
  https://puppet:8140/${PUPPET_HEALTHCHECK_ENVIRONMENT}/status/test \
  |  grep -q '"is_alive":true' \
  || exit 1

COPY Dockerfile /

