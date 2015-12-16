#!/bin/bash
DIRECTORY=~/Dropbox/Wallpaper/
PREFIX="CHECKED_"
REVIEW_FOLDER=Review
LOG=./auto_delete_log.txt

MIN_SIZE_IN_BYTES=200000 #200KB
MAX_SIZE_IN_BYTES=8000000 #8MB
MIN_WIDTH=1200
MIN_HEIGHT=600
MIN_RESOLUTION=72

function tagForReview {
	echo -e "${1}\t${2}" >> $LOG;
	mv $1 $REVIEW_FOLDER;
}
function tagForRemoval {
	echo -e "${1}\t${2}" >> $LOG;
	rm $1;
}
function floor {
	RETURN=$(python -c "from math import floor; print floor($1)")
	echo "${RETURN/\.0/""}"
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
	fullname=${PREFIX}${pruned}.${extension}
	mv $1 $fullname
}

FILE_COUNT=$(ls -B "$DIRECTORY" | wc -l)
echo "$FILE_COUNT files"

cd $DIRECTORY;
mkdir -p $REVIEW_FOLDER;
for f in *; 
	do 
	((COUNTER++))
	
	if [ -d "${f}" ] ; then
		continue;
	fi
	if [[ $f == ${PREFIX}* ]] ; then
		continue;
	fi

	SIZE_IN_BYTES=$(identify -format "%b" $f)
	SIZE_IN_BYTES="${SIZE_IN_BYTES/B/""}"
	WIDTH=$(identify -format "%w" $f)
	HEIGHT=$(identify -format "%h" $f)
	RESOLUTION=$(identify -format "%[resolution.x]" $f)
	RESOLUTION=$(floor $RESOLUTION)

	if [ "$WIDTH" -lt "$HEIGHT" ]; then
		tagForRemoval ${f} "Is portrait.";
	elif [ "$SIZE_IN_BYTES" -lt "$MIN_SIZE_IN_BYTES" ]; then
		tagForRemoval ${f} "Size too small.";
	elif [ "$SIZE_IN_BYTES" -gt "$MAX_SIZE_IN_BYTES" ]; then
		tagForReview ${f} "Size too big.";
	elif [ "$WIDTH" -lt "$MIN_WIDTH" ]; then
		tagForRemoval ${f} "Width too small. $WIDTH";
	elif [ "$HEIGHT" -lt "$MIN_HEIGHT" ]; then
		tagForRemoval ${f} "Height too small. $HEIGHT";
	elif [ "$RESOLUTION" -lt "$MIN_RESOLUTION" ]; then
		tagForReview ${f} "Resolution=${RESOLUTION}.";
	else
		echo "Processing $COUNTER/$FILE_COUNT..";
		tidyName ${f};
	fi
done

echo "Checking for duplicates..."
fdupes -r .