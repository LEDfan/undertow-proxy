#!/usr/bin/env bash

/usr/sbin/nginx -g 'daemon on; master_process on;'

exec $@

