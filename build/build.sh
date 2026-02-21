#!/usr/bin/env bash

set -xeuo pipefail

# swap to generic logos
dnf5 swap -y fedora-logos generic-logos

# remove leftovers
dnf5 config-manager setopt fedora-cisco-openh264.enabled=0
dnf5 -y remove ublue-os-update-services \
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
    toolbox \
    gnome-tour \
    gnome-classic-session
rm -f /etc/yum.repos.d/_copr_ublue-os-akmods.repo

# copy system files over
cp -avf "/ctx/files"/. /

# swap to bazzite kernel
/ctx/swap-kernel.sh

# put homebrew to its own layer
setfattr -n user.component -v "homebrew" /usr/share/homebrew.tar.zst

# install steam and sddm (the latter is needed for gamescope session)
dnf5 -y install --setopt=install_weak_deps=False steam sddm

# enable bunch of repos, install gamescope{,-session} and steam deck dsp (for oled model)
dnf5 -y copr enable ublue-os/bazzite
dnf5 -y copr enable ublue-os/bazzite-multilib
dnf5 -y copr enable ycollet/audinux
dnf5 -y config-manager setopt '*bazzite*'.priority=90
dnf5 -y install gamescope-libs gamescope-shaders steamdeck-dsp gamescope-session-plus
dnf5 -y copr disable ublue-os/bazzite
dnf5 -y copr disable ublue-os/bazzite-multilib
dnf5 -y copr disable ycollet/audinux

# get latest versions of shadowblip software from github and install it directly
OGUI_TAG=$(/ctx/ghcurl https://api.github.com/repos/ShadowBlip/OpenGamepadUI/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
IP_TAG=$(/ctx/ghcurl https://api.github.com/repos/ShadowBlip/InputPlumber/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
PS_TAG=$(/ctx/ghcurl https://api.github.com/repos/ShadowBlip/PowerStation/releases/latest | grep tag_name | cut -d : -f2 | tr -d "v\", ")
dnf5 -y install https://github.com/ShadowBlip/OpenGamepadUI/releases/download/v${OGUI_TAG}/opengamepadui-${OGUI_TAG}-1.x86_64.rpm \
    https://github.com/ShadowBlip/InputPlumber/releases/download/v${IP_TAG}/inputplumber-${IP_TAG}-1.x86_64.rpm \
    https://github.com/ShadowBlip/PowerStation/releases/download/v${PS_TAG}/powerstation-${PS_TAG}-1.x86_64.rpm

# install bazaar
dnf5 -y copr enable ublue-os/packages
dnf5 -y install bazaar
dnf5 -y copr disable ublue-os/packages

# finishing touches
glib-compile-schemas /usr/share/glib-2.0/schemas
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

# Temporarily patch /etc/os-release to avoid the initramfs depending on the
# version number (which changes daily).
# https://github.com/secureblue/secureblue/pull/1923
tmp_release_file=$(mktemp --tmpdir 'os-release-XXXXXXXXXX')
cp /etc/os-release "${tmp_release_file}"
sed -Ei -e '/^(OSTREE_)VERSION=/d' /etc/os-release

# regenerate initramfs (since we no longer have it)
KERNEL_VERSION="$(find "/usr/lib/modules" -maxdepth 1 -type d ! -path "/usr/lib/modules" -exec basename '{}' ';' | sort | tail -n 1)"
export DRACUT_NO_XATTR=1
dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree -f "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"
chmod 0600 "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

cp "${tmp_release_file}" /etc/os-release

systemctl enable systemd-timesyncd.service
systemctl enable systemd-resolved.service
systemctl enable brew-setup.service
systemctl enable flatpak-nuke-fedora.service
systemctl enable powerstation.service
systemctl enable inputplumber.service
systemctl enable inputplumber-suspend.service
systemctl disable rpm-ostree-countme.service
systemctl disable rpm-ostreed-automatic.timer
