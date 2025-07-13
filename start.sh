#!/bin/bash
set -e

bin/rinha_de_backend eval "RinhaDeBackend.Release.migrate"
bin/rinha_de_backend start

exec "$@"