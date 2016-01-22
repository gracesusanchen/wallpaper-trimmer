#!/bin/bash
source ./config.sh

function tagForReview {
	echo -e "${1}\t${2}" >> $LOG;
	mv "$1" $review_folder_name;
}
function tagForRemoval {
	echo -e "${1}\t${2}" >> $LOG;
	rm "$1";
}
function floor {
	decimal=$(python -c "from math import floor; print floor($1)")
	echo "${decimal/\.0/""}"
}
function pruneName {
	# get rid of extra strings in filename
	# 1. file dimensions
	# 2. extra "x"es from removing file dimensions
	# 3. uselss "OC" label
	# 4. extra spaces
	# 5. extra underscores
	echo $1 | sed -E 's/([0-9]+x[0-9]+|[0-9]+)//g' | sed -E 's/_[[:alpha:]]{1}_//g' | sed -E 's/_OC*//g'  | sed -E 's/([-,_]+|[[:space:]]+)/_/g' | sed -E 's/(_+$|^_+)//g'
}
function tidyName {
	extension=$(echo ${1##*.})
	filename=$(echo ${1%.*})

	pruned=$(pruneName ${filename});
	fullname=${checked_file_prefix}${pruned}.${extension}
	mv "$1" $fullname
}

FILE_COUNT=$(ls -B "$directory" | wc -l)
echo "You currently have $FILE_COUNT wallpapers"

cd $directory;
mkdir -p $review_folder_name;
for f in *; 
	do 
	((COUNTER++))

	if [ -d "${f}" ] ; then
		continue;
	fi
	if [[ $f == ${checked_file_prefix}* ]] ; then
		continue;
	fi

	SIZE_IN_BYTES=$(identify -format "%b" "$f")
	SIZE_IN_BYTES="${SIZE_IN_BYTES/B/""}"
	WIDTH=$(identify -format "%w" "$f")
	HEIGHT=$(identify -format "%h" "$f")
	RESOLUTION=$(identify -format "%[resolution.x]" "$f")
	RESOLUTION=$(floor $RESOLUTION)

	if [ "$WIDTH" -lt "$HEIGHT" ]; then
		tagForRemoval "$f" "Is portrait.";
	elif [ "$SIZE_IN_BYTES" -lt "$MIN_SIZE_IN_BYTES" ]; then
		tagForRemoval "$f" "Size too small.";
	elif [ "$SIZE_IN_BYTES" -gt "$MAX_SIZE_IN_BYTES" ]; then
		tagForReview "$f" "Size too big.";
	elif [ "$WIDTH" -lt "$MIN_WIDTH" ]; then
		tagForRemoval "$f" "Width too small. $WIDTH";
	elif [ "$HEIGHT" -lt "$MIN_HEIGHT" ]; then
		tagForRemoval "$f" "Height too small. $HEIGHT";
	elif [ "$RESOLUTION" -lt "$MIN_RESOLUTION" ]; then
		tagForReview "$f" "Resolution=${RESOLUTION}.";
	else
		echo "Processing $COUNTER/$FILE_COUNT..";
		tidyName "$f";
	fi
done

echo "Removing duplicates..."
fdupes -r --delete .