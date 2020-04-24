FROM openjdk:11.0.7-jdk-slim-buster
LABEL MAINTAINER="Maksim Kostromin <daggerok@gmail.com>"
ENV PRODUCT="jboss-eap-7.3"                                                                     \
    JBOSS_USER="jboss"
ENV ADMIN_USER="admin"                                                                          \
    ADMIN_PASSWORD="Admin.123"                                                                  \
    JBOSS_USER_HOME="/home/${JBOSS_USER}"                                                       \
    DOWNLOAD_BASE_URL="https://github.com/daggerok/${PRODUCT}/releases/download"                \
    JBOSS_EAP_PATCH="7.3.0"
ENV JBOSS_HOME="${JBOSS_USER_HOME}/${PRODUCT}"                                                  \
    ARCHIVES_BASE_URL="${DOWNLOAD_BASE_URL}/archives"                                           \
    PATCHES_BASE_URL="${DOWNLOAD_BASE_URL}/${JBOSS_EAP_PATCH}"
ENV PATH="${JBOSS_HOME}/bin:/tmp:${PATH}"                                                       \
    JAVA_OPTS="-Djava.net.preferIPv4Stack=true -Djboss.bind.address=0.0.0.0 -Djboss.bind.address.management=0.0.0.0"
USER root
RUN ( apt-get update -y || echo "cannot update." )                                           && \
    apt-get install -y wget ca-certificates unzip sudo openssh-client net-tools              && \
    echo "${JBOSS_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers                             && \
    sed -i "s/.*requiretty$/Defaults !requiretty/" /etc/sudoers                              && \
    addgroup --system --gid 1001 ${JBOSS_USER}                                               && \
    adduser --system --home ${JBOSS_USER_HOME} --shell /bin/ash --gid 1001 --uid 1001 ${JBOSS_USER}
USER ${JBOSS_USER}
EXPOSE 8080 8443 9990
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["${JBOSS_HOME}/bin/standalone.sh -b 0.0.0.0"]
WORKDIR /tmp
ADD --chown=jboss ./install.sh .
RUN wget ${ARCHIVES_BASE_URL}/jboss-eap-7.3.0.zip                                               \
          -q --no-cookies --no-check-certificate -O /tmp/jboss-eap-7.3.0.zip                 && \
    unzip -q /tmp/jboss-eap-7.3.0.zip -d ${JBOSS_USER_HOME}                                  && \
    add-user.sh ${ADMIN_USER} ${ADMIN_PASSWORD} --silent                                     && \
    ( standalone.sh --admin-only                                                                \
      & ( sudo chmod +x /tmp/install.sh                                                      && \
          install.sh                                                                         && \
          sudo apt-get remove -y --purge --auto-remove unzip openssh-client ca-certificates  && \
          sudo apt-get autoremove -y                                                         && \
          sudo apt-get autoclean -y                                                          && \
          sudo apt-get clean -y                                                              && \
          ( sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* || echo "cleanup!" ) ) )
WORKDIR ${JBOSS_USER_HOME}

############################################ USAGE ##############################################
#                                                                                               #
# FROM daggerok/jboss-eap-7.3:7.3.0-debian                                                      #
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
