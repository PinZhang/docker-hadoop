# Specify the base image
FROM ubuntu:12.04

MAINTAINER Pin Zhang <pzhang@mozilla.com>

# switch to faster mirrors
ADD sources.list /etc/apt/
RUN apt-get update

RUN apt-get install -y ssh curl rsync openjdk-6-jdk

# install hadoop
RUN mkdir -p /usr/lib/hadoop \
    && curl -SL http://mirror.bit.edu.cn/apache/hadoop/common/stable/hadoop-2.6.0.tar.gz \
    | tar -zxC /usr/lib/hadoop

# set env
ENV JAVA_HOME  /usr/lib/jvm/java-6-openjdk-amd64/jre
ENV PATH       /usr/lib/hadoop/hadoop-2.6.0/bin:$PATH

# install sshd, copy from: https://docs.docker.com/examples/running_ssh_service/
RUN apt-get install -y openssh-server
RUN mkdir /var/run/sshd

# passwordless ssh, copy from: https://github.com/sequenceiq/hadoop-docker/blob/master/Dockerfile
# this could be override by mounting host dir like:
#  -v ssh_settings:/root/.ssh
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

EXPOSE 22
CMD ["/usr/sbin/sshd"]

# copy /etc/bootstrap.sh
ADD ./etc/ /etc/
RUN chmod 700 /etc/bootstrap.sh \
    && chown root:root /etc/bootstrap.sh

