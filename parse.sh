#!/usr/bin/env sh

if [ $# != 2 ]
then exit 1
fi

output_file=gid_tid.csv

gzip -d $1 -k -f
tag_file=${1%.gz}

echo applying tag rename workaround...
sh workaround.sh "${tag_file}"

(
	echo start processing gid-tid...
	cat "${tag_file}" |
	  grep -E '^\(.*\)[,;]$' |
	  tr -cd '[0-9] \n' |
	  grep -v '^$' |
	  awk -F" " '{ print $2 }' |
	  sort -n -r |
	  uniq -c |
	  sed 's/^\s*//g;s/ /,/' |
	  awk -F, '{ print $2 "," $1 }' |
	  sort -k 1b,1 -t ',' > tid_count.csv &
	 
	echo start processing tag...
	zcat "$2" |
	  grep -E '^\(.*\)[,;]$' |
	  tr -d "();" |
	  sed 's![,;]$!!;s!, !,!' |
	  sort -k 1b,1 -t ',' > tid_tag.csv &
	  
	wait
)

echo merging tid-count-tag...
join -t ',' tid_count.csv tid_tag.csv > tid_count_tag.csv

(
	echo resorting files...
	for file in {tid_count,tid_tag,tid_count_tag}.csv
	do
	sort -t ',' -k 1 -n -o $file $file &
	done

	wait
)

for file in {tid_count,tid_tag,tid_count_tag}.csv
do
  echo start compressing tid-$file...
  gzip $file -f &
done
