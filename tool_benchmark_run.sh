#!/bin/bash

################################################
# Pair of benchmarking scripts, to automate submission of multiple identical 
# jobs with increasing resources.
# Outputs and logs are unique for resources, queue and sample. 
# Setup for runs on normal, express, hugemem, normalbw and expressbw. 
# CPU settings are determined by NUMA domain sizes. 

# To use:
#1) Specify inputs, required directories etc. Ensure that all variables required by the
#	 actual job run command are parsed with '-v' within the qsub command
#2) Adjust <tool>_benchmark.pbs modules, run commands etc to your needs. 
#3) Specify the queue to benchmark on as first and only argument to the script
#	Accepted values: normal express hugemem normalbw expressbw
#4) It is recommended to test this  before submission, simply done by wrapping the 
#	qsub command in a printf block to echo out the commands. Note this will of
#	course not test compatability with the pbs job script, so consider running
# 	on one CPU value first before submitting the full suite of runs. 

################################################

### REQUIRED CHANGES ###

#### Inputs - change as required: 
input=./input_file.in # INPUT FILE 
sample=$(basename ${input%.in})
tool=<tool> # name of the tool being benchmarked
short=<short-tool-name> # abbreviated tool name, for ease of viewing job name on qstat

################################################

### DO NOT EDIT BELOW THIS LINE ###

queue=$1

if [ -z ${queue} ]
then
	printf "Please specify queue name as first argument to script.\nCurrently accepted values are ONE OF normal express hugemem normalbw expressbw.\n"
	exit
fi


script=${tool}_benchmark.pbs
outdir=${tool}_benchmarking
mkdir -p ${outdir}
logs=./PBS_logs/${tool}_benchmarks
mkdir -p ${logs}
 

# Do not change, UNLESS: 
#  -May need to remove some CPU settings from the NCPUS array depending on minimum resources for the task! 
#  -May need to add other queue details 

if [[ "${queue}" =~ ^(normal|express)$ ]]
then
	#NCPUS=( 1 2 4 6 12 24 48 ) #  based on Gadi NUMA domains for queue
	NCPUS=( 4 6 12 24 48) # may need to reduce the number of benchmark runs
	max_cpus=48 # total CPU on nodes
	max_jobfs=400 # In GB, adjust depending on which queue you are benchmarking on  
	mem_per_cpu=4 # adjust depending on which queue you are benchmarking on 
	jobfs_per_cpu=$(( $max_jobfs / $max_cpus ))
elif [[ "${queue}" =~ ^(hugemem)$ ]]
then
	max_cpus=48 
	max_jobfs=1400  
	mem_per_cpu=31 
	jobfs_per_cpu=$(( $max_jobfs / $max_cpus ))
	#NCPUS=( 1 2 4 6 12 24 48 ) 
	NCPUS=( 2 4 6 12 )
elif [[ "${queue}" =~ ^(normalbw|expressbw)$ ]]
then
	max_cpus=28 
	max_jobfs=400  
	mem_per_cpu=9 
	jobfs_per_cpu=$(( $max_jobfs / $max_cpus ))
	#NCPUS=( 1 7 14 28 )
	NCPUS=( 7 14 28 )
else
	printf "Resource parameters for ${queue} not defined.\nPlease add queue details to this script and re-submit.\n"
	exit
fi


printf "################################################\nBenchmarking ${tool} on ${queue} queue for sample ${sample}\n################################################\n"
 
for ncpus in "${NCPUS[@]}"
do
   mem=$(( ncpus * ${mem_per_cpu}))
   jobfs=$(( ncpus * ${jobfs_per_cpu}))
   
   if [[ ${ncpus} == ${max_cpus} ]]
   then 
   	mem=$(( $mem - 2 ))
	jobfs=${max_jobfs}
   fi
   
    
   job_name=${short}_${ncpus}N_${mem}M_${sample}
   outfile_prefix=${sample}_${queue}_${ncpus}NCPUS_${mem}MEM 
   dot_e=${logs}/${tool}_${queue}_${ncpus}NCPUS_${mem}MEM_${sample}.e
   dot_o=${logs}/${tool}_${queue}_${ncpus}NCPUS_${mem}MEM_${sample}.o
   
   printf "\nBenchmarking on queue ${queue} with ${ncpus} NCPUS and ${mem} MEM with job ID: "
     
   qsub \
   	-q ${queue} \
   	-l ncpus=${ncpus} \
	-l mem=${mem}GB \
	-l jobfs=${jobfs}GB \
	-o ${dot_o} \
	-e ${dot_e} \
	-N ${job_name} \
	-v outfile_prefix="${outfile_prefix}",input="${input}",outdir="${outdir}" \
	${script} 
    
   sleep 2
   echo
done

