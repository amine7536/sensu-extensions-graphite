FROM centos:centos7

ENV GEM_VERSION "0.0.2"
ENV GEM_PREFIX "/opt/sensu/embedded/lib/ruby/gems/2.4.0"

COPY build/sensu.repo /etc/yum.repos.d/sensu.repo
RUN mkdir /rpms \
        && yum -y install rpm-build sensu \
        && /opt/sensu/embedded/bin/gem install fpm
ENV PATH $PATH:/opt/sensu/embedded/bin

VOLUME /rpms
WORKDIR /rpms

ENTRYPOINT ["/rpms/build.sh"]
CMD ["sensu-extensions-graphite"]
