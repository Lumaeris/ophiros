FROM scratch AS ctx

COPY build /
COPY files /files
COPY cosign.pub /files/etc/pki/containers/lumaeris.pub
COPY --from=ghcr.io/ublue-os/brew:latest /system_files /files
COPY --from=ghcr.io/bazzite-org/kernel-bazzite:latest-f43-x86_64 / /kernel

FROM ghcr.io/ublue-os/silverblue-main:43

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/var \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# optimizing the image so bootc won't complain
# also applying a workaround for /opt
RUN rm -rf /var/* && \
    rm -rf /tmp/* && \
    rm -rf /usr/etc && \
    rm -rf /boot && \
    rm -rf /opt && \
    mkdir /boot && \
    mkdir /var/{tmp,roothome,opt} && \
    ln -s /var/opt /opt && \
    chmod -R 1777 /var/tmp && \
    bootc container lint
