#!/usr/bin/env bash

usage() {
  echo "Usage: ./project.sh <command> [args]"
  echo
  echo "Core commands:"
  echo "  info         Show scripts/project.sh.info"
  echo "  self-update  Reinstall scripts via PROJECT_SH_ORIGIN_INSTALL"
  echo
  echo "No other command modules are bundled by default in project.sh core."
  echo "Add modules under scripts/project/*.sh in your repository to extend commands."
}
