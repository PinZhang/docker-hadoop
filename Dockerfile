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

# install sshd
RUN apt-get install -y openssh-server

RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22
CMD ["/usr/sbin/sshd"]

ADD ./etc/ /etc/
RUN chmod 700 /etc/bootstrap.sh \
    && chown root:root /etc/bootstrap.sh

