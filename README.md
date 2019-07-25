# parallel-TRhist
Slurm scripts for running TRhist in parallel and then collating the data into one matrix

**Usage**
screen parallel.TRhist.wrapper.sh -p file_prefix -s /path/to/sequences -o /path/to/output | [ - h | --help ]

\# Use ctrl+a d to detach from the screen session (the session will quit once the read splitting is done)

**Workflow description**
The wrapper script sets off a chain of jobs working on paired fastq files to get a single matrix of all possible read repeat counts.
The fastq are split into sub files of 10 million reads per chunk.
Each chunk is trimmed in parallel to 90 base pairs with trimmomatic https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4103590/.  All reads must be the same length.  120 bp would be better as that can accomodate repeat unit lengths of 1-6 to the full length of the read but 90 is the default to make it a bit faster and can do repeat units of 1,2,3,5 & 6.
Each trimmed read pair is run through TRhist independently and in parallel https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3957077/
The results of TRhist are compiled with a customised python script.
Approximate run time on our HPC is 6 hours (the same protocol without splitting takes > 72 hours).

**Notes:**
These scripts are written for the specific architecture of our HPC.  They will not work unless you fix up file paths and adapt for your scheduler.
