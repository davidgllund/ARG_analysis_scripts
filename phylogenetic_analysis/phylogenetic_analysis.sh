#!/bin/bash
# This script creates phylogenetic trees from genomic and metagenomic data.
# To run the script, you need the following files in the current directory:
# - predicted-orfs-genomic.fasta: Fasta file containing the protein sequences identified in genomic data
# - predicted-orfs-meta.fasta: Fasta file containing the protein sequences identified in metagenomic data
# - species.txt: List of species from which the entries in 'predicted-orfs-genomic.fasta' correspond
# - lablels.txt: List of metagenomes from which the entries in 'predicted-orfs-meta.fasta' correspond

#--------------------------------------------------------------------------------------------------------------------
# Manual inputs
#--------------------------------------------------------------------------------------------------------------------
# Define the type of gene you are analyzing
echo "Input the type of genes you are analyzing (aac/aph/rmt/erm/mph), and then press [ENTER]:"
read genetype

if [[ $genetype == "aac" || $genetype == "aph" || $genetype == "rmt" || $genetype == "erm" || $genetype == "mph" ]]; then
    echo "Preparing to analyze $genetype gene sequences"
else
    echo "Genetype not recognized. Please input a valid genetype (aac/aph/rmt/erm/mph)."
    exit 1
fi
#--------------------------------------------------------------------------------------------------------------------
# Preparation of files
#--------------------------------------------------------------------------------------------------------------------
# Change headers in the two fasta files to include species/metagenome of origin
if [[ -f predicted-orfs-genomic.fasta && -f species.txt ]]; then
    grep '>' predicted-orfs-genomic.fasta | cut -d '_' -f 2,3 > ids_genomic.txt
    paste -d '-' ids_genomic.txt species.txt > headers_genomic.txt
    python /home/dlund/scripts/miscellaneous_scripts/change_fasta_headers.py headers_genomic.txt predicted-orfs-genomic.fasta adjusted-orfs-genomic.fasta
fi

if [[ -f predicted-orfs-meta.fasta && -f labels.txt ]]; then
    grep '>' predicted-orfs-meta.fasta | cut -d '|' -f 2 | cut -d ':' -f 1 > ids_meta.txt
    paste -d '-' ids_meta.txt labels.txt > headers_meta.txt
    python /home/dlund/scripts/miscellaneous_scripts/change_fasta_headers.py headers_meta.txt predicted-orfs-meta.fasta adjusted-orfs-meta.fasta
fi

# Combine genomic and metagenomic data (if both are present) into a single fasta file
if [[ -f adjusted-orfs-genomic.fasta && -f adjusted-orfs-meta.fasta ]]; then
    cat adjusted-orfs-genomic.fasta adjusted-orfs-meta.fasta > predicted-orfs-combined.fasta
 
elif [[ -f adjusted-orfs-genomic.fasta && ! -f adjusted-orfs-meta.fasta ]]; then
    cat adjusted-orfs-genomic.fasta > predicted-orfs-combined.fasta

elif [[ ! -f adjusted-orfs-genomic.fasta && -f adjusted-orfs-meta.fasta ]]; then
    cat adjusted-orfs-meta > predicted-orfs-combined.fasta
fi

# Delete auxilary files
rm ids_genomic.txt headers_genomic.txt ids_meta.txt headers_meta.txt adjusted-orfs-genomic.fasta adjusted-orfs-meta.fasta
#--------------------------------------------------------------------------------------------------------------------
# Cluster sequences
#--------------------------------------------------------------------------------------------------------------------
# Add known macrolide ARG sequences before clustering
    if [[ $genetype == "aac" ]]; then
	cat predicted-orfs-combined.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/AACs/AAC_enzymes.fasta > novel_and_known_genes.fasta
    
    elif [[ $genetype == "aph" ]]; then
	cat predicted-orfs-combined.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/APHs/APH_enzymes.fasta > novel_and_known_genes.fasta

    elif [[ $genetype == "rmt" ]]; then
	cat predicted-orfs-combined.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/16S_RMTs/16S_RMTs_adj.fasta > novel_and_known_genes.fasta

    elif [[ $genetype == "erm" ]]; then
	cat predicted-orfs-combined.fasta /storage/dlund/macrolide_resistance_project/resistance_gene_sequences/23S_rRNA_methyltransferases.fasta > novel_and_known_genes.fasta

    elif [[ $genetype == "mph" ]]; then
	cat predicted-orfs-combined.fasta /storage/dlund/macrolide_resistance_project/resistance_gene_sequences/macrolide_phosphotransferases.fasta > novel_and_known_genes.fasta
    fi

# Get representative centroid sequences of gene families sharing < 70% AA similarity
    usearch -cluster_fast novel_and_known_genes.fasta -id 0.7 -centroids gene_families.fasta

# Make new directory and store files containing all sequences that were assigned to each gene family
    mkdir cluster_dir
    usearch -cluster_fast novel_and_known_genes.fasta -id 0.7 -clusters cluster_dir/c_

# Fix the filenames such that order of files in cluster dir corresponds to order of sequences in gene_families.fasta
    cd cluster_dir
    ls | sed -r 's/^([^0-9]*)([0-9]*)(.*)/printf "mv -v '\''&'\'' '\''%s%04d%s'\''" "\1" "\2" "\3"/e;e' > /dev/null
    cd ..
#--------------------------------------------------------------------------------------------------------------------
# Collect information about the contents of each gene family
#--------------------------------------------------------------------------------------------------------------------
    echo "Compiling information about gene families"

# For each gene family, compile information about species/metagenome of origin and whether or not it is mobile
    for cluster in cluster_dir/*
    do

# Extract the name of the gene family from blast_summary.txt
	known_genes=$(grep '>' "$cluster" | grep -v '_seq' | wc -l)

# Check if cluster contains sequence(s) found on annotated plasmid
	grep '>' $cluster | cut -d '>' -f 2 | cut -d '.' -f 1 > ids.txt

# Compile information about cluster
	cluster_size=$(grep '>' "$cluster" | wc -l)
	cluster_name=$(grep '>' "$cluster" | head -1)

	echo "$known_genes" >> genes_present.txt
	echo "$cluster_size" >> cluster_sizes.txt
	echo "$cluster_name" >> cluster_names.txt
	
	if [[ $known_genes == "0" ]]; then
	    echo "Unknown" >> known_names.txt

	elif [[ $known_genes == "1" ]]; then
	    grep '>' "$cluster" | grep -v '_seq' | cut -d '>' -f 2 >> known_names.txt
	
	elif [[ $known_genes != "1" ]] && [[ $known_genes != "0" ]]; then
	    grep '>' "$cluster" | grep -v '_seq' | cut -d '>' -f 2 | cut -d ' ' -f 1 | tr '\n' '/' >> known_names.txt
	    echo "\n" >> known_names.txt
	fi

# Extract the species/metagenomes where sequences from the gene family were identified
	grep '>' "$cluster" | cut -d '-' -f 2 > source.txt
	grep '>' "$cluster" | cut -d '>' -f 2 | cut -d '.' -f 1 > ids.txt

# Count the hits in each species/metagenome
	python /home/dlund/scripts/phylogenetic_analysis/summarize_species.py source.txt

	cat species_information.txt  >> species_summary.txt
	echo "\n" >> species_summary.txt

# Delete auxilary files
	rm species_information.txt ids.txt
    done

# Identify and remove clusters that only contain reference sequences
    python /home/dlund/scripts/phylogenetic_analysis/find_clusters_to_remove.py genes_present.txt cluster_sizes.txt cluster_names.txt known_names.txt species_summary.txt

    python /home/dlund/scripts/phylogenetic_analysis/remove_gene_families.py genes_not_present.txt gene_families.fasta gene_families_filtered.fasta

# Change headers of gene families to reflect contents of cluster
    python /home/dlund/scripts/phylogenetic_analysis/change_cluster_name.py known_genes_in_cluster.txt cluster_sizes_filtered.txt species_information_filtered.txt gene_families_filtered.fasta gene_families_names_adjusted.fasta

    sed 's/\[//g' gene_families_names_adjusted.fasta | sed 's/\]//g' | tr ', ' '_' > gene_families_correct_headers.fasta

# Delete auxilary files and directories
    rm predicted-orfs-combined.fasta gene.txt ids.txt new_header.txt cluster_headers.txt number.txt source.txt species_information.txt gene_families.fasta
    rm -r cluster_dir

# Change name of the previously created fasta file (as it will be saved)
    mv gene_families_correct_headers.fasta gene_families.fasta
    
#--------------------------------------------------------------------------------------------------------------------
# Create phylogenetic tree
#--------------------------------------------------------------------------------------------------------------------
    echo "Creating phylogenetic tree"

# Activate standard conda environment
    source activate MVEX60

# Add outgroup before alignment
    if [[ $genetype == "aac" ]]; then
	cat gene_families.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/AACs/GNAT_outgroup.fasta > seqs_to_align.fasta
    
    elif [[ $genetype == "aph" ]]; then
	cat gene_families.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/APHs/mph.fasta > seqs_to_align.fasta
    
    elif [[ $genetype == "rmt" ]]; then
	cat gene_families.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/16S_RMTs/erm.fasta > seqs_to_align.fasta

    elif [[ $genetype == "erm" ]]; then
	cat gene_families.fasta /storage/dlund/macrolide_resistance_project/resistance_gene_sequences/misclassified_ksgA.fasta > seqs_to_align.fasta

    elif [[ $genetype == "mph" ]]; then
	cat gene_families.fasta /storage/dlund/macrolide_resistance_project/resistance_gene_sequences/APH2.fasta > seqs_to_align.fasta
    fi

# Create multiple sequence alignment using mafft
    mafft seqs_to_align.fasta > alignment.fasta

# Create phylogenetic tree from the alignment using FastTree
    FastTree alignment.fasta > messy_tree.txt

# Edit the tip labels in the newick tree file
    sed 's/\\n/ /g' messy_tree.txt | tr -d "'" > "$genetype"_tree.txt

# Delete remaining auxilary files
    rm seqs_to_align.fasta alignment.fasta messy_tree.txt novel_and_known_genes.fasta species_summary.txt genes_present.txt cluster_sizes.txt cluster_names.txt known_names.txt gene_families_filtered.fasta gene_families_names_adjusted.fasta genes_not_present.txt known_genes_in_cluster.txt species_information_filtered.txt cluster_sizes_filtered.txt
