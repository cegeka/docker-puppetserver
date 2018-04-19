FROM registry.redhat.io/rhel7:latest
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN groupadd -g 8140 -r puppet && \
    useradd -u 8140 -g 8140 -r -s /usr/sbin/nologin puppet
RUN yum -y install puppetserver && yum clean all -y
RUN chmod -R 777 /opt/puppetlabs
# install puppet start script
ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server
EXPOSE 8140
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]

