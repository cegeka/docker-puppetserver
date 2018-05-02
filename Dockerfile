# puppetserver
FROM registry.redhat.io/rhel7:latest
FROM registry.access.redhat.com/rhscl/s2i-base-rhel7:latest

# TODO: Put the maintainer name in the image metadata
LABEL maintainer="Thomas Meeus <thomas.meeus@cegeka.com>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Platform for building Puppet Server images" \
#      io.k8s.display-name="builder x.y.z" \
      io.openshift.expose-services="8140:https"
#      io.openshift.tags="builder,x.y.z,etc."


# Add the s2i scripts.
LABEL io.openshift.s2i.scripts-url=image:///usr/libexec/s2i
COPY ./s2i/bin/ /usr/libexec/s2i

RUN rpm --import https://yum.puppetlabs.com/RPM-GPG-KEY-puppet
RUN yum-config-manager --add-repo https://yum.puppetlabs.com/el/7/PC1/x86_64/
RUN yum -y install puppetserver && yum clean all -y


# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

COPY ./s2i/scripts/puppetserver.sh /usr/local/bin/start-puppet-server
COPY ./s2i/scripts/ca.cfg /etc/puppetlabs/puppetserver/services.d/ca.cfg
COPY ./s2i/scripts/webserver.conf /etc/puppetlabs/puppetserver/conf.d/webserver.conf


RUN chmod +x /usr/local/bin/start-puppet-server

RUN chgrp -R 0 /opt/puppetlabs/


RUN chgrp -R 0 /etc/puppetlabs
RUN chmod -R 771 /etc/puppetlabs/puppet/ssl
RUN mkdir -p /etc/puppetlabs/code
RUN chmod -R 775 /etc/puppetlabs/code

RUN chgrp -R 0 /var/log/puppetlabs
RUN chmod 750 /var/log/puppetlabs/puppetserver
RUN touch /var/log/puppetlabs/puppetserver/masterhttp.log
RUN chmod 660 /var/log/puppetlabs/puppetserver/masterhttp.log

ONBUILD COPY src/ /etc/puppetlabs/code/


# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

USER 1001


EXPOSE 8140

CMD ["/usr/libexec/s2i/usage"]
