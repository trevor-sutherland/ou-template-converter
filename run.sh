#!/bin/bash

site="fulbright"
site_map="fulbright"
files=`find . -iname "*.pcf"`
props=`find . -name "_props.pcf"`
directory=`find . -path "*/directory/*.pcf"`

mkdir converted && mkdir out
#Run script on all .pcf files except 
./ou-convert --map maps/$site_map.map --tmpl tmpl/interior.tmpl --ignore "_props.pcf" $files
cd out && zip -r $site.zip $site && cp $site.zip ../converted && cd .. && rm -r out

#Run script on _props.pcfs only
./ou-convert --map maps/_props.map --tmpl tmpl/_props.tmpl --ignore "trash" $props
cd out && zip -r _props.zip $site && cp  _props.zip ../converted && cd .. && rm -r out

#Run script on directory
./ou-convert --map maps/interior-directory.map --tmpl tmpl/interior-directory.tmpl --ignore "_props.pcf" $directory
cd out && zip -r directory.zip $site && cp  directory.zip ../converted