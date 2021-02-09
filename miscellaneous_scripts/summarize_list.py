#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given a list, counts the number of unique entries in the list and returns a file containing the unique
# entries and the number of times they appear in the original list, sorted in descending order
#--------------------------------------------------------------------------------------------------------------------
# Import required packages
import matplotlib.pyplot as plt
import numpy as np
import sys

# Import list
file1 = open(sys.argv[1], 'r')
list_of_interest = file1.readlines()
file1.close()

# Initialize an empty list of unique names
unique_names = []

# Fill the list with all unique names from the list
for name in list_of_interest:
    if name not in unique_names:
        unique_names.append(name)

# Initialize a corresponding vector to fill with the number of time each unique organism occur in the list
number_of_occurrences = [0]*len(unique_names)

# Count the number of time each name appears in the original list
for i in range(len(list_of_interest)):
    for j in range(len(unique_names)):
        if list_of_interest[i] == unique_names[j]:
            number_of_occurrences[j] += 1

index = np.argsort(-np.array(number_of_occurrences))

names_and_occurrences = []

for i in index:
    names_and_occurrences.append(unique_names[i].rstrip() + ": " + str(number_of_occurrences[i]) + "\n")

stringToExport = ""

for row in names_and_occurrences:
    stringToExport += str(row)

fileName = sys.argv[2]

# Check if successfully exported
try:
    fp = open(fileName, "w")
    fp.write(stringToExport)
    fp.close()
except IOError:
    print("Could not open file")
sys.exit(1)

