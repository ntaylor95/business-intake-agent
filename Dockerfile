# Dev container for the AI Pipeline
#
# Provides Node 20 LTS + Python 3.11, plus everything needed to scaffold and
# run Vite + React + TypeScript + Vitest UIs AND FastAPI/MCP Python services.
#
# Build:   docker build -t claude-team-agent-dev .
# Run:     see docker-compose.yml — `docker compose up -d` is the easy path.

FROM node:20-bookworm-slim

# System tooling + Python toolchain.
# node:20-bookworm-slim is intentionally minimal — git/curl/python aren't
# included by default.
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        python3 \
        python3-pip \
        python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3 /usr/local/bin/python

# Pin npm to a recent version. Node 20 ships with an older npm; this prevents
# subtle compatibility issues with newer create-vite releases.
RUN npm install -g npm@latest

# Python toolchain:
#   uv      — fast modern package manager (replaces pip + pip-tools + venv)
#   httpx   — async-capable HTTP client (default per CLAUDE.md Python Stack)
#   pytest  — default test framework
#   mypy    — strict static type checker (default per CLAUDE.md Python Stack)
#
# Installed globally with --break-system-packages because this is a dev container
# the user owns; per-project venvs via `uv init` still work normally on top.
RUN pip3 install --no-cache-dir --break-system-packages \
        uv \
        httpx \
        pytest \
        mypy \
        pydantic-settings \
        python-dotenv

# Non-root user. Matches the host UID 1000 by default so file ownership on
# bind-mounted volumes stays clean.
#
# The node:20-bookworm-slim base image ships with a pre-existing "node"
# user/group at UID/GID 1000. Remove it so we can create our own "developer"
# user at the same UID/GID matching the host. Without this, groupadd fails
# with "GID '1000' already exists".
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN userdel -r node 2>/dev/null || true \
    && groupdel node 2>/dev/null || true \
    && groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME

WORKDIR /workspace
RUN chown $USERNAME:$USERNAME /workspace
USER $USERNAME

# Vite dev server (5173) and FastAPI/uvicorn default (8000).
# MCP servers usually talk stdio so no port needed unless using HTTP/SSE transport.
EXPOSE 5173 8000

# Keep the container alive so the user can `docker exec` into it.
# Override with `command:` in docker-compose if you want it to do something else.
CMD ["bash", "-c", "tail -f /dev/null"]
