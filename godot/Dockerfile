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
        nodejs npm awscli unzip zip git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN node --version && aws --version
