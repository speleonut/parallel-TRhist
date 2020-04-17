#!/bin/bash
# Master script for TRhist parallel pipeline

# Script constants
scriptDir=/data/neurogenetics/git/PhoenixScripts/mark
usage()
{
echo "# This is the master script that coordinates job submission for parallel analysis of fastq files using TRhist
# TRhist is ususally super slow so this allows the steps and fastq to be broken up into bits then put back together 
# Requires: Java, TRhist, Trimmomatic.
# This script assumes your sequence files are gzipped
#
# Usage screen $0 -p file_prefix -s /path/to/sequences -o /path/to/output | [ - h | --help ]
#
# Options
# -p	REQUIRED. A prefix to your sequence files of the form PREFIX_R1.fastq.gz 
# -s 	REQUIRED. Path to find your fastq files /path/to/sequences
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
if [ -z "$seqPath" ]; then # If no location for the sequence files given then do not proceed
	usage
	echo "#ERROR: You need to tell me where to find your sequence files."
	exit 1
fi
if [ -z "$workDir" ]; then # If no output directory then use default directory
	workDir=$FASTDIR/TRhist/$outPrefix
	echo "Using $FASTDIR/TRhist/$outPrefix as the output directory"
fi

# Make sure $workDir exists
if [ ! -d "$workDir" ]; then
    mkdir -p $workDir
fi

# Locate sequence file names.
# This is a bit awkward and prone to errors since relies on only a few file naming conventions and assumes how they will line up after ls of files
# ...and assumes only your seq files are in the folder matching the file prefix
cd $seqPath
seqFile1=$(ls *.fastq.gz | grep $outPrefix\_ | head -n 1) # Assume sequence files are some form of $outPrefix_fastq.gz
if [ -f "$seqFile1" ]; then
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
if [ ! -f "$seqFile1" ]; then # Proceed to epic failure if can't locate unique seq file names
	echo "Sorry I can't find your sequence files! I'm using $outPrefix as part of the filename to locate them"
	exit 1
fi

echo "#!/bin/bash
# This script is to clean up after this pipeline
" > $workDir/$outPrefix.TRhist.parallel.CleanUp.sh

splitJob=`sbatch --wait --export=ALL $scriptDir/splitReadFiles.sh -p $outPrefix -s $seqPath -o $workDir`
splitJob=$(echo ${splitJob} | cut -d" " -f4)
wait
splitCount=$(head -n-1 $workDir/$outPrefix.xlist.txt | wc -l)
trimJob=`sbatch --array=0-${splitCount} --export=ALL --dependency=afterok:${splitJob} $scriptDir/trimmomatic.sh -p $outPrefix -o $workDir`
trimJob=$(echo $trimJob | cut -d" " -f4)
histJob=`sbatch --array=0-${splitCount} --export=ALL --dependency=afterok:${trimJob} $scriptDir/TRhist.parallel.paired.fastq.sh -p $outPrefix -o $workDir`
histJob=$(echo $histJob | cut -d" " -f4)
sbatch --export=ALL --dependency=afterok:${histJob} $scriptDir/collate.trhist.files.phoenix.sh -p $outPrefix -o $workDir
