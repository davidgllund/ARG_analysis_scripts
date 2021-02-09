#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given the number of reference sequences each cluster, the size of the clusters, the name of the 
# clusters, the names of the reference sequence(s) in each cluster, and information about the species represented in
# each cluster, identifies the clusters that are only comprised of reference, that should thereby be removed. 
#--------------------------------------------------------------------------------------------------------------------
# Import required packages
import sys
import numpy as np

# Convert input files to correct formats
file1 = open(sys.argv[1], 'r')
hits = [int(line) for line in file1.readlines()]
file1.close()

file2 = open(sys.argv[2], 'r')
cluster_size = [int(line) for line in file2.readlines()]
file2.close()

file3 = open(sys.argv[3], 'r')
cluster_names = file3.readlines()
file3.close()

file4 = open(sys.argv[4], 'r')
known_genes = file4.readlines()
file4.close()

file5 = open(sys.argv[5], 'r')
species_information = file5.readlines()
file5.close()

# Initialize list to hold names of gene clusters to remove
genes_not_present = []

# Initialize lists to hold sizes, known gene names and species of origin of the clusters that remain after filtering
cluster_sizes_filtered = []
known_genes_filtered = []
species_information_filtered = []

# Collect names of clusters not present in dataset
for i in range(len(hits)):
    if int(hits[i]) == int(cluster_size[i]):
        genes_not_present.append(cluster_names[i])
    else:
        cluster_sizes_filtered.append(str(cluster_size[i]) + "\n")
        known_genes_filtered.append(known_genes[i])
        species_information_filtered.append(species_information[i])
    

# Export the list of genes not present, along with the sizes of the clusters that will not be removed and the list of known genes present within the clusters that will not be removed.
stringToExport1 = ""
stringToExport2 = ""
stringToExport3 = ""
stringToExport4 = ""

for row in genes_not_present:
    stringToExport1 += str(row)

filename1 = "genes_not_present.txt"

try:
    fp = open(filename1, "w")
    fp.write(stringToExport1)
    fp.close
except IOError:
    print("Could not open genes_not_present.txt")

for row in known_genes_filtered:
    stringToExport2 += str(row)

filename2 = "known_genes_in_cluster.txt"

try:
    fp = open(filename2, "w")
    fp.write(stringToExport2)
    fp.close()
except IOError:
    print("Could not open known_genes_in_cluster.txt")

for row in cluster_sizes_filtered:
    stringToExport3 += str(row)

filename3 = "cluster_sizes_filtered.txt"

try:
    fp = open(filename3, "w")
    fp.write(stringToExport3)
    fp.close()
except IOError:
    print("Could not open cluster_sizes_filtered.txt")

filename4 = "species_information_filtered.txt"

for row in species_information_filtered:
    stringToExport4 += str(row)

try:
    fp = open(filename4, 'w')
    fp.write(stringToExport4)
    fp.close()
except IOError:
    print("Could not open species_information_filtered.txt")
sys.exit(1)
