#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given a list of fasta-file headers, a fasta-file, and the name of the output file produced, 
# changes the headers of the original fasta to the new headers provided, and outputs the results as a new fasta-file.
#--------------------------------------------------------------------------------------------------------------------
# Import required packages
import sys
from Bio import SeqIO

# Import list of fasta headers
file1 = open(sys.argv[1], 'r')
new_ids = file1.readlines()
file1.close()

# Define "i" as a way to count iterations
i = 0

# Use SeqIO to overwrite previous fasta headers with new headers
with open(sys.argv[2]) as original_fasta, open(sys.argv[3], 'w') as corrected_fasta:
    records = SeqIO.parse(original_fasta, 'fasta')
    for record in records:
        record.id = new_ids[i]
        record.description = ""
        i += 1
        SeqIO.write(record, corrected_fasta, 'fasta')
