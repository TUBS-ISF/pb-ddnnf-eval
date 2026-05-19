#!/bin/bash

dimacs_file=$1

sed '/^c/d' < $dimacs_file | sed '/^p/d' | sed 's/0$//' | wc -w
