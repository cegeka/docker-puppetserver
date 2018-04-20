FROM registry.redhat.io/rhel7:latest
#FROM centos
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN yum -y install puppetserver && yum clean all -y

RUN groupadd -g 999 puppet && \
    useradd -r -u 999 -g puppet puppet
USER puppet

ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server
EXPOSE 8140
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]

