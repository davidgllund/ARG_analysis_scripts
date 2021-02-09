#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given a list of organism names, counts the number of unique names in the list and returns a file 
# containing each unique name and the number of times it occurred in the original list, in descending order.
#--------------------------------------------------------------------------------------------------------------------
# Import required packages
import sys
import numpy as np

# Import list of organism names
file1 = open(sys.argv[1], 'r')
organism_list = file1.readlines()
file1.close()

# Generate a list containing the unique organism names from the original list
unique_names = []

for name in organism_list:
    if name not in unique_names:
        unique_names.append(name)

# Initialize a corresponding vector to hold the number of occurences of each organism
number_of_occurrences = [0]*len(unique_names)

# Count the occurences of each organism
for i in range(len(organism_list)):
    for j in range(len(unique_names)):
        if organism_list[i] == unique_names[j]:
            number_of_occurrences[j] += 1

# Get a list of indices in descending order of which the organisms occur
index = np.argsort(-np.array(number_of_occurrences))

# Compile the information to be exported
species_information = []

for i in index:
    species_information.append(unique_names[i] + "_" + str(number_of_occurrences[i]))

# Write the species information into a new file
fileName = "species_information.txt"

stringToExport = ""

stringToExport += str(species_information)

try:
    fp = open(fileName, "w")
    fp.write(stringToExport)
    fp.close()
except IOError:
    print("Could not open species_information.txt")
sys.exit(1)



