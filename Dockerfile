FROM ghcr.io/ministryofjustice/analytical-platform-cloud-development-environment-base@sha256:642f27835387423029b56cf298d671259d56f505157bcfae2d2a193993f4ca35

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="RStudio" \
      org.opencontainers.image.description="RStudio image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-rstudio"

ENV RSTUDIO_VERSION="2024.09.0-375" \
    RSTUDIO_SHA256="3aedf8c376352e426a6d43b77af1bc4346e176a429e5bf919c0e3ca19f4d48ed"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

USER root

# First Run Notice
COPY --chown="${CONTAINER_USER}:${CONTAINER_GROUP}" --chmod=0644 src${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt ${ANALYTICAL_PLATFORM_DIRECTORY}/first-run-notice.txt

# RStudio
COPY --chown=root:root --chmod=0644 src/etc/rstudio/rserver.conf /etc/rstudio/rserver.conf
COPY --chown=root:root --chmod=0644 src/etc/rstudio/logging.conf /etc/rstudio/logging.conf
RUN <<EOF
apt-get update --yes

# These packages are required for RStudio
apt-get install --yes \
  "libssl-dev" \
  "psmisc" \
  "libclang-dev" \
  "lsb-release" \
  "sudo"

curl --location --fail-with-body \
  "https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" \
  --output "rstudio-server.deb"

echo "${RSTUDIO_SHA256} rstudio-server.deb" | sha256sum --check

apt-get install --yes ./rstudio-server.deb

rm --force --recursive rstudio-server.deb /var/lib/apt/lists/*
EOF

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}
EXPOSE 8080
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/healthcheck.sh /usr/local/bin/healthcheck.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["/usr/local/bin/healthcheck.sh"]
