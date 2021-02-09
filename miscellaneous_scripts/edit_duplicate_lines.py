#!/usr/bin/env python
#--------------------------------------------------------------------------------------------------------------------
# Script that, given a list, returns the same list, where duplicate lines have been edited by adding an extention.
#--------------------------------------------------------------------------------------------------------------------
# Import required package
import sys

# Import list
file1 = open(sys.argv[1], 'r')
arbitrary_list  = file1.readlines()
file1.close()


# For each entry in the list, identify if its a duplicate of a previous line, and if so add a unique extention to it
unique_names = []
i = 1

for name in arbitrary_list:
    if name not in unique_names:
        unique_names.append(name)
    elif name in unique_names:
        
        new_name = str(name.rstrip("\r\n") + "E" + str(i) + "\n")
        unique_names.append(new_name)
        i += 1

# Export file
fileName  = "adjusted_list.txt"

stringToExport = ""

for row in unique_names:
    stringToExport += str(row)

try:
    fp = open(fileName, "w")
    fp.write(stringToExport)
    fp.close()
except IOError:
    print("Could not open adjusted_list.txt")
sys.exit(1)
