# syntax=docker/dockerfile:1
# Bash execution environment with Docker Hardened Images.
# Uses debian-base since there is no dedicated DHI shell image.

ARG RUNNER_IMAGE=ghcr.io/aron-muon/kubecoderun-runner:latest
FROM ${RUNNER_IMAGE} AS runner

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

################################
# Final stage - runtime image
################################
FROM dhi.io/debian-base:trixie-debian13-dev AS final

ARG BUILD_DATE
ARG VERSION
ARG VCS_REF

LABEL org.opencontainers.image.title="KubeCodeRun Bash Environment" \
      org.opencontainers.image.description="Secure execution environment for Bash scripts" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install runtime utilities a typical bash script reaches for.
# bash, coreutils, grep, sed, gawk are the bare minimum for the
# shell to be useful; findutils (find/xargs) and jq cover the
# next-most-common patterns.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    grep \
    sed \
    gawk \
    findutils \
    jq \
    ca-certificates \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /mnt/data && chown 65532:65532 /mnt/data

WORKDIR /mnt/data

USER 65532

# Copy runner binary for code execution
COPY --from=runner /runner /usr/local/bin/runner

ENTRYPOINT ["/usr/bin/env", "-i", \
    "PATH=/usr/bin:/bin", \
    "HOME=/tmp", \
    "TMPDIR=/tmp", \
    "LANGUAGE=bash"]
CMD ["/usr/local/bin/runner"]
