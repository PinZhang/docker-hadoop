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

