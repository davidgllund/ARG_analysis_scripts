#!/usr/bin/env python
import sys

def make_labels(list, name):
    labels = []
    for row in list:
        labels.append(name + "\n")

    return labels

file1 = open(sys.argv[1], 'r')
list = file1.readlines()
file1.close()

name = sys.argv[2]

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
        
