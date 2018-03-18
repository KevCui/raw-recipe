#!/bin/bash

source cookbook.sh

if [[ "$1" == "cook" || "$1" == "" ]];then
	fry
	wrap
	mix
fi

if [[ "$1" == "check" || "$1" == "" ]];then
	check
fi

if [[ "$1" == "clean" ]]; then
	clean
fi
