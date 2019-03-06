#!/bin/bash

salt-call --local \
    --log-level=info \
    --log-file=/tmp/salt-formula.log \
    --log-file-level=all \
    --retcode-passthrough \
    --force-color state.highstate
