#!/bin/bash

LUAC=./3rd/lua/luac
mkdir -p bin

Luas=`find . -name "*.c"`
for file in $Luas
do
    rm $file
done

Luas=`find . -name "*.h"`
for file in $Luas
do
    rm $file
done