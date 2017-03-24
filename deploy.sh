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
           --name hyphochytrium-mysql \
           -e MYSQL_ROOT_PASSWORD=rootuserpassword \
           -e MYSQL_ROOT_HOST='172.17.0.0/255.255.0.0' \
           mysql/mysql-server:5.5 &&
sleep 10 &&


echo Step 2. Set up template database using EasyMirror &&
docker run --rm \
           --name hyphochytrium-ensembl \
           -v ~/hyphochytrium_genomehub/ensembl/conf:/ensembl/conf:ro \
           --link hyphochytrium-mysql \
           -p 8081:8080 \
          genomehubs/easy-mirror:17.03.23 /ensembl/scripts/database.sh /ensembl/conf/database.ini &&

echo Step 3. Import sequences, prepare gff and import gene models &&
docker run --rm \
           -u $UID:$GROUPS \
           --name easy-import-hyphochytrium-catenoides \
           --link hyphochytrium-mysql \
           -v ~/hyphochytrium_genomehub/import/hypho/conf:/import/hypho/conf \
           -v ~/hyphochytrium_genomehub/import/hypho/data:/import/hypho/data \
           -e DATABASE=Hyphochytrium_catenoides_2017 \
           -e FLAGS="-s -p -g" \
           genomehubs/easy-import:17.03.23 &&

echo Step 4. Export sequences, export json and index database for imported Hyphochytrium catenoides &&
docker run --rm \
           -u $UID:$GROUPS \
           --name easy-import-operophtera_brumata_v1_core_32_85_1 \
           --link hyphochytrium-mysql \
           -v ~/hyphochytrium_genomehub/import/hypho/conf:/import/hypho/conf \
           -v ~/hyphochytrium_genomehub/import/hypho/data:/import/hypho/data \
           -v ~/hyphochytrium_genomehub/import/download/data:/import/download \
           -v ~/hyphochytrium_genomehub/import/blast/data:/import/blast \
           -e DATABASE=Hyphochytrium_catenoides_2017 \
           -e FLAGS="-e -j -i" \
           genomehubs/easy-import:17.03.23 &&
ls ~/hyphochytrium_genomehub/import/download/data/sequence/* 2> /dev/null &&


echo Step 5. Export sequences, export json and index database for mirrored Phytophthera ramorum &&
docker run --rm \
           -u $UID:$GROUPS \
           --name easy-import-phytophthora_ramorum_core_32_85_1 \
           --link hyphochytrium-mysql \
           -v ~/hyphochytrium_genomehub/import/hypho/conf:/import/hypho/conf \
           -v ~/hyphochytrium_genomehub/import/hypho/data:/import/hypho/data \
           -v ~/hyphochytrium_genomehub/import/download/data:/import/download \
           -v ~/hyphochytrium_genomehub/import/blast/data:/import/blast \
           -e DATABASE=phytophthora_ramorum_core_32_85_1 \
           -e FLAGS="-e -i -j" \
           genomehubs/easy-import:17.03.23 &&
ls ~/demo/genomehubs-import/download/data/sequence/Phy* 2> /dev/null &&


echo Step 7. Startup SequenceServer BLAST server &&

docker run -d \
           -u $UID:$GROUPS \
           --name hyphochytrium-sequenceserver \
           -v ~/hyphochytrium_genomehub/import/blast/conf:/conf \
           -v ~/hyphochytrium_genomehub/import/blast/data:/dbs \
           -p 8083:4567 \
           genomehubs/sequenceserver:17.03.23 &&



echo Step 9. Waiting for site to load &&

until $(curl --output /dev/null --silent --head --fail http://127.0.0.1:8081//i/placeholder.png); do
    printf '.'
    sleep 5
done &&

echo done &&

echo Visit your mirror site at 127.0.0.1:8081 &&

exit

echo Unable to set up GenomeHubs site, removing containers

docker stop hyphochytrium-mysql && docker rm hyphochytrium-mysql
docker stop hyphochytrium-ensembl && docker rm hyphochytrium-ensembl
#docker stop hyphochytrium-h5ai && docker rm genomehubs-h5ai
docker stop hyphochytrium-sequenceserver && docker rm hypochytrium-sequenceserver

