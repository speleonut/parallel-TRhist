#!/apps/software/Python/3.7.0-foss-2016b/bin/python3

import sys, getopt
import numpy as np
import pandas as pd

def usage():
    print (
'''
# collate.trhist.files.phoenix.py a script to combine TRhist files created from parallel analysis of fastq files.
#
# Usage collate.trhist.files.phoenix.py -s sampleList.txt | [ -h | --help ]
#
# Options:
# -s           /path/to/sampleFile   REQUIRED: A list of specific sample files to combine.
# -h | --help  Displays help                 OPTIONAL: Displays usage information.
#
# Script created by Mark Corbett on 29/03/2019
# Contact: mark.corbett at adelaide.edu dot au
# Edit History (Name; Date; Description)
#
'''
         )

# Set initial values
sampleFile = ''

# Read command line arguments
try:
    opts, args = getopt.getopt(sys.argv[1:],'hs:',['help'])
except getopt.GetoptError:
    usage
    sys.exit(2)
for opt, arg in opts:
    if opt in ("-h", "--help"):
        usage
        sys.exit()
    elif opt in ("-s"):
        sampleFile = arg

# Make sure you have what you need
if sampleFile == '':
    usage
    print('Hey, you forgot to tell me which files to combine')
    sys.exit(2)	

# Make a dummy dataframe to start with with the known repeat sequence "A"
# If your TRhist files didn't have that index then there is something seriously odd with the genome you sequenced!
df = pd.DataFrame([np.repeat(0, 91)])
df = df.set_index([0])
df = df.reindex(["A"], fill_value=0)
df = df.apply(pd.to_numeric)

# Import the list of sample files
samples = [line.rstrip() for line in open(sampleFile)]

# Loop through the files and add them into the main df
for s in samples:
    myTRhist = [line.rstrip() for line in open(s)]
    nreps = int(len(myTRhist)/91)
    myArray = np.reshape(myTRhist, (nreps,91))
    myDf = pd.DataFrame(myArray)
    myDf = myDf.set_index([0])
    myDf = myDf.apply(pd.to_numeric)
    df = df.add(myDf,axis=[1], fill_value=0)

# Export data to file
myID = sampleFile.split('.')[0]
df.to_csv(myID+".combined.histogram.matrix.txt", sep='\t')
