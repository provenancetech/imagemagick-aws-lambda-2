#!/usr/bin/env bash
# Verify the freshly built toolchain inside the AL2023 Lambda runtime image
# (glibc 2.34, no compiler): a symbol or shared library the runtime does not
# provide would only surface at invoke time otherwise.
#
# Usage: verify-layer.sh <platform>   e.g. linux/amd64 or linux/arm64
#
# The delegate assertions exist because ImageMagick configure degrades to
# "no delegate" when pkg-config cannot find a library, and a make recipe with
# a wrong install path still exits 0 - both produce a binary that runs fine
# but has silently lost format support (this is exactly the lib64/lib bug the
# AL2023 rebuild fixed).
set -euo pipefail

PLATFORM="${1:?platform required (e.g. linux/amd64)}"

docker run --rm --platform="$PLATFORM" \
  -e VERIFY_PLATFORM="$PLATFORM" \
  -v "$PWD/result:/opt:ro" \
  -v "$PWD/src:/src:ro" \
  --entrypoint bash public.ecr.aws/lambda/provided:al2023 \
  -c 'set -e
      /opt/bin/identify -version
      /opt/bin/identify /src/test.jpg
      /opt/bin/convert /src/test.jpg -resize 100x /tmp/thumb.png
      /opt/bin/identify /tmp/thumb.png

      delegates=$(/opt/bin/identify -version | sed -n "s/^Delegates (built-in): //p")
      echo "delegates: $delegates"
      for name in bzlib heic jp2 jpeg lcms png tiff webp zlib; do
        case " $delegates " in
          *" $name "*) ;;
          *) echo "missing delegate: ${name}"; exit 1 ;;
        esac
      done
      # GIF is built into ImageMagick rather than delegated.
      /opt/bin/identify -list format | grep -qE "^[[:space:]]+GIF[*]?([[:space:]]|$)"
      echo "arch: $(uname -m)"
      echo "all expected delegates present on $VERIFY_PLATFORM"'
