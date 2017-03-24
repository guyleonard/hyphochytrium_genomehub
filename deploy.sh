#!/usr/bin/env bash

# ============================================================================
# deploy.sh - automated commands to import an assembly from FASTA and GFF
#
# modified version of import.sh from https://github.com/genomehubs/demo.git
#
# Usage:
# cd
# git clone https://github.com/guyleonard/hyphochytrium_genomehub.git
# cd hyphochytrium_genomehub
# ./deploy.sh
#
# Prerequisites:
# Requires Docker
# ============================================================================

echo Step 1. Set up mySQL container
docker run -d \
           --name hyphochytrium_mysql \
           -e MYSQL_ROOT_PASSWORD=rootuserpassword \
           -e MYSQL_ROOT_HOST='172.17.0.0/255.255.0.0' \
           mysql/mysql-server:5.5 &&
sleep 10 &&


echo Step 2. Set up template database using EasyMirror &&
docker run --rm \
           --name genomehubs-ensembl \
           -v ~/demo/genomehubs-import/ensembl/conf:/ensembl/conf:ro \
           --link genomehubs-mysql \
           -p 8081:8080 \
          genomehubs/easy-mirror:17.03.23 /ensembl/scripts/database.sh /ensembl/conf/database.ini &&
