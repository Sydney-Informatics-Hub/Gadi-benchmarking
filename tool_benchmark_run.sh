#!/bin/bash
set -a

################################################
### REQUIRED CHANGES ###
################################################

# A prefix that will be included in output directory path and PBS log file names
# this is to enable runing benchmarking at the same resources on multiple samples/inputs in 
# different runs withput over-writing outputs and logs 
# Can also be used to assign inputs within the benchmarking command script, but this is not mandatory
# If there is no need for an input-specific prefix, please use any value here such as 'A' or 'Run1'  

prefix=

#--------

# Name of the tool being benchmarked, will be used to name outdir and  PBS logs

tool= 

#--------

# Abbreviated name of tool for job name
 
short=

#--------

################################################
### QUEUE SETUP
################################################

# Do not change, UNLESS: 
# -   	You need to remove or add different CPU values to the 'NCPUS array, for example
# 	removing the low CPU valies if they will not provide adequate resources for the task
# - 	You want to add queue details for queues not included in the original repository scripts 

NODES=( 1 2 4 8 16 32)
NCPUS=( 1 2 ) #  Reasonable Artemis numbers
max_cpus=32 # total CPU on nodes
mem_per_cpu=4 # adjust depending on which queue you are benchmarking on 


################################################
### DO NOT EDIT BELOW THIS LINE 
################################################

script=${tool}_benchmark.pbs
outdir=${tool}/${prefix}
logs=./PBS_logs/${tool}

mkdir -p PBS_logs ${tool} ${outdir} ${logs}

 
for nchunks in "${NODES[@]}"
do
	for ncpus in "${NCPUS[@]}"
	do
	   mem=$(( ncpus * ${mem_per_cpu}))
   
	   if [[ ${ncpus} == ${max_cpus} ]]
	   then 
	   	mem=$(( $mem - 2 ))
	   fi
   
    
	   job_name=${short}_${ncpus}N_${mem}M
	   outfile_prefix=${ncpus}NCPUS_${mem}MEM 
	   dot_e=${logs}/${ncpus}NCPUS_${mem}MEM_${prefix}.e
	   dot_o=${logs}/${ncpus}NCPUS_${mem}MEM_${prefix}.o
   
   
	   if [[ $1 == 'test' ]]
	   then
	   	printf "################################################\n### TESTING\n################################################\n"
		printf "\n* Will run ${script} at CPU valus of ${NCPUS[@]}\n\n"
		test=true
	   	bash $script
	   	exit 
	   fi
   
	   printf "\nBenchmarking ${tool} on queue ${queue} for ${prefix} with ${ncpus} NCPUS and ${mem} MEM with job ID: "
      
	   qsub \
	   	-q defaultQ \
	   	-l select=${nchunks}:ncpus=${ncpus}:mem=${mem}GB \
		-o ${dot_o} \
		-e ${dot_e} \
		-N ${job_name} \
		-v ncpus="${ncpus}",outfile_prefix="${outfile_prefix}",prefix="${prefix}",outdir="${outdir}" \
		${script}
    
	   sleep 2
	   echo
	done
done