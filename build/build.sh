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

rm -f /etc/yum.repos.d/_copr_ublue-os-akmods.repo

cp -avf "/ctx/files"/. /

/ctx/swap-kernel.sh

dnf5 -y install --setopt=install_weak_deps=False steam

dnf5 -y copr enable ublue-os/bazzite
dnf5 -y copr enable ublue-os/bazzite-multilib
dnf5 -y config-manager setopt '*bazzite*'.priority=90
dnf5 -y install gamescope-libs gamescope-shaders
dnf5 -y copr disable ublue-os/bazzite
dnf5 -y copr disable ublue-os/bazzite-multilib

OGUI_TAG=$(/ctx/ghcurl https://api.github.com/repos/ShadowBlip/OpenGamepadUI/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
IP_TAG=$(/ctx/ghcurl https://api.github.com/repos/ShadowBlip/InputPlumber/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
PS_TAG=$(/ctx/ghcurl https://api.github.com/repos/ShadowBlip/PowerStation/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")

dnf5 -y install https://github.com/ShadowBlip/OpenGamepadUI/releases/download/v${OGUI_TAG}/opengamepadui-${OGUI_TAG}-1.x86_64.rpm \
    https://github.com/ShadowBlip/InputPlumber/releases/download/v${IP_TAG}/inputplumber-${IP_TAG}-1.x86_64.rpm \
    https://github.com/ShadowBlip/PowerStation/releases/download/v${PS_TAG}/powerstation-${PS_TAG}-1.x86_64.rpm

sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/htop.desktop
sed -i 's@\[Desktop Entry\]@\[Desktop Entry\]\nHidden=true@g' /usr/share/applications/nvtop.desktop
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
