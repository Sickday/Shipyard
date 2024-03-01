FROM debian:latest

RUN apt update && apt install -y \
    "libsdl2-*-dev" \
    "libsdl2-*"
