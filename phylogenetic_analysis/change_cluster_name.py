#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given the names of known genes in each cluster, the size of each cluster, and information about the
# species represented in each cluster, generates new fasta headers that reflect this information and replaces the 
# previous fasta headers with these.
#--------------------------------------------------------------------------------------------------------------------
# Import required packages
import sys
from Bio import SeqIO
from sets import Set

# Import files
file1 = open(sys.argv[1], 'r')
known_genes = file1.readlines()
file1.close()

file2 = open(sys.argv[2], 'r')
cluster_size = file2.readlines()
file2.close()

file3 = open(sys.argv[3], 'r')
species_information = file3.readlines()
file3.close()

# Generate new fasta headers 
new_ids = []
j = 1

for i in range(len(cluster_size)):
    known_genes[i] = known_genes[i].replace('\n', '')
    cluster_size[i] = cluster_size[i].replace('\n', '')
    if known_genes[i] == "Unknown":
        new_ids.append("Unknown_Gene_Family" + "_" + str(j) + "_" + "#" + cluster_size[i] + "_" + species_information[i])
        j += 1
    elif known_genes[i] == "Unknown mobile":
        new_ids.append("Unknown_Gene_Family_Mobile" + "_" + str(j) + "_" + "#" + cluster_size[i] + " " + species_information[i])
        j += 1
    else:
        new_ids.append(known_genes[i] + "_" + "#" + str(int(cluster_size[i])-1) + "_" + species_information[i])
i = 0

# Overwrite the headers in the original fasta with the newly generated headers
with open(sys.argv[4]) as original_fasta, open(sys.argv[5], 'w') as corrected_fasta:
    records = SeqIO.parse(original_fasta, 'fasta')
    for record in records:
        record.id = new_ids[i]
        record.description = ""
        i += 1
        SeqIO.write(record, corrected_fasta, 'fasta')
