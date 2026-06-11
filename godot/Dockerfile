# Forgejo Actions CI image for the AstralOdyssey Godot/.NET client.
#
# Derives the upstream barichello/godot-ci mono image (Godot 4.6.3 + .NET 8 +
# Linux/Windows/macOS export templates) and adds what THIS runner needs that the
# base lacks:
#   - nodejs/npm : Forgejo runs JS actions (actions/checkout, upload-artifact…)
#                  as `node` INSIDE the job container
#   - awscli     : fetch the 168 MB asset pack from B2 (s3 sync) before export —
#                  Godot can't pull assets at runtime, so they're baked in here
#   - unzip/zip  : extract the asset pack + package the per-platform exports
# Pushed as sickday/godot:mono-4.6.3 (amd64 only — the base is amd64).
FROM barichello/godot-ci:mono-4.6.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs npm unzip zip git ca-certificates curl \
        libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*
# libfontconfig1: Godot dlopen's libfontconfig.so.1 for font handling during
# import/export. The base image lacks it ("cannot open shared object file") —
# harmless for --version, but can break exports that import fonts.

# AWS CLI v2 from AWS's official bundle. Ubuntu noble (24.04) dropped the
# `awscli` apt package, so the repo install ("no installation candidate") is
# dead — fetch the bundle and run its installer instead. (amd64 only, matching
# this image's single-arch build.)
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

RUN node --version && aws --version
