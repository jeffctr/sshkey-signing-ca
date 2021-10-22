FROM centos/systemd

RUN yum update -y && \
    yum install -y \
        openssh-server \
        openssh-clients \
        vim \
        wget \
        python3


COPY ./shared/master_node/sshd_config /etc/ssh/sshd_config
COPY ./shared/user_ca/user_ca.pub /etc/ssh/user_ca.pub


CMD ["/usr/sbin/init"]
