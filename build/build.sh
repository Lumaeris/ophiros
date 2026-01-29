#!/usr/bin/env bash

set -xeuo pipefail

dnf5 config-manager setopt fedora-cisco-openh264.enabled=0

dnf5 -y remove ublue-os-udev-rules \
    ublue-os-update-services \
    ublue-os-signing \
    fedora-bookmarks \
    fedora-chromium-config \
    fedora-chromium-config-gnome \
    firefox \
    firefox-langpacks \
    gnome-extensions-app \
    gnome-shell-extension-background-logo \
    gnome-software \
    gnome-software-rpm-ostree \
    gnome-terminal-nautilus \
    podman-docker \
    yelp \
    cosign \
    toolbox

cp -avf "/ctx/files"/. /

/ctx/swap-kernel.sh

sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/_copr_ublue-os-akmods.repo

rm -rf /usr/src
rm -rf /usr/share/doc
rm -rf /usr/share/man
rpm --erase --nodeps kernel-devel

flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
systemctl mask flatpak-add-fedora-repos.service

#sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service
dnf5 clean all

systemctl enable systemd-timesyncd.service
systemctl enable systemd-resolved.service
systemctl enable brew-setup.service
systemctl enable flatpak-nuke-fedora.service
systemctl disable rpm-ostree-countme.service
systemctl disable rpm-ostreed-automatic.timer
