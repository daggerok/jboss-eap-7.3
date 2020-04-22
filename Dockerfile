FROM centos:centos8.1.1911
LABEL MAINTAINER="Maksim Kostromin <daggerok@gmail.com>"
ENV PRODUCT="jboss-eap-7.3"                                                                                 \
    JBOSS_USER="jboss"
ENV ADMIN_USER="admin"                                                                                      \
    ADMIN_PASSWORD="Admin.123"                                                                              \
    JBOSS_USER_HOME="/home/${JBOSS_USER}"                                                                   \
    DOWNLOAD_BASE_URL="https://github.com/daggerok/${PRODUCT}/releases/download"                            \
    JBOSS_EAP_PATCH="7.3.0"
ENV JBOSS_HOME="${JBOSS_USER_HOME}/${PRODUCT}"                                                              \
    ARCHIVES_BASE_URL="${DOWNLOAD_BASE_URL}/archives"                                                       \
    PATCHES_BASE_URL="${DOWNLOAD_BASE_URL}/${JBOSS_EAP_PATCH}"
ENV PATH="${JBOSS_HOME}/bin:/tmp:${PATH}"                                                                   \
    JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk"                                                             \
    JAVA_OPTS="-Djava.net.preferIPv4Stack=true -Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0"
USER root
RUN yum update --security -y -q                                                                          && \
    yum install -y -q unzip openssh-clients zip net-tools                                                   \
                      wget ca-certificates curl sudo java-1.8.0-openjdk-devel                            && \
    echo "${JBOSS_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers                                         && \
    groupadd --system --gid 1001 ${JBOSS_USER}                                                           && \
    adduser --system -m -d ${JBOSS_USER_HOME} -s /sbin/bash -g ${JBOSS_USER} --uid 1001 ${JBOSS_USER}    && \
    usermod -a -G ${JBOSS_USER} ${JBOSS_USER}
USER ${JBOSS_USER}
EXPOSE 8080 8443 9990
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["${JBOSS_HOME}/bin/standalone.sh -b 0.0.0.0"]
WORKDIR /tmp
ADD --chown=jboss ./install.sh .
RUN wget ${ARCHIVES_BASE_URL}/jboss-eap-7.3.0.zip                                                           \
          -q --no-cookies --no-check-certificate -O /tmp/jboss-eap-7.3.0.zip                             && \
    unzip -q /tmp/jboss-eap-7.3.0.zip -d ${JBOSS_USER_HOME}                                              && \
    add-user.sh ${ADMIN_USER} ${ADMIN_PASSWORD} --silent                                                 && \
    ( standalone.sh --admin-only                                                                            \
      & ( sudo chmod +x /tmp/install.sh                                                                  && \
          install.sh                                                                                     && \
          rm -rf /tmp/install.sh                                                                         && \
          sudo yum autoremove -y                                                                         && \
          sudo yum clean all -y                                                                          && \
          ( sudo rm -rf /tmp/* /var/cache/yum || echo "something was not removed..." ) ) )
WORKDIR ${JBOSS_USER_HOME}

############################################ USAGE ##############################################
#                                                                                               #
# FROM daggerok/jboss-eap-7.3:7.3.0-centos                                                     #
#                                                                                               #
# # debug:                                                                                      #
# ENV JAVA_OPTS="$JAVA_OPTS -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005" #
# EXPOSE 5005                                                                                   #
#                                                                                               #
# # health-check:                                                                               #
# HEALTHCHECK --retries=33 \                                                                    #
#             --timeout=1s \                                                                    #
#             --interval=1s \                                                                   #
#             --start-period=3s \                                                               #
#             CMD  wget -q --spider http://127.0.0.1:8080/my-service/health || exit 1           #
#             #CMD curl -f http://127.0.0.1:8080/my-servicehealth           || exit 1           #
#             #CMD test `netstat -ltnp | grep 9990 | wc -l` -ge 1           || exit 1           #
# COPY --chown=jboss ./target/*.war ${JBOSS_HOME}/standalone/deployments/my-service.war         #
#                                                                                               #
# # or multi-deployment:                                                                        #
# COPY --chown=jboss ./target/*.war ./build/libs/*.war ${JBOSS_HOME}/standalone/deployments/    #
#                                                                                               #
#################################################################################################
