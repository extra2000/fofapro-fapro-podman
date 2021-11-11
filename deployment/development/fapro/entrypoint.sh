#!/bin/sh
set -e

# Makes fapro to write logs into a different directory
ln --symbolic /opt/fapro/logs/fapro.log /opt/fapro/fapro.log

exec "$@"
