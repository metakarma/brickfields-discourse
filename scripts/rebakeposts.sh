#!/bin/sh

. /opt/bitnami/scripts/setenv.sh
cd /opt/bitnami/apps/discourse/htdocs
bin/rake posts:rebake RAILS_ENV='production'
