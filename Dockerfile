# Specify the base image
FROM ubuntu:14.04

MAINTAINER Pin Zhang <pzhang@mozilla.com>

# switch to faster mirrors
ADD sources.list /etc/apt/
RUN apt-get update

# Install prerequisites
RUN apt-get install -y ssh curl rsync openjdk-7-jdk openssh-server

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

# install hive
ENV HIVE_VERSION       1.2.0
ENV HIVE_PARENT_DIR    /usr/lib/hive

RUN mkdir -p $HIVE_PARENT_DIR \
    && curl -SL http://mirror.bit.edu.cn/apache/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz \
    | tar -zxC $HIVE_PARENT_DIR \
    && mv $HIVE_PARENT_DIR/apache-hive-$HIVE_VERSION-bin $HIVE_PARENT_DIR/hive-$HIVE_VERSION

# setup Hive
ENV HIVE_HOME          $HIVE_PARENT_DIR/hive-$HIVE_VERSION
ENV HIVE_CONF          $HIVE_HOME/conf
ENV PATH               $HIVE_HOME/bin:$PATH

COPY hive_configs      $HIVE_CONF

# install java driver class, and add it into classpath
RUN apt-get install -y libmysql-java
RUN ln -n /usr/share/java/mysql-connector-java-5.1.28.jar  $HIVE_HOME/lib/mysql.jar

# setup Hadoop
ENV JAVA_HOME          /usr/lib/jvm/java-6-openjdk-amd64/jre
ENV HADOOP_PREFIX      $HADOOP_PARENT_DIR/hadoop-$HADOOP_VERSION
ENV HADOOP_HOME        $HADOOP_PREFIX
ENV PATH               $HADOOP_PREFIX/bin:$PATH
ENV HADOOP_CONF_DIR    $HADOOP_PREFIX/etc/hadoop

ENV HADOOP_MAPRED_HOME $HADOOP_PREFIX
ENV YARN_CONF_DIR      $HADOOP_CONF_DIR

COPY hadoop_configs    $HADOOP_CONF_DIR

# Create dirs for hdfs, we could always reset them by volumes mounting.
RUN mkdir -p /hdfs/name/ \
    mkdir -p /hdfs/data/ \
    mkdir -p /hdfs/namesecondary

# need to run this, otherwise namenode can't be started.
RUN $HADOOP_PREFIX/bin/hdfs namenode -format
# hadoop-env.sh

# use 8002
RUN sed -i '/^Port 22/ s:.*:Port 8002:' /etc/ssh/sshd_config

# copy /etc/bootstrap.sh
ADD ./etc/ /etc/
RUN chmod 700 /etc/bootstrap.sh \
    && chown root:root /etc/bootstrap.sh

CMD ["/etc/bootstrap.sh", "-d"]

# ssh
EXPOSE 8002

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090

# Mapred ports
EXPOSE 19888

#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088

