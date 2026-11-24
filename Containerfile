# Asima Hub's build and test container: Qt 6, OpenSSL, and Xvfb with Mesa (software GL) so every
# screen can be rendered to a screenshot headlessly. Packages come from a pinned Arch Linux snapshot.
FROM docker.io/archlinux/archlinux:base
ARG ARCHIVE_DATE=2026/11/14
RUN printf '[options]\nArchitecture = auto\nSigLevel = Required DatabaseOptional\nLocalFileSigLevel = Optional\n\n[core]\nServer = https://archive.archlinux.org/repos/%s/$repo/os/$arch\n\n[extra]\nServer = https://archive.archlinux.org/repos/%s/$repo/os/$arch\n' \
        "${ARCHIVE_DATE}" "${ARCHIVE_DATE}" > /etc/pacman.conf \
    && pacman -Syuu --noconfirm --disable-download-timeout \
        gcc cmake ninja pkgconf openssl \
        qt6-base qt6-declarative qt6-svg qt6-tools \
        breeze-icons noto-fonts noto-fonts-cjk \
        xorg-server-xvfb xorg-xauth mesa \
    && pacman -Scc --noconfirm
