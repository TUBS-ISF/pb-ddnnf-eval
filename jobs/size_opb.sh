#!/bin/bash

opb_file=$1

sed '/^#/d' < $opb_file | grep -o "\"[^\"]*\"" | wc -w
