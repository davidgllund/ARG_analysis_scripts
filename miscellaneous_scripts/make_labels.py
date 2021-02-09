#!/usr/bin/env python
import sys

def make_labels(list, name):
    labels = []
    for row in list:
        labels.append(name[0])

    return labels

file1 = open(sys.argv[1], 'r')
list = file1.readlines()
file1.close()

file2 = open(sys.argv[2], 'r')
name = file2.readlines()
file2.close()

labels = make_labels(list, name)

stringToExport = ""

fileName = "labels.txt"

for row in labels:
    stringToExport += str(row)

try:
    fp = open(fileName, 'w')
    fp.write(stringToExport)
    fp.close()
except IOError:
    print("Could not open labels.txt")
sys.exit(1)
        
