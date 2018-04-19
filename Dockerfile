FROM registry.redhat.io/rhel7:latest
RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN yum -y install puppetserver && yum clean all -y
CMD /opt/puppetlabs/bin/puppetserver foreground
