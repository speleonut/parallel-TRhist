#!/usr/bin/python3

# Script to split multisample ANNOVAR file
import pandas as pd
from scipy import stats
import sys, getopt, csv, os

def usage():
    print (
'''
# multisampleTRhistMatrix.py
# This is a helper script to parse combined.histogram.matrix.txt.gz files produced by our parallel TRhist program.
# Execute the script from a folder containing sample folders with that file included.
#
# Usage multisampleTRhistMatrix.py -s sampleList.txt -c 90 | [ -h | --help ]
#
# Options:
# -s           /path/to/sampleFile   OPTIONAL: A list of specific samples to extract. By default all samples are split into new files
# -c           basepair position     OPTIONAL: Default is 90.  Adjust this number if you want to extract a different column.
# -h | --help  Displays help         OPTIONAL: Displays usage information.
#
# Script created by Mark Corbett on 03/04/2019
# Contact: mark.corbett at adelaide.edu dot au
# Edit History (Name; Date; Description)
#
'''
         )

# Set initial values
sampleFile = ''
targetColumn = 90

# Read command line arguments
try:
    opts, args = getopt.getopt(sys.argv[1:],'hs:c:',['help'])
except getopt.GetoptError:
    usage
    sys.exit(2)
for opt, arg in opts:
    if opt in ("-h", "--help"):
        usage
        sys.exit()
    elif opt in ("-s"):
        sampleFile = arg
    elif opt in ("-c"):
        targetColumn = arg

# Make sure you have what you need
if sampleFile == '':
	print('No sample folders supplied so I\'m just seeing what I can do about that')
	samples = next(os.walk('.'))[1]	# List sample directories in the current directory
elif sampleFile != '':
    samples = [line.rstrip() for line in open(sampleFile)]

# Create an empty dataframe to start things off from
df = pd.DataFrame()

# open each sample dataframe extract the target column and concatenate to df
for s in samples:
    currentSampleTable = pd.read_csv( s+"/"+s+".combined.histogram.matrix.txt.gz", sep='\t', index_col = 0, usecols = [0, targetColumn], compression = 'gzip')
    currentSampleTable = currentSampleTable.rename(columns={str(targetColumn) : s})
    currentSampleTable = currentSampleTable[currentSampleTable[s] != 0]
    df = pd.concat([df, currentSampleTable], axis=1, join='outer', sort=True )
    df = df.fillna(0)

# Export everything	
df.to_csv("multisampleTRhistMatrix.txt", sep='\t')

# Make a short summary version for faster looking at likley candidates
df.filter(regex = '^\\w{0,7}$', axis = 0).to_csv("upto7mers.multisampleTRhistMatrix.txt", sep='\t')

# Calulate Z-scores
dfZ = stats.zscore(df, axis=0)

# Calculate ranking matrix
dfMean = pd.df.mean(axis=1)
dfMedian = pd.df.median(axis=1)
dfSD = pd.df.std(axis=1)
dfMax = pd.df.max(axis=1)
dfZMax = pd.dfZ.max(axis=1)
dfZCount = dfZ[dfZ > 1].count()
dfZ = pd.concat([dfMean, dfMedian, dfSD, dfMax, dfZMax, dfZCount], axis=1, join='outer', sort=True)
dfZ.to_csv("Zscores.mulltisampleTRhistMatrix.txt", sep='\t')
dfZ[dfZ['dfMedian']==0 & dfZ['dfZCount'] < 3 & dfZ['dfMax'] > 14 ].to_csv("outlierSamplesTRhistMatrix.txt", sep='\t')