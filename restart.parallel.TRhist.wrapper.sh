#!/bin/bash
# Master script for TRhist parallel pipeline

# Script constants
scriptDir=/data/neurogenetics/git/PhoenixScripts/mark/parallel-TRhist
usage()
{
echo "# This is the edited master script that coordinates job submission for parallel analysis of fastq files using TRhist
# TRhist is ususally super slow so this allows the steps and fastq to be broken up into bits then put back together 
# Requires: Java, TRhist, Trimmomatic.
# This script assumes your sequence files are gzipped
#
# Usage $0 -p file_prefix -o /path/to/output | [ - h | --help ]
#
# Options
# -p	REQUIRED. A prefix to your sequence files of the form PREFIX_R1.fastq.gz 
# -o	OPTIONAL. Path to where you want to find your file output (if not specified $FASTDIR/TRhist/prefix is used)
# -h or --help	Prints this message.  Or if you got one of the options above wrong you'll be reading this too!
# 
# 
# Original: Mark Corbett, 19/01/2018
# Modified: (Date; Name; Description)
#
"
}

## Set Variables ##
while [ "$1" != "" ]; do
	case $1 in
		-p )			shift
					outPrefix=$1
					;;
		-o )			shift
					workDir=$1
					;;
		-h | --help )		usage
					exit 0
					;;
		* )			usage
					exit 1
	esac
	shift
done
if [ -z "$outPrefix" ]; then # If no file prefix specified then do not proceed
	usage
	echo "#ERROR: You need to specify a file prefix (PREFIX) referring to your sequence files eg. PREFIX_R1.fastq.gz."
	exit 1
fi
if [ -z "$workDir" ]; then # If no output directory then use default directory
	workDir=$FASTDIR/TRhist/$outPrefix
	echo "Using $FASTDIR/TRhist/$outPrefix as the output directory"
fi

# Make sure $workDir exists
if [ ! -d "$workDir" ]; then
    usage
    echo "# ERROR: This is not the directory you're looking for.  This script is only if you get premature termination of your parallel TRhist pipeline.
	$workDir was not found but it should have been.  Does it exist?
	You can go about your business"
	exit 1
fi

# Find the TRhist fragments that did not complete
cd $workDir
find *.fa.gz | cut -f2 -d"." > $outPrefix.complete.txt
mv $outPrefix.xlist.txt $outPrefix.xlist.txt.old
grep -Fvwf $outPrefix.complete.txt $outPrefix.xlist.txt.old > $outPrefix.xlist.txt

# Coordinate jobs
splitCount=$(wc -l $workDir/$outPrefix.xlist.txt | cut -f1 -d" ")
histJob=`sbatch --array=0-${splitCount} --export=ALL $scriptDir/TRhist.parallel.paired.fastq.sh -p $outPrefix -o $workDir`
histJob=$(echo $histJob | cut -d" " -f4)
sbatch --export=ALL --dependency=afterok:${histJob} $scriptDir/collate.trhist.files.phoenix.sh -p $outPrefix -o $workDir
