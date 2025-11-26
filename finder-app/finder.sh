#!/bin/sh

filesdir=$1
searchstr=$2

if [ $# -ne 2 ]; then
	echo "Error: invalid number of arguments. It should be 2: directory path and string"
	exit 1
fi


if [ ! -d "$filesdir" ]; then
	echo "Error: $filesdir is not a valid directory"
	exit 1
fi

file_count=$(find "$filesdir" -type f | wc -l)

#matching_lines=$(grep -r "$searchstr" "$filesdir" | wc -l)

#dont include binary files
#matching_lines=$(grep -rI "$searchstr" "$filesdir" | wc -l)

#including searches on binary files.
matching_lines=$(grep -rIa "$searchstr" "$filesdir" | wc -l)

echo "The number of files are $file_count and the number of matching lines are $matching_lines"

exit 0
