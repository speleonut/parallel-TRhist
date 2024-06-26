#!/bin/bash

#SBATCH -J TrimTheFat
#SBATCH -o /hpcfs/users/%u/log/trimmomatic.slurm-%j.out
#SBATCH -p icelake,a100cpu
#SBATCH -N 1
#SBATCH -n 4
#SBATCH --time=01:00:00
#SBATCH --mem=16GB

# Notification configuration 
#SBATCH --mail-type=END                                         
#SBATCH --mail-type=FAIL                                        
#SBATCH --mail-user=%u@adelaide.edu.au

TrimmomaticProg="/hpcfs/groups/phoenix-hpc-neurogenetics/executables/Trimmomatic-0.39/trimmomatic-0.39.jar"
DelFq=true # Adds all files to the clean up script for later removal

usage()
{
echo "# Script for trimming Illumina reads
# Requires: Java, Trimmomatic.
# This script is part of a pipeline and assumes you ran splitReadFiles.sh already
#
# Usage sbatch $0 -p file_prefix -o /path/to/output | [ - h | --help ]
#
# Options
# -p        REQUIRED. A prefix to your sequence files of the form PREFIX_R1.fastq.gz 
# -o        OPTIONAL. Path to where you want to find your file output (if not specified /hpcfs/users/${USER}/TRhist/prefix is used)
# --keep    OPTIONAL. Set this if you want to keep the paired trimmed fastq files.  The default is to add them to the clean up script.
# -h or --help	Prints this message.  Or if you got one of the options above wrong you'll be reading this too!
# 
# 
# Original: Mark Corbett, 19/01/2018
# Modified: (Date; Name; Description)
# 11/01/2023; Mark; Add the --keep option to add all paired fq.gz files to the clean up script. NOTE: this changes the default behaviour.
#
"
}

## Set Variables ##
while [ "$1" != "" ]; do
	case $1 in
		-p )		shift
					outPrefix=$1
					;;
		-o )		shift
					workDir=$1
					;;
		--keep )	shift
					DelFq=false
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

# Create the array of seqFiles
readarray -t seqFile < $workDir/$outPrefix.xlist.txt

# load modules
module purge
module use /apps/skl/modules/all
module load Java/1.8.0_191

## Start of the script ##
cd $workDir

# Make sure all reads are the same length or TRhist gets up tight about it. 
# 90 bases gives patterns of length 1,2,3,5,6 and all factors of these, integer numbers of repeats
java -Xmx16g -jar $TrimmomaticProg PE -threads 4 \
$workDir/read1/${seqFile[$SLURM_ARRAY_TASKID]} $workDir/read2/${seqFile[$SLURM_ARRAY_TASK_ID]} \
-baseout $workDir/$outPrefix.${seqFile[$SLURM_ARRAY_TASK_ID]}.fq.gz \
LEADING:2 CROP:90 MINLEN:90

# We can't use the unpaired reads for TRhist so just throw them out along with the split files
echo "rm $workDir/$outPrefix.${seqFile[$SLURM_ARRAY_TASK_ID]}\_[1,2]U.fq.gz" >> $workDir/$outPrefix.TRhist.parallel.CleanUp.sh
if "$DelFq"; then
    echo "rm $workDir/$outPrefix.${seqFile[$SLURM_ARRAY_TASK_ID]}\_[1,2]P.fq.gz" >> $workDir/$outPrefix.TRhist.parallel.CleanUp.sh
fi
