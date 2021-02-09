#!/usr/bin/env python

import sys
import re

def simplify_list(list1, query1):
    simplified_list = []

    for i in range(len(list1)):

        for j in range(len(query1)):
            
            hit = re.search(query1[j], list1[i])

            if hit is None and j < (len(query1)-1):
                continue
            elif hit is not None:
                simplified_list.append(hit.group() + "\n")
                break
            elif hit is None and j == (len(query1)-1):
                simplified_list.append("Miscellaneous\n")
                break

    return simplified_list

file1 = open(sys.argv[1], 'r')
phylum_list = file1.readlines()
file1.close()

query = ["Actinobacteria", "Firmicutes", "Bacteroidetes", "Proteobacteria", "NA", "Metagenome", "Mobile"]

simplified_phyla = simplify_list(phylum_list, query)

fileName = "simplified_phyla.txt"

stringToExport = ""

for row in simplified_phyla:
    stringToExport += str(row)

try:
    fp = open(fileName, 'w')
    fp.write(stringToExport)
    fp.close()
except IOError:
    print("Could not open simplified_phyla.txt")
sys.exit(1)
