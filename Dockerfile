FROM registry.redhat.io/rhel7:latest
#FROM centos
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN yum -y install puppetserver && yum clean all -y


ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
#RUN chgrp 0 /usr/local/bin/start-puppet-server
RUN chmod +x /usr/local/bin/start-puppet-server
#
#RUN chgrp -R 0 /etc/puppetlabs/puppetserver/
#RUN chmod -R 775 /etc/puppetlabs/puppetserver/
#
#RUN touch /var/log/puppetlabs/puppetserver/masterhttp.log
#RUN chgrp -R 0 /var/log/puppetlabs/puppetserver
#RUN chmod -R 750 /var/log/puppetlabs/puppetserver
#
#RUN chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log
#RUN chgrp 0 /var/log/puppetlabs/puppetserver/masterhttp.log
#
#RUN chgrp -R 0 /opt/puppetlabs/
#RUN chmod -R 775 /opt/puppetlabs/
#
#RUN chgrp -R 0 /etc/puppetlabs/puppet/ssl
#RUN chmod -R 771 /etc/puppetlabs/puppet/ssl

EXPOSE 8140
CMD ["/usr/local/bin/start-puppet-server"]

