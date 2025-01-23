FROM ghcr.io/ministryofjustice/analytical-platform-cloud-development-environment-base@sha256:adb9c1bb3a1deb8e8fcf7572a59245469da44d464d731a55b627b6431ef8638c

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="RStudio" \
      org.opencontainers.image.description="RStudio image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-rstudio"

ENV RSTUDIO_SERVER_VERSION="2024.09.0-375" \
    RSTUDIO_SERVER_SHA256="efcc1c69252dd220b30973c7a10571707cfd47afc70c37c11a5e68efd2129feb"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

USER root

# First Run Notice
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt

# RStudio
RUN <<EOF
apt-get update --yes

# These packages are required for RStudio
apt-get install --yes \
  "libssl-dev=3.0.13-0ubuntu3.4" \
  "psmisc=23.7-1build1" \
  "libclang-dev=1:18.0-59~exp2" \
  "lsb-release=12.0-2" \
  "sudo=1.9.15p5-3ubuntu5"

curl --location --fail-with-body \
  "https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_SERVER_VERSION}-amd64.deb" \
  --output "rstudio-server.deb"

echo "${RSTUDIO_SERVER_SHA256} rstudio-server.deb" | sha256sum --check

apt-get install --yes ./rstudio-server.deb

rm --force --recursive rstudio-server.deb /var/lib/apt/lists/*

# RStudio Server is started when installing
# (https://docs.posit.co/ide/server-pro/server_management/core_administrative_tasks.html#stopping-and-starting)
rstudio-server stop

# RStudio DEBUG
chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} /var/lib/rstudio-server
chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} /var/run/rstudio-server
EOF

COPY --chown=root:root --chmod=0644 src/etc/rstudio/logging.conf /etc/rstudio/logging.conf
COPY --chown=root:root --chmod=0644 src/etc/rstudio/rserver.conf /etc/rstudio/rserver.conf

### DEBUG
RUN <<EOF
# THIS WORKS
echo "PATH=${PATH}:\${PATH}" > /etc/profile.d/10-global-path.sh
# THIS DOES NOT WORK
echo "ANALYTICAL_PLATFORM_DIRECTORY=${ANALYTICAL_PLATFORM_DIRECTORY}" > /etc/profile.d/20-analytical-platform.sh
EOF

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}
EXPOSE 8080
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]
