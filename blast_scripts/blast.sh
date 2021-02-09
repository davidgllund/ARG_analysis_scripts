#!/bin/bash
#--------------------------------------------------------------------------------------------------------------------
# Script that BLASTs a fasta file against a reference database of ARGs, and returns the best hit for each sequence, 
# given that there was a hit with identity > 70%.
#--------------------------------------------------------------------------------------------------------------------
# BLAST the file of choice against the reference ARG sequences.
blastp -query predicted-orfs-genomic.fasta -out blastout.txt -db /home/dlund/blast_db/reference_ARGs.fsa -outfmt 7 -max_target_seqs 1

# Extract information form the BLAST output file
grep '>' predicted-orfs-genomic.fasta | cut -d '>' -f 2 | cut -d '_' -f 2,3 > headers.txt

grep -v '^#' blastout.txt | cut -f 1 | cut -d '_' -f 2,3 > blast_headers.txt
grep -v '^#' blastout.txt | cut -f 2 > blast_names.txt
grep -v '^#' blastout.txt | cut -f 3 > perc_identity.txt

# Filter away any hits that show AA identity < 70%
python home/dlund/scripts/blast_scripts/filter_blast_results.py blast_headers.txt blast_names.txt perc_identity.txt

# Compile the results into a list of proper length
python home/dlund/scripts/blast_scripts/compile_blast_results.py headers.txt filtered_blast_headers.txt filtered_blast_names.txt

# Remove temporary files
rm headers.txt blast_headers.txt blast_names.txt perc_identity.txt filtered_blast_headers.txt filtered_blast_names.txt blastout.txt
