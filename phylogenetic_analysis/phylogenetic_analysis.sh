#!/bin/bash
# This script is used to perform phylogenetic analysis of macrolide or aminoglycoside resistance gene sequences predicted by the fARGene software, clustered into gene families at 70% AA similarity. 

# The following input files are used by the script:
# - predicted-orfs-genomic.fasta: Fasta file containing protein sequences identified in genomic data in standard fARGene output format.
# - predicted-orfs-meta.fasta: Fasta file containing protein sequences identified in metagenomic data in standard fARGene output format (optional).
# - species.txt: List of species from which the sequences in 'predicted-orfs-genomic.fasta' correspond.
# - phylum.txt: List of phyla from which the sequences in 'predicted-orfs-genomic.fasta' correspond.
# - lablels.txt: List of metagenomes from which the sequences in 'predicted-orfs-meta.fasta' correspond (optional).
# - known_ARGs.fasta: Fasta file containing protein sequences representing known antibiotic resistance genes.

# The script produces the following output:
# - gene_familes.fasta: Fasta file containing the centroid sequecnes of the produced gene families, the headerlines contain information about the taxonomy of each family.
# - tree.txt: Phylogentic tree in Newick-format, created from gene_families.fasta with an appropriate outgroup included based on the type of ARG that the analysis concerns.
# - files_for_plotting/: Directory containing 4 files that are required to run the script phylogenetic_analysis.R in the visualization/ directory.

#--------------------------------------------------------------------------------------------------------------------
# 0.1 Manual inputs
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
#--------------------------------------------------------------------------------------------------------------------
# 1. GENERATE DETAILED DESCRIPTION OF PHYLOGENY
#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------
# 1.1 Preparation of files
#--------------------------------------------------------------------------------------------------------------------
# Change fasta headers to include the taxonomy of the identified host
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
rm headers_genomic.txt headers_meta.txt adjusted-orfs-genomic.fasta adjusted-orfs-meta.fasta
#--------------------------------------------------------------------------------------------------------------------
# 1.2 Cluster sequences
#--------------------------------------------------------------------------------------------------------------------
# Add known ARG sequences before clustering
cat predicted-orfs-combined.fasta /home/dlund/index_files/known_ARGs.fasta > novel_and_known_genes.fasta

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
# 1.3 Collect information about the contents of each gene family
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
# 1.4 Create phylogenetic tree
#--------------------------------------------------------------------------------------------------------------------
echo "Creating phylogenetic tree"

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
mafft seqs_to_align.fasta > alignment.aln

# Create phylogenetic tree from the alignment using FastTree
fasttree alignment.aln > messy_tree.txt

# Edit the tip labels in the newick tree file
sed 's/\\n/ /g' messy_tree.txt | tr -d "'" > tree.txt

# Delete remaining auxilary files
    rm seqs_to_align.fasta alignment.aln messy_tree.txt novel_and_known_genes.fasta species_summary.txt genes_present.txt cluster_sizes.txt cluster_names.txt known_names.txt gene_families_filtered.fasta gene_families_names_adjusted.fasta genes_not_present.txt known_genes_in_cluster.txt species_information_filtered.txt cluster_sizes_filtered.txt

#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------
# GENERATE FILES FOR VISUALIZING PHYLOGENY
#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------
# 2.1 Preparation of files
#--------------------------------------------------------------------------------------------------------------------
echo "Creating files for visualization of results"

# Create directory to store output files
mkdir files_for_plotting

# Change fasta headers to include the taxonomy of the identified host
if [[ -f predicted-orfs-genomic.fasta && -f species.txt ]]; then
    paste -d '-' ids_genomic.txt phylum.txt > headers_genomic.txt
    python /home/dlund/scripts/miscellaneous_scripts/change_fasta_headers.py headers_genomic.txt predicted-orfs-genomic.fasta adjusted-orfs-genomic.fasta
fi

if [[ -f predicted-orfs-meta.fasta && -f labels.txt ]]; then
    python /home/dlund/scripts/miscellaneous_scripts/make_labels.py labels.txt 'Metagenome' meta_list.txt
    paste -d '-' ids_meta.txt meta_list.txt > headers_meta.txt
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

# Delete auxiliary files
rm ids_genomic.txt headers_genomic.txt ids_meta.txt headers_meta.txt adjusted-orfs-genomic.fasta adjusted-orfs-meta.fasta meta_list.txt

#--------------------------------------------------------------------------------------------------------------------
# 2.2 Generate files describing predicted gene families
#--------------------------------------------------------------------------------------------------------------------
# Add known ARG sequences before clustering
cat predicted-orfs-combined.fasta /home/dlund/index_files/known_ARGs.fasta > novel_and_known_genes.fasta

# Make new directory and store files containing all sequences that were assigned to each gene family
mkdir cluster_dir
usearch -cluster_fast novel_and_known_genes.fasta -id 0.7 -clusters cluster_dir/c_

cd cluster_dir

# Fix the filenames such that order of files in cluster dir corresponds to order of sequences in gene_families.fasta
ls | sed -r 's/^([^0-9]*)([0-9]*)(.*)/printf "mv -v '\''&'\'' '\''%s%04d%s'\''" "\1" "\2" "\3"/e;e' > /dev/null

# Remove clusters containing only reference sequences
for cluster in *; do
    hits=$(cat $cluster | grep '>' | grep -v '_seq' | wc -l)
    rows=$(cat $cluster | grep '>' | wc -l)

    if [[ $hits == $rows ]]; then 
	rm $cluster
    fi
done

# Compile ids from the representative sequence of each cluster and save the results 
for cluster in *;
do
    grep '>' $cluster | grep '_seq' | head -1 | cut -d '>' -f 2 | cut -d '-' -f 1 >> headers.txt
done

mv headers.txt ../files_for_plotting/

# Identify the representative phylum of each cluster and save the results
source /home/dlund/scripts/taxonomic_analysis/get_representative_phylum.sh
python /home/dlund/scritps/taxonomic_analysis/simplify_phylum_list.py

mv phylum_list.txt ../files_for_plotting/phylum.txt
cd ..

# Delete the cluster directory
rm -r cluster_dir

# Compile list indicating which gene families represent known ARGs and save the results
grep '>' gene_families.fasta | cut -d '>' -f 2 | cut -d '#' -f 1 > lines.txt
while read line;
do 
    hit=$(echo $line | grep 'Unknown' | wc -l)

    if [[ $hit == "1" ]]; then 
	echo 'NA' >> files_for_plotting/names.txt
    else 
	echo $line | tr '_' '-' >> files_for_plotting/names.txt
    fi
done<lines.txt

#--------------------------------------------------------------------------------------------------------------------
# 2.3 Create phylogenetic tree
#--------------------------------------------------------------------------------------------------------------------
# Add the representative ids from headers.txt to gene_families.fasta
python /home/dlund/scripts/miscellaneous_scripts/change_fasta_headers.py files_for_plotting/headers.txt gene_families.fasta fams.fasta

# Add outgroup before alignment
if [[ $genetype == "aac" ]]; then
    cat fams.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/AACs/GNAT_outgroup.fasta > seqs_to_align.fasta

elif [[ $genetype == "aph" ]]; then
    cat fams.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/APHs/mph.fasta > seqs_to_align.fasta

elif [[ $genetype == "rmt" ]]; then
    cat fams.fasta /home/dlund/aminoglycoside_project/resistance_gene_sequences/16S_RMTs/erm.fasta > seqs_to_align.fasta

elif [[ $genetype == "erm" ]]; then
    cat fams.fasta /storage/dlund/macrolide_resistance_project/resistance_gene_sequences/misclassified_ksgA.fasta > seqs_to_align.fasta

elif [[ $genetype == "mph" ]]; then
    cat fams.fasta /storage/dlund/macrolide_resistance_project/resistance_gene_sequences/APH2.fasta > seqs_to_align.fasta
fi

# Create multiple sequence alignment using mafft
mafft seqs_to_align.fasta > alignment.aln

# Create phylogenetic tree usign FastTree
fasttree alignment.aln > files_for_plotting/tree.txt

# Remove remaining auxiliary files
rm alignment.aln seqs_to_align.fasta lines.txt fams.fasta novel_and_known_genes.fasta predicted-orfs-combined.fasta
