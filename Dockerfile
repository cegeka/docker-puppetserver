FROM registry.redhat.io/rhel7:latest
#FROM centos
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN yum -y install puppetserver && yum clean all -y

ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
ADD conf/ca.cfg /etc/puppetlabs/puppetserver/services.d/ca.cfg
#ADD conf/webserver.conf /etc/puppetlabs/puppetserver/conf.d/webserver.conf

RUN chmod +x /usr/local/bin/start-puppet-server

RUN chgrp -R 0 /opt/puppetlabs/

RUN chgrp -R 0 /etc/puppetlabs
RUN chmod -R 771 /etc/puppetlabs/puppet/ssl

RUN chgrp -R 0 /var/log/puppetlabs
RUN chmod 750 /var/log/puppetlabs/puppetserver
RUN touch /var/log/puppetlabs/puppetserver/masterhttp.log
RUN chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log

EXPOSE 8140
CMD ["/usr/local/bin/start-puppet-server"]

