#!/bin/bash

set -euo pipefail

mpv --wayland-app-id="mpv-float" "$1"
