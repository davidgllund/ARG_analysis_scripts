#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given a list of sequences in fasta-file to remove, a corresponding fasta-file, and the name of the 
# edited file, removes the specifies sequences from the original fasta-file. 
#--------------------------------------------------------------------------------------------------------------------
# Import required packages
import sys
from Bio import SeqIO
from sets import Set

# Function that removes the first character from the fasta headers
def list_ids():
    
    identifiers = Set([])
    
    with open(sys.argv[1], 'r') as fi:
        for line in fi:
            line = line.strip()
            identifiers.add(str(line).replace(">", ""))
            
    return identifiers

# Function that removes the specified sequences from the original fasta-file
def filter():
    identifiers = list_ids()
    
    with open(sys.argv[2]) as original_fasta, open(sys.argv[3], 'w') as corrected_fasta:
        records = SeqIO.parse(original_fasta, 'fasta')
        for record in records:
            if record.id not in identifiers:
                SeqIO.write(record, corrected_fasta, 'fasta')

# Apply functions
if __name__ == '__main__':
    filter()
