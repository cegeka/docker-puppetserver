FROM registry.redhat.io/rhel7:latest
#FROM centos
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN groupadd -g 998 puppet && \
    useradd -r -u 999 -g puppet puppet
RUN yum -y install puppetserver && yum clean all -y


ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chown puppet:puppet /usr/local/bin/start-puppet-server
RUN chmod +x /usr/local/bin/start-puppet-server

RUN chgrp -R 0 /etc/puppetlabs/puppetserver/
RUN chmod -R 775 /etc/puppetlabs/puppetserver/

RUN chrgrp -R 0 /var/log/puppetlabs/puppetserver
RUN chmod -R 775 /var/log/puppetlabs/puppetserver


RUN chrgrp -R 0 /opt/puppetlabs/
RUN chmod -R 775 /opt/puppetlabs/
EXPOSE 8140
# switch user only at this point
USER 998
CMD ["/usr/local/bin/start-puppet-server"]
#ENTRYPOINT ["/sbin/init"]

