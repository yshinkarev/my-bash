FROM openjdk:11.0.7-jre

RUN yum update -y \
   && yum -y install xmlstarlet saxon augeas bsdtar tar unzip curl wget less dos2unix gettext \
   && yum clean all \
   && echo "Europe/Moscow" > /etc/timezone \
   && cd /etc/ ; rm /etc/localtime && ln -s ../usr/share/zoneinfo/Europe/Moscow ./localtime

RUN groupadd -r tkit -g 1111 \
 && useradd -l -u 1111 -r -g tkit -m -d /home/tkit -s /bin/bash -c "tkit user" tkit \
 && chmod -R 755 /home/tkit \
 && mkdir /opt/tkit \
 && chown -R tkit:tkit /opt/tkit \
 && chmod 755 /opt/tkit \
 && echo 'tkit ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

WORKDIR /opt/tkit
USER tkit


USER root
ENV H2DIR=/opt/h2 \
    H2VERS=1.4.193 \
    H2DATA=/opt/h2-data \
    H2CONF=/opt/h2-conf

ADD h2-start.sh /tmp/

RUN mkdir -p ${H2CONF} ${H2DATA}/data \
    && groupadd -r h2 -g 2000 \
    && useradd -u 2000 -r -g h2 -m -d ${H2DATA}/data -s /sbin/nologin -c "h2 user" h2 \
    && curl -L http://www.h2database.com/h2-2016-10-31.zip -o /tmp/h2.zip \
    && unzip -q /tmp/h2.zip -d /opt/ \
    && rm /tmp/h2.zip \
    && mv /tmp/h2-start.sh ${H2DIR}/bin \
    && chmod 755 ${H2DIR}/bin/h2-start.sh  ${H2DIR}/bin/h2.sh \
    && chown -R h2:h2 /opt/h2*

USER h2

WORKDIR ${H2DIR}

CMD ["/opt/h2/bin/h2-start.sh"]