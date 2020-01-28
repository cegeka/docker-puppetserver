# Puppetserver docker file
FROM registry.access.redhat.com/rhel8/ruby-25:latest
LABEL maintainer="Thomas Meeus <thomas.meeus@cegeka.com>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

# TODO: Set labels used in OpenShift to describe the builder image
LABEL io.k8s.description="Container which will push Puppet facts to foreman" \
      io.k8s.display-name="Openshift-puppetserver-facts-pusher" \
      io.openshift.tags="openshift,docker,puppet,puppetserver,image,builder"

USER root

RUN dnf -y install hostname \
        && yum clean all \
        && gem install facter --no-ri --no-rdoc \
        && mkdir -p /opt/puppetlabs/server/data/puppetserver/yaml/

COPY ./external_node_v2.rb /usr/local/bin/external-node-v2.rb

USER 1001

EXPOSE 8140

CMD ["/usr/libexec/s2i/usage"]
