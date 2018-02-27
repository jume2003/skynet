#!/bin/bash

LUAC=./3rd/lua/luac
mkdir -p bin

Luas=`find . -name "*.lua"`
for file in $Luas
do
    filename=`basename $file`
    $LUAC -o bin/$filename $file
done