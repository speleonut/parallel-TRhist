#!/bin/bash

#SBATCH -J splitsville
#SBATCH -o /fast/users/%u/launch/splitsville.slurm-%j.out

#SBATCH -A robinson
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --time=03:00:00
#SBATCH --mem=16GB

# Notification configuration 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=%u@adelaide.edu.au

usage()
{
echo "# Script for splitting Illumina read files to chunks
# Requires: bash
# This script assumes your sequence files are gzipped
#
# Usage sbatch $0 -p file_prefix -s /path/to/sequences -o /path/to/output [-i /path/to/bedfile.bed] | [ - h | --help ]
#
# Options
# -p	REQUIRED. A prefix to your sequence files of the form PREFIX_R1.fastq.gz 
# -s 	REQUIRED. Path to find your fastq files /path/to/sequences
# -o	OPTIONAL. Path to where you want to find your file output (if not specified $FASTDIR/TRhist/prefix is used)
# -h or --help	Prints this message.  Or if you got one of the options above wrong you'll be reading this too!
# 
# 
# Original: Mark Corbett, 27/03/2019
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
		-s )			shift
					seqPath=$1
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
if [ -z "$seqPath" ]; then # If no file prefix specified then do not proceed
	usage
	echo "#ERROR: You need to tell me where to find your sequence files."
	exit 1
fi
if [ -z "$workDir" ]; then # If no output directory then use default directory
	workDir=$FASTDIR/TRhist/$outPrefix
	echo "Using $FASTDIR/TRhist/$outPrefix as the output directory"
fi

# Make sure $workDir exists
if [ ! -d $workDir ]; then
    mkdir -p $workDir
fi

# Locate sequence file names.
# This is a bit awkward and prone to errors since relies on only a few file naming conventions and assumes how they will line up after ls of files
# ...and assumes only your seq files are in the folder matching the file prefix
cd $seqPath
seqFile1=$(ls *.fastq.gz | grep $outPrefix\_ | head -n 1) # Assume sequence files are some form of $outPrefix_fastq.gz
if [ -f $seqFile1 ]; then
	fileCount=$(ls *.fastq.gz | grep $outPrefix\_ | wc -l | sed 's/[^0-9]*//g')
	if [ $fileCount -ne "2" ]; then
		echo "Sorry I've found the wrong number of sequence files and there's a risk I will map the wrong ones!"
		exit 1
	fi
	seqFile2=$(ls *.fastq.gz | grep $outPrefix\_ | tail -n 1)
else
	fileCount=$(ls *.fastq.gz | grep -w $outPrefix | wc -l | sed 's/[^0-9]*//g') # Otherwise try other seq file name options
	if [ $fileCount -ne "2" ]; then
		echo "Sorry I've found the wrong number of sequence files and there's a risk I will map the wrong ones!"
		exit 1
	fi
	seqFile1=$(ls *.fastq.gz | grep -w $outPrefix | head -n 1) 
	seqFile2=$(ls *.fastq.gz | grep -w $outPrefix | tail -n 1)
fi
if [ ! -f $seqFile1 ]; then # Proceed to epic failure if can't locate unique seq file names
	echo "Sorry I can't find your sequence files! I'm using $outPrefix as part of the filename to locate them"
	exit 1
fi

## Start of the script ##
cd $workDir
mkdir read1
mkdir read2

# Make sure all reads are the same length or TRhist gets up tight about it. 
# 120 bases gives patterns of length 1,2,3,4,5,6 and all factors of these, integer numbers of repeats

# Split reads in 10 million reads per file (40 million lines) 
cd $workDir/read1 && zcat $seqPath/$seqFile1 | split -a3 -l 40000000 &
cd $workDir/read2 && zcat $seqPath/$seqFile2 | split -a3 -l 40000000
wait

cd $workDir/read1 && find x* | xargs -n1 -P4 gzip 
cd $workDir/read2 && find x* | xargs -n1 -P4 gzip 
find x* > $workDir/$outPrefix.xlist.txt

echo "rm -r $workDir/read1 $workDir/read2" >> $workDir/$outPrefix.TRhist.parallel.CleanUp.sh
