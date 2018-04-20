FROM registry.redhat.io/rhel7:latest
#FROM centos
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN yum -y install puppetserver && yum clean all -y

#RUN chmod -R 777 /opt/puppetlabs

# create and chown directories
#RUN install --directory --owner=puppet --group=puppet --mode=0755 /var/run/puppetlabs/puppetserver && \
#    install --directory --owner=puppet --group=puppet --mode=0777 /srv/puppet/deploy && \
#    chown -R puppet:puppet /etc/puppetlabs/puppet /etc/puppetlabs/code /etc/puppetlabs/puppetserver /srv/puppet


# backup configuration files
#RUN install -d -m 0777 -o puppet -g puppet /usr/share/puppet{,server,code}/backup/etc && \
#    cp -r /etc/puppetlabs/puppet/* /usr/share/puppet/backup/etc && \
#    cp -r /etc/puppetlabs/puppetserver/* /usr/share/puppetserver/backup/etc/ && \
#    cp -r /etc/puppetlabs/code/* /usr/share/puppetcode/backup/etc/ && \
#    chown -R puppet:puppet /usr/share/puppet{,server,code}/backup/etc/

#RUN chmod -R 777 /usr/share/puppet
#RUN chmod -R 777 /etc/puppetlabs
#RUN mkdir -p /etc/puppetlabs/puppet/ssl/public_keys
#RUN mkdir -p /etc/puppetlabs/puppet/ssl/certs
#RUN mkdir -p /etc/puppetlabs/puppet/ssl/certificate_requests
#RUN mkdir -p /etc/puppetlabs/puppet/ssl/private_keys
#RUN chmod -R 771 /etc/puppetlabs/puppet/ssl/public_keys
#RUN chmod -R 750 /var/log/puppetlabs/puppetserver
#RUN chmod -R 750 /etc/puppetlabs/puppetserver/conf.d/
# install puppet start script
ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server
EXPOSE 8140
#ENTRYPOINT ["/usr/local/bin/start-puppet-server"]

