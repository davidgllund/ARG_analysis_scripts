#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given information from a BLAST output file (id of BLASTed sequence, name of best hit, and percent AA 
# identity), removes all hits that displayed a AA identity < 90%. 
#--------------------------------------------------------------------------------------------------------------------
import sys

# Define function that keeps only the entries that have an identity > 70%
def cross_reference(list1, identity):
    filtered_list = []

    for i in range(len(list1)):
        if float(identity[i].rstrip("\n")) > float(70.0):
            filtered_list.append(str(list1[i]))
            continue
        else:
            continue

    return filtered_list
            
# Import files
file1 = open(sys.argv[1], 'r')
headers = file1.readlines()
file1.close()

file2 = open(sys.argv[2], 'r')
names = file2.readlines()
file2.close()

file3 = open(sys.argv[3], 'r')
identity = file3.readlines()
file3.close()

# Apply the above function to both sequence ids and BLAST hit names
filtered_headers = cross_reference(headers, identity)
filtered_names = cross_reference(names, identity)

# Export filtered lists
string1 = ""
string2 = ""

fileName1 = "filtered_blast_headers.txt"
fileName2 = "filtered_blast_names.txt" 

for row in filtered_headers:
    string1 += str(row)

try:
    fp = open(fileName1, 'w')
    fp.write(string1)
    fp.close()
except IOError:
    print("Could not open filtered_blast_headers.txt")

for row in filtered_names:
    string2 += str(row)

try:
    fp = open(fileName2, 'w')
    fp.write(string2)
    fp.close()
except IOError:
    print("Could not open filtered_blast_names.txt")
sys.exit(1)
