#!/bin/bash

# Start SearXNG if not already running
if ! docker compose -f "$HOME/searxng/docker-compose.yml" ps --quiet 2>/dev/null | grep -q .; then
    docker compose -f "$HOME/searxng/docker-compose.yml" up -d
fi

exec dwm
