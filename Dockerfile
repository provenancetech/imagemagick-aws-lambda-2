# Build environment for the ImageMagick Lambda layer.
#
# Amazon Linux 2023 matches the OS of every currently supported Lambda runtime.
# Amazon Linux 2 reached end of life on 2026-06-30, so this replaces the
# abandoned lambci/lambda-base-2:build image (last pushed January 2021).
#
# Do NOT switch to gcc14: the AL2023 Lambda runtime ships a libstdc++ built
# with gcc 11 (highest symbol GLIBCXX_3.4.33), so a binary compiled with a
# newer compiler would reference symbols the runtime cannot resolve. The
# default gcc 11 is exactly the runtime's ABI level.
ARG BASE_IMAGE=public.ecr.aws/amazonlinux/amazonlinux:2023
FROM ${BASE_IMAGE}

# Everything Makefile_ImageMagick needs:
#   * gcc/g++/make/cmake - compile the libraries and ImageMagick
#   * autoconf/automake/libtool - libwebp, lcms2 and ImageMagick regenerate
#     their configure scripts from the source archives we download
#   * pkgconf-pkg-config - configure scripts locate the libraries built into
#     the cache directory
#   * zlib-devel - libpng cannot build without zlib headers
#   * tar/xz/gzip/bzip2/unzip/zip/patch/findutils/diffutils/which - absent from
#     the minimal base image but required by the recipes and their autogen.sh
#     scripts
RUN dnf install -y \
      gcc \
      gcc-c++ \
      make \
      cmake \
      autoconf \
      automake \
      libtool \
      pkgconf-pkg-config \
      zlib-devel \
      tar \
      xz \
      gzip \
      bzip2 \
      unzip \
      zip \
      patch \
      findutils \
      diffutils \
      which \
      git \
    && dnf clean all \
    && rm -rf /var/cache/dnf

WORKDIR /var/task
