#!/bin/sh
#SBATCH   --partition=normal            # submit   to the normal(default) partition
#SBATCH   --job-name=getukb            # name the job
#SBATCH   --output=/groups/GENOECON/ukb/%j.out        # write stdout/stderr   to named file
#SBATCH   --error=/groups/GENOECON/ukb/%j.err
#SBATCH   --time=0-096:00:00             # Run for max of 02 hrs, 00 mins, 00 secs
#SBATCH   --nodes=1                     # Request N nodes
#SBATCH   --cpus-per-task=10            # Request n   cores per node
#SBATCH   --mem-per-cpu=4GB             # Request nGB RAM per core
#SBATCH   --mail-type=BEGIN,END,FAIL         # ALL,NONE,BEGIN,END,FAIL,REQUEUE,..
#SBATCH   --mail-user=gmarkel@gmu.edu     # Put your GMU email address here

module load use.own
module load parallel
sh /groups/GENOECON/ukb/par_gen.sh
