#!/bin/bash
set -evx
CUR_PWD=`pwd`
echo '[build nz tiles map] [begin]'

# 初始化 minio
mc alias set nz $MINIO_HOST $MINIO_USER $MINIO_PWD

# dependency
MBUTIL_PKG="mbutil-0.3.0.tar.gz"
TILEMAKER_PKG="tilemaker-2.4.0.docker-image.tar.gz"

# source filename
SOURCE_OSM_PBF_FILE="china-latest.osm.pbf"

# output filename
OUTPUT_FILE_NAME="china-8-11-tiles.tar.gz"

mc cp nz/depends/tilemaker/$MBUTIL_PKG ./
mc cp nz/depends/tilemaker/$TILEMAKER_PKG ./
mc cp nz/depends/map/$SOURCE_OSM_PBF_FILE ./


# tilemaker
echo '[load docker images] [begin] [name: tilemaker]'
docker load -i $TILEMAKER_PKG
echo '[load docker images] [finshed]'

# mbutil
echo '[decompression mbutil pkg] [begin]'
tar -zxvf $MBUTIL_PKG
echo '[decompression
 mbutil pkg] [finshed]'

ls -hl $CUR_PWD
ls -hl $CUR_PWD/tools

# osm.pbf -> osm.mbtiles
echo '[build osm.mbtiles file] [begin]'
docker run --rm \
-v $CUR_PWD:$CUR_PWD \
--user $(id -u):$(id -g) tilemaker \
--config $CUR_PWD/tools/config.json --process $CUR_PWD/tools/process.lua \
--input $CUR_PWD/$SOURCE_OSM_PBF_FILE --output $CUR_PWD/temp.osm.mbtiles

ls -hl $CUR_PWD/temp.osm.mbtiles
echo '[build osm.mbtiles file] [finshed]'

# osm.mbtiles -> pbf
echo '[export an mbtiles file] [begin] [directory: mbutil/work]'
rm -rf $CUR_PWD/mbutil/work
sh $CUR_PWD/mbutil/mb-util --image_format=pbf  $CUR_PWD/temp.osm.mbtiles $CUR_PWD/mbutil/work

sh $CUR_PWD/tools/ungzip-pbf.sh $CUR_PWD/mbutil/work

echo '[export an mbtiles file] [finshed]'

tar -zcf $OUTPUT_FILE_NAME -C $CUR_PWD/mbutil/work .

md5sum $OUTPUT_FILE_NAME > $OUTPUT_FILE_NAME.md5sum.txt

# 上传编译的rpm 文件
mc cp $OUTPUT_FILE_NAME nz/release/tiles-map/$OUTPUT_FILE_NAME
mc cp $OUTPUT_FILE_NAME.md5sum.txt nz/release/tiles-map/$OUTPUT_FILE_NAME.md5sum.txt

echo '[build nz tiles map] [finshed]'
