# Puppetserver docker file
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
LABEL maintainer="Thomas Meeus <thomas.meeus@cegeka.com>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building Puppet Server images" \
      io.k8s.display-name="Openshift-puppetserver-image-builder" \
      io.openshift.expose-services="8140:https" \
      io.openshift.tags="openshift,docker,puppet,puppetserver,image,builder"

## Add the s2i scripts.
LABEL io.openshift.s2i.scripts-url=image:///usr/libexec/s2i
COPY ./s2i/bin/ /usr/libexec/s2i

## Install Puppetserver & create Puppet code directory

RUN rpm -i https://yum.puppet.com/puppet7/el/8/x86_64/puppet7-release-7.0.0-2.el8.noarch.rpm \
    && sed -i 's/http:/https:/g' /etc/yum.repos.d/* \
    && microdnf -y update \
    && microdnf -y install vim openssl wget nmap puppetserver puppetdb-termini\
    && microdnf clean all -y \
    && mkdir -p /etc/puppetlabs/code \
    && mkdir -p /tmp/puppet-scripts \
    && mkdir -p /tmp/ca-certs \
    && mkdir -p /etc/puppetlabs/ssl/ca \
    && mkdir -p /etc/puppetlabs/code/environments/production/manifests \
    && mkdir -p /var/log/puppetlabs/puppetserver/ \
    && touch /var/log/puppetlabs/puppetserver/masterhttp.log

## Copy all required config files
COPY ./s2i/config/puppetserver.sh /usr/local/bin/start-puppet-server
COPY ./s2i/config/foreman.rb /opt/puppetlabs/puppet/lib/ruby/vendor_ruby/puppet/reports/foreman.rb
COPY ./s2i/config/external_node_v2.rb /usr/local/bin/external_node_v2.rb
COPY ./s2i/config/cloud_registration.rb /usr/local/bin/cloud_registration.rb
COPY ./s2i/config/sysconfig/puppetserver /etc/sysconfig/puppetserver

## Set correct permissions
RUN chmod +x /usr/local/bin/start-puppet-server \
    && chgrp -R 0 /opt/puppetlabs \
    && chgrp -R 0 /etc/puppetlabs \
    && chmod -R 771 /etc/puppetlabs/puppet/ssl \
    && chmod -R 775 /etc/puppetlabs/code \
    && chgrp -R 0 /var/log/puppetlabs \
    && chmod 750 /var/log/puppetlabs/puppetserver \
    && chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log \
    && mkdir /opt/puppetlabs/server/data/puppetserver/yaml \
    && chmod 750 /opt/puppetlabs/server/data/puppetserver/yaml \
    && mkdir /opt/puppetlabs/puppet/cache/facts.d \
    && mkdir /tmp/thycotic \
    && chmod 0775 /etc/puppetlabs/ssl/ca \
    && chmod -R 0771 /etc/puppetlabs/ssl \
    && chmod 755 /usr/local/bin/cloud_registration.rb

## Install dependencies for puppet-thycotic module
RUN /opt/puppetlabs/server/bin/puppetserver gem install --no-document soap4r-ng \
    && /opt/puppetlabs/server/bin/puppetserver gem install --no-document parseconfig \
    && /opt/puppetlabs/server/bin/puppetserver gem install --no-document filecache \
    && /opt/puppetlabs/server/bin/puppetserver gem install --no-document msgpack \
    && /opt/puppetlabs/server/bin/puppetserver gem install --no-document CFPropertyList \
    && /opt/puppetlabs/server/bin/puppetserver gem install --no-document httpclient \
    && /opt/puppetlabs/server/bin/puppetserver gem install --no-document minitest:5.12.0 \
    && /opt/puppetlabs/server/bin/puppetserver gem install --no-document activerecord-jdbcmysql-adapter:1.3.25 \
    && rm /etc/puppetlabs/puppetserver/conf.d/* \
    && chmod og+w /etc/puppetlabs/puppetserver/conf.d

## Copy over /etc/puppetlabs/code/ for the next builds
#ONBUILD COPY /tmp/src/ /etc/puppetlabs/code/

## Make /etc/passwd writable for root to be able to adjust the puppet userid. Required for Thycotic module
RUN chmod g+w /etc/passwd
    && chmod g+w /etc/group

USER 1001

EXPOSE 8140

CMD ["/usr/libexec/s2i/usage"]
