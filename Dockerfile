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

EXPOSE 22
CMD ["/usr/sbin/sshd"]
########### sshd end ###########

# install hadoop
ENV HADOOP_VERSION     2.6.0
ENV HADOOP_PARENT_DIR  /usr/lib/hadoop

RUN mkdir -p $HADOOP_PARENT_DIR \
    && curl -SL http://mirror.bit.edu.cn/apache/hadoop/common/stable/hadoop-$HADOOP_VERSION.tar.gz \
    | tar -zxC $HADOOP_PARENT_DIR

# Add Hadoop bin to $PATH
ENV JAVA_HOME          /usr/lib/jvm/java-6-openjdk-amd64/jre
ENV HADOOP_HOME        $HADOOP_PARENT_DIR/hadoop-$HADOOP_VERSION
ENV PATH               $HADOOP_HOME/bin:$PATH
ENV HADOOP_CONF_DIR    $HADOOP_HOME/etc/hadoop

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-6-openjdk-amd64/jre\nexport HADOOP_HOME=/usr/lib/hadoop/hadoop-2.6.0 \n:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/lib/hadoop/hadoop-2.6.0/etc/hadoop/:' $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# hadoop-env.sh

# copy /etc/bootstrap.sh
ADD ./etc/ /etc/
RUN chmod 700 /etc/bootstrap.sh \
    && chown root:root /etc/bootstrap.sh

