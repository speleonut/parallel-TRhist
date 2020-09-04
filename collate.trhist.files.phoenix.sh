#!/bin/bash

#SBATCH -J tableTRhist
#SBATCH -o /hpcfs/users/%u/log/collateTRhist.slurm-%j.out

#SBATCH -A robinson
#SBATCH -p batch
#SBATCH -N 1
#SBATCH -n 2
#SBATCH --time=01:00:00
#SBATCH --mem=8GB

# Notification configuration 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=%u@adelaide.edu.au

scriptDir=/hpcfs/groups/phoenix-hpc-neurogenetics/scripts/git/mark/parallel-TRhist

usage()
{
echo "# Script for counting repeats in Illumina reads
# Requires: Java, TRhist.
# This script assumes you have run trimmomatic.
#
# Usage sbatch $0 -p file_prefix -o /path/to/output | [ - h | --help ]
#
# Options
# -p	REQUIRED. A prefix to your sequence files of the form PREFIX_R1.fastq.gz 
# -o	OPTIONAL. Path to where you want to find your file output (if not specified /hpcfs/users/${USER}/TRhist/prefix is used)
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
	workDir=/hpcfs/users/${USER}/TRhist/$outPrefix
	echo "#INFO: Using $workDir as the output directory"
fi

# Make sure $workDir exists
if [ ! -d "$workDir" ]; then
    mkdir -p $workDir
fi

# load modules
module load Python/3.7.0-foss-2016b

## Start of the script ##
cd $workDir
find *.justNumbers.list > $outPrefix.listOfhists.txt
$scriptDir/collate.trhist.files.phoenix.py -s $outPrefix.listOfhists.txt
gzip $outPrefix.combined.histogram.matrix.txt
cat *.paired.fa.gz > $outPrefix.paired.all.fa.gz

echo "cat $outPrefix.listOfhists.txt | xargs -n1 rm
rm $outPrefix.listOfhists.txt
rm *.paired.fa.gz" >> $workDir/$outPrefix.TRhist.parallel.CleanUp.sh

chmod +x $workDir/$outPrefix.TRhist.parallel.CleanUp.sh
