# The live-fight server: headless Godot 4.3 running this repo's sim/ and server/.
# Build from the repo root:  docker build -f server/Dockerfile -t battleballs-live .
# Run locally:               docker run -p 8080:8080 -e LIVE_DEV=1 battleballs-live
ARG BASE=ubuntu:24.04
FROM ${BASE}
ARG GODOT_VERSION=4.3
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 \
 && curl -sSfL -o /tmp/godot.zip "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
 && unzip -q /tmp/godot.zip -d /opt && mv /opt/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
 && rm /tmp/godot.zip && apt-get purge -y curl unzip && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
RUN useradd --create-home live
WORKDIR /app
# Only what the server runs: the sim, the server and the project file.
COPY project.godot ./
COPY sim ./sim
COPY server ./server
RUN chown -R live /app
USER live
RUN timeout 180 godot --headless --import || true
ENV PORT=8080
EXPOSE 8080
CMD ["godot", "--headless", "--script", "res://server/live_server.gd"]
