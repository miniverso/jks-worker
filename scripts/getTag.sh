#!/bin/bash
tag=`git tag --sort version:refname | tail -1 | cut -c 2-`
IFS='.' tags=( $tag )

case $1 in
  1) echo "${tags[0]}" ;;
  2) echo "${tags[0]}.${tags[1]}" ;;
  *) echo "${tags[0]}.${tags[1]}.${tags[2]}" ;;
esac
