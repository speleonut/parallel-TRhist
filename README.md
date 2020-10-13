# parallel-TRhist
Slurm scripts for running TRhist in parallel and then collating the data into one matrix

**Usage**

`screen parallel.TRhist.wrapper.sh -p file_prefix -s /path/to/sequences -o /path/to/output | [ - h | --help ]`

\# Use ctrl+a d to detach from the screen session (the session will quit once the read splitting is done)

**Workflow description**
The wrapper script sets off a chain of jobs working on paired fastq files to get a single matrix of all possible read repeat counts.
The fastq are split into sub files of 10 million reads per chunk.
Each chunk is trimmed in parallel to 90 base pairs with trimmomatic https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4103590/.  All reads must be the same length and so 90 is the default to make things run a bit faster.
Each trimmed read pair is run through TRhist independently and in parallel https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3957077/. Approximate run time on our HPC is 6 hours (the same protocol without splitting takes > 72 hours).

When you have completed several genomes you can collate data from multiple runs to look for significant outliers as determined by z-score by running the multisampleTRhistMatrix.py script from the top level directory containing all of your sample directories.
e.g.

```
cd /path/to/output
python3 multisampleTRhistMatrix.py
```

**Notes:**
These scripts are written for the specific architecture of our HPC.  They will not work unless you fix up file paths and adapt for your scheduler.
