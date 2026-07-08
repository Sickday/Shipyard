# Hardened distroless RUNTIME BASE for Elixir/Erlang releases.
# Pushed as sickday/elixir:distroless (see .github/workflows/elixir-distroless.yml).
#
# Contains NO ERTS and NO application — just the minimal scaffolding a
# `mix release` needs to run on distroless/cc:
#   * a deny-by-default static busybox: /bin/sh + the ~14 coreutils the release
#     launcher scripts call, and NOTHING else. Built from source with allnoconfig
#     so no network/fetch/server applet (wget/nc/tftpd/...) is even compiled in —
#     a compromised container has no `wget | sh` fetch primitive. Verified at
#     build time (the build FAILS if a network applet slips in).
#   * libtinfo — beam.smp's terminal driver, which distroless/cc does not ship.
#   * a writable /tmp (1777) — runtime.exs sys.config staging + crash dumps under
#     the nonroot user.
#   * UTF-8 locale + sane RELEASE_TMP/PATH defaults (distroless has no locale, so
#     the BEAM otherwise defaults to latin1).
#
# Usage in an app Dockerfile. Build the release on a *trixie* builder so the
# :crypto NIF and the ERTS link the same glibc/OpenSSL this image
# (distroless/cc-debian13) ships (the sickday/elixir:ci builder is trixie):
#
#   FROM hexpm/elixir:<ver>-erlang-<ver>-debian-trixie-<date> AS builder
#   # ... mix release, assemble at /rel ...
#   FROM sickday/elixir:distroless
#   COPY --from=builder /rel /app
#   # App-specific native libs go here, e.g. libbz2 for the bzip2 NIF:
#   #   COPY --from=builder /usr/lib/*-linux-gnu/libbz2.so.1* /usr/lib/
#   ENTRYPOINT ["/app/bin/<release>"]
#   CMD ["start"]
#
# This base is OTP-agnostic (no ERTS), so one tag serves every Elixir app
# regardless of Elixir/OTP version.

ARG BUSYBOX_VERSION=1.36.1
ARG RUNTIME_IMAGE=gcr.io/distroless/cc-debian13:nonroot

# ---------------------------------------------------------------------------
# Stage 1: custom minimal static busybox (deny-by-default)
# ---------------------------------------------------------------------------
FROM debian:trixie-slim AS busybox

ARG BUSYBOX_VERSION
# libtinfo6 is pulled in here so we can carry libtinfo.so.6 into the final image.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential wget bzip2 ca-certificates libtinfo6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN wget -q "https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2" \
    && tar xf "busybox-${BUSYBOX_VERSION}.tar.bz2" --strip-components=1

# allnoconfig (everything off) + re-enable only a static build, ash, and the
# coreutils the release launcher scripts call. echo/printf/[/test are ash
# BUILTINS via ASH_ECHO/ASH_PRINTF/ASH_TEST (default y upstream, but allnoconfig
# forces them off and they only appear once ASH is on — hence two oldconfig
# passes). FEATURE_SH_MATH etc. are shell *features*, not applets: no surface.
RUN make allnoconfig \
    && for sym in STATIC ASH CUT CAT SED GREP BASENAME DIRNAME READLINK \
                  DD OD AWK DATE MKDIR ENV ; do \
         sed -i "s/^# CONFIG_${sym} is not set/CONFIG_${sym}=y/" .config ; \
       done \
    && yes "" | make oldconfig \
    && for b in ASH_ECHO ASH_PRINTF ASH_TEST FEATURE_SH_MATH \
                ASH_GETOPTS ASH_CMDCMD ASH_INTERNAL_GLOB ASH_OPTIMIZE_FOR_SIZE ; do \
         sed -i "s/^# CONFIG_${b} is not set/CONFIG_${b}=y/" .config ; \
       done \
    && yes "" | make oldconfig \
    && make -j"$(nproc)" 2>/dev/null

# Stage busybox + the applet symlinks the release scripts need, plus a writable
# /tmp (1777). CONFIG_BUSYBOX (the multiplexer) is OFF, so applets are reachable
# only via these symlinks.
RUN mkdir -p /rootfs/bin \
    && cp busybox /rootfs/bin/busybox \
    && for a in sh cut cat sed grep basename dirname readlink dd od awk date mkdir env ; do \
         ln -s busybox "/rootfs/bin/$a" ; \
       done \
    && mkdir -m 1777 -p /rootfs/tmp

# Enforce the security property at build time: shell + builtins work (PATH
# limited to our busybox dir, mirroring the runtime — no debian coreutil
# fallback), and no fetch/network/persistence applet is compiled in.
RUN env -i PATH=/rootfs/bin /rootfs/bin/sh -c 'echo OK; printf "%s\n" PRN; [ -d / ] && echo BR' \
      | tr '\n' ' ' | grep -q 'OK PRN BR' || { echo "FATAL: shell/builtins broken" >&2; exit 1; } ; \
    for bad in wget curl nc netcat tftp tftpd telnet telnetd ftpget ftpput ftpd \
               httpd nslookup ping nbd-client sendmail popmaildir rdate whois \
               crond crontab dpkg rpm ip ifconfig route nsenter chroot ; do \
      ln -sf /rootfs/bin/busybox "/tmp/$bad" ; \
      if ! "/tmp/$bad" 2>&1 | grep -q 'applet not found' ; then \
        echo "FATAL: applet '$bad' is reachable in the runtime busybox" >&2 ; exit 1 ; \
      fi ; \
      rm -f "/tmp/$bad" ; \
    done ; \
    echo "deny-by-default verified: shell works, no fetch/network/persistence applets present"

# ---------------------------------------------------------------------------
# Stage 2: the published base
# ---------------------------------------------------------------------------
FROM ${RUNTIME_IMAGE} AS base

COPY --from=busybox /rootfs/bin /bin
COPY --from=busybox /rootfs/tmp /tmp
# beam.smp links libtinfo (ncurses); distroless/cc lacks it. /usr/lib is on
# glibc's default search path; the glob stays arch-agnostic. Source the
# canonical /usr/lib path (not the /lib symlink) — Docker's COPY glob does not
# resolve through /lib -> usr/lib on usr-merged Debian (trixie), so /lib/... matches nothing.
COPY --from=busybox /usr/lib/*-linux-gnu/libtinfo.so.6 /usr/lib/

ENV PATH="/bin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin"
ENV LANG="C.UTF-8" LC_ALL="C.UTF-8" ELIXIR_ERL_OPTIONS="+fnu"
ENV RELEASE_TMP="/tmp" ERL_CRASH_DUMP="/tmp/erl_crash.dump"
WORKDIR /app

# No ENTRYPOINT/CMD — the consuming app's release defines these.
