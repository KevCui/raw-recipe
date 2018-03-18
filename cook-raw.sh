#!/bin/bash

source cookbook.sh

if [[ "$1" == "cook" || "$1" == "" ]];then
    clean
	fry
	wrap
	mix
	check
fi

if [[ "$1" == "cooked" ]]; then
    clean
    fry "recipe"
    wrap "recipe"
    mix "-cooked"
    check "-cooked"
fi

if [[ "$1" == "fry" ]]; then
    fry $2
fi

if [[ "$1" == "wrap" ]]; then
    wrap $2
fi

if [[ "$1" == "mix" ]]; then
    mix $2
fi

if [[ "$1" == "check" ]]; then
    check $2
fi

if [[ "$1" == "clean" ]]; then
	clean
fi

if [[ "$1" == "unwrap" ]]; then
    unwrap
fi
