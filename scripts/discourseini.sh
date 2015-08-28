#!/bin/sh
. /opt/bitnami/scripts/setenv.sh
export LANG=en_US.UTF-8

cd /opt/bitnami/apps/discourse/htdocs
bin/rake db:migrate RAILS_ENV='production'
exit $EXITCODE
