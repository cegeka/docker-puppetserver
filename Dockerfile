FROM registry.redhat.io/rhel7:latest
#FROM centos
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN groupadd -g 998 puppet && \
    useradd -r -u 999 -g puppet puppet
RUN yum -y install puppetserver && yum clean all -y


ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chown puppet:puppet /usr/local/bin/start-puppet-server
EXPOSE 8140
# switch user only at this point
USER puppet
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]

