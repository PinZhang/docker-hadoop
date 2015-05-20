# Specify the base image
FROM ubuntu:12.04

MAINTAINER Pin Zhang <pzhang@mozilla.com>

# switch to faster mirrors
ADD sources.list /etc/apt/
RUN apt-get update

# Install prerequisites
RUN apt-get install -y ssh curl rsync openjdk-6-jdk openssh-server

########### sshd start ###########
# install sshd, copy from: https://docs.docker.com/examples/running_ssh_service/
RUN mkdir /var/run/sshd

# passwordless ssh, copy from: https://github.com/sequenceiq/hadoop-docker/blob/master/Dockerfile
# this could be override by mounting host dir like:
#  -v ssh_settings:/root/.ssh
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config
########### sshd end ###########

# install hadoop
ENV HADOOP_VERSION     2.6.0
ENV HADOOP_PARENT_DIR  /usr/lib/hadoop

RUN mkdir -p $HADOOP_PARENT_DIR \
    && curl -SL http://mirror.bit.edu.cn/apache/hadoop/common/stable/hadoop-$HADOOP_VERSION.tar.gz \
    | tar -zxC $HADOOP_PARENT_DIR

# Add Hadoop bin to $PATH
ENV JAVA_HOME          /usr/lib/jvm/java-6-openjdk-amd64/jre
ENV HADOOP_PREFIX      $HADOOP_PARENT_DIR/hadoop-$HADOOP_VERSION
ENV HADOOP_HOME        $HADOOP_PREFIX
ENV PATH               $HADOOP_PREFIX/bin:$PATH
ENV HADOOP_CONF_DIR    $HADOOP_PREFIX/etc/hadoop

COPY hadoop_configs/*  $HADOOP_CONF_DIR/

# Create dirs for hdfs, we could always reset them by volumes mounting.
RUN mkdir -p /hdfs/name/ \
    mkdir -p /hdfs/data/ \
    mkdir -p /hdfs/namesecondary

# need to run this, otherwise namenode can't be started.
RUN $HADOOP_PREFIX/bin/hdfs namenode -format
# hadoop-env.sh

# copy /etc/bootstrap.sh
ADD ./etc/ /etc/
RUN chmod 700 /etc/bootstrap.sh \
    && chown root:root /etc/bootstrap.sh

CMD ["/etc/bootstrap.sh", "-d"]

# ssh
EXPOSE 22

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090

