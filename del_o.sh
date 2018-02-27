#!/bin/bash

LUAC=./3rd/lua/luac
mkdir -p bin

Luas=`find . -name "*.so"`
for file in $Luas
do
    rm $file
done

Luas=`find . -name "*.o"`
for file in $Luas
do
    rm $file
done