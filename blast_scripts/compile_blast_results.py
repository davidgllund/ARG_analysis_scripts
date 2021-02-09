#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given fasta file headers, headers corresponding to entries that showed AA identity > 79% during BLAST,
# and the names of teh corresponding BLAST hits, returns a list of equal length, and corresponding to the original 
# fasta headers.
#--------------------------------------------------------------------------------------------------------------------
# Import required packages
import re
import sys

# Define function that for each entry in list, generates a new list with the corresponding BLAST hit of "Unknown"
def cross_reference(list1, list2, list3):
    blast_summary = []
    for i in range(len(list1)):
        if list1[i] not in list2:
            blast_summary.append("Unknown\n")
            continue

        else:
            for j in range(len(list2)):
                hit = re.search(list1[i], list2[j])
                if hit is None:
                    continue
                elif hit.group() is list2[j]:
                    blast_summary.append(list3[j])
                    break
    return blast_summary

# Import files
file1 = open(sys.argv[1], 'r')
headers = file1.readlines()
file1.close()

file2 = open(sys.argv[2], 'r')
blast_hit_headers = file2.readlines()
file2.close()

file3 = open(sys.argv[3], 'r')
blast_hit_names = file3.readlines()
file3.close()

# Apply function
blast_summary = cross_reference(headers, blast_hit_headers, blast_hit_names)

# Export file
fileName = "blast_summary.txt"

stringToExport = ""

for row in blast_summary:
    stringToExport += str(row)

try:
    fp = open(fileName, "w")
    fp.write(stringToExport)
    fp.close()
except IOError:
    print("Could not open blast_summary.txt")
sys.exit(1)
