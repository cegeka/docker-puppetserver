FROM registry.redhat.io/rhel7:latest
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN groupadd -g 8140 -r puppet && \
    useradd -u 8140 -g 8140 -r -s /usr/sbin/nologin puppet
RUN yum -y install puppetserver && yum clean all -y
RUN chmod -R 777 /opt/puppetlabs

# create and chown directories
RUN install --directory --owner=puppet --group=puppet --mode=0775 /var/run/puppetlabs/puppetserver && \
    install --directory --owner=puppet --group=puppet --mode=0770 /srv/puppet/deploy && \
    chown -R puppet:puppet /etc/puppetlabs/puppet /etc/puppetlabs/code /etc/puppetlabs/puppetserver /srv/puppet


# backup configuration files
RUN install -d -m 0755 -o puppet -g puppet /usr/share/puppet{,server,code}/backup/etc && \
    cp -r /etc/puppetlabs/puppet/* /usr/share/puppet/backup/etc && \
    cp -r /etc/puppetlabs/puppetserver/* /usr/share/puppetserver/backup/etc/ && \
    cp -r /etc/puppetlabs/code/* /usr/share/puppetcode/backup/etc/ && \
    chown -R puppet:puppet /usr/share/puppet{,server,code}/backup/etc/

# install puppet start script
ADD scripts/puppetserver.sh /usr/local/bin/start-puppet-server
RUN chmod 0775 /usr/local/bin/start-puppet-server
EXPOSE 8140
ENTRYPOINT ["/usr/local/bin/start-puppet-server"]

