#!/bin/bash

source cookbook.sh

if [[ "$1" == "cook" || "$1" == "" ]];then
    clean
	fry
	wrap
	mix
	check
    clean
fi

if [[ "$1" == "fry" ]]; then
    fry
fi

if [[ "$1" == "wrap" ]]; then
    wrap
fi

if [[ "$1" == "mix" ]]; then
    mix
fi

if [[ "$1" == "check" ]]; then
    check
fi

if [[ "$1" == "clean" ]]; then
	clean
fi
