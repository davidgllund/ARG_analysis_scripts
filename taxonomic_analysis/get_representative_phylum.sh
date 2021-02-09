#!/bin/bash
#--------------------------------------------------------------------------------------------------------------------
# Script that analyzes the taxonomic origin of gene clusters, and returns a representative phylum/metagenome for each
# cluster in the current directory.
#--------------------------------------------------------------------------------------------------------------------
# Extract accession ids corresponding to annotated plasmid sequences
grep -i 'plasmid' ../../metadata.txt | cut -f 2 > plasmid_ids.txt

# For each cluster, collect information about the species and accession ids in each cluster
for f in c_*; do
    grep '>' $f | grep -vi 'aac' | grep -v 'APH' | rev | cut -d '-' -f 1 | rev > list
    grep '>' $f | grep -vi 'aac' | grep -v 'APH' | cut -d '>' -f 2 | cut -d '.' -f 1 > ids

# Check if any of the accession ids represented in the cluster corresponds to an annotated plasmid sequence
    plasmid=$(echo "FALSE")
    
    while read i; do
	while read j; do
	    if [[ $i == $j ]]; then
		plasmid=$(echo "TRUE")
	    fi
	done<plasmid_ids.txt
    done<ids

    if [[ $plasmid == "TRUE" ]]; then
	echo "Mobile" >> phylum_list.txt
	echo "Mobile gene identified"
	continue
    fi

# Count how many sequences in each cluster that correspond to a specific phylum or metagenome
    python home/dlund/scripts/miscellaneous_scripts/summarize_list.py list summary.txt

    NA=$(grep 'NA' summary.txt | wc -l)
    meta=$(grep 'Metagenome' summary.txt | wc -l)
    size=$(less summary.txt | wc -l)
    top=$(head -1 summary.txt | cut -d ':' -f 1)
    second=$(head -2 summary.txt | tail -1 | cut -d ':' -f 1)
    third=$(head -3 summary.txt | tail -1 | cut -d ':' -f 1)
    
# Determine whether a gene family originates from a certain phylum. is mobile or only identified in metagenomes
    if [[ $top == "Metagenome" && $size == 2 && $NA == 1 ]]; then
        echo $top >> phylum_list.txt
	continue 
    elif [[ $top == "Metagenome" && $size == 2 && $NA == 0 ]]; then
	echo $second >> phylum_list.txt
	continue
    elif [[ $top == "NA" && size > 1 ]]; then
	echo $second >> phylum_list.txt
	continue
    elif [[ $second == "Metagenome" && $size == 2 && $NA == 1 ]]; then
	echo $second >> phylum_list.txt
	continue
    elif [[ $second == "Metagenome" && $size == 2 && $NA == 0 ]]; then
	echo $top >> phylum_list.txt
	continue
    elif [[ $size == 2 && $NA == 0 && $meta == 0 ]]; then
	echo "Mobile" >> phylum_list.txt
	continue
    elif [[ ($size == 3 && $NA == 0 && $meta == 1) || ($size == 3 && $NA == 1 && $meta == 0) || ($size == 3 && $NA == 0 && $meta == 0) ]]; then
	echo "Mobile" >> phylum_list.txt
	continue
    elif [[ $size > 3 ]]; then 
	echo "Mobile" >> phylum_list.txt
	continue
    else
	echo $top >> phylum_list.txt
	continue
    fi
done

# Remove auxilary files
rm plasmid_ids.txt
rm list
rm ids
rm summary.txt
