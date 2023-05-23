#!/bin/sh
#SBATCH   --partition=normal            # submit   to the normal(default) partition
#SBATCH   --job-name=getukb            # name the job
#SBATCH   --output=/groups/GENOECON/ukb/logs/debug/%j.out        # write stdout/stderr   to named file
#SBATCH   --error=/groups/GENOECON/ukb/logs/debug/%j.err
#SBATCH   --time=0-096:00:00             # Run for max of 02 hrs, 00 mins, 00 secs
#SBATCH   --nodes=1                     # Request N nodes
#SBATCH   --cpus-per-task=24           # Request n   cores per node
#SBATCH   --mem-per-cpu=8GB             # Request nGB RAM per core
#SBATCH   --mail-type=BEGIN,END,FAIL         # ALL,NONE,BEGIN,END,FAIL,REQUEUE,..
#SBATCH   --mail-user=gmarkel@gmu.edu     # Put your GMU email address here

ml load zlib/1.2.11-e3
ml load hosts/hopper
ml load gnu10/10.3.0-ya
ml load r/4.1.2-dx

Rscript
