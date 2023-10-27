#!/bin/bash
set -a

################################################
# Pair of benchmarking scripts, to automate submission of multiple identical 
# jobs with increasing resources.
# Outputs and logs are unique for resources, queue and sample. 
# Setup for runs on normal, express, hugemem, normalbw and expressbw. 
# CPU settings are determined by NUMA domain sizes
# If the queue you want to benchmark on is not described here, you can add it under 'QUEUE SETUP' heading
# If you want to alter the range of CPU values to benchmark on, this can be done by editing the relevant array under the 'QUEUE SETUP' heading
# The queue to benchmark on is required as the first argument to the script
# Optional second argument is 'test', where some variables and your script are printed to screen but no job is submitted

# To use:
#1) Edit 'prefix', 'tool' and 'short' variables within this script
#2) Within <tool>_benchmark.pbs:
#	- Edit -P PBS directive to your NCI project
#	- Edit -lstorage PBS directive to your required NCI storage paths
#	- Edit walltime ot be sufficient for the lowest-resourced run of your job
#	- Add your sript body (including module loads) between 'YOUR SCRIPT HERE' and 'END YOUR SCRIPT' headers
#	- Ensure you have left the last line 'end_test=end' intact
# 	- Use the variables 'prefix', 'outfile_prefix' and 'outdir' for IO within your script 
#3) Run a simple check in test mode:
# 	- Example command to run in test mode on normal queue:
#	`bash <tool>_benchmark_run.sh normal test`
#	- This will print variables received from the run script, and your script
#4) If you also want to do a more thorough test with variable interpolation:
#	- Within <tool>_benchmark.pbs, wrap the tool command in a 'printf' statement, save, then resubmit NOT in test mode
#	- Once the command looks correct, remove the printf, save, and run as usual 
#5) Submit the benchmarking jobs to the queue:
#	- Example command to run benchmarking on hugemem queue:
#	`bash <tool>_benchmark_run.sh hugemem`


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

queue=$1

if [ -z ${queue} ]
then
	printf "Please specify queue name as first argument to script.\nCurrently accepted values are ONE OF normal express hugemem normalbw expressbw.\n"
	exit
fi

if [[ "${queue}" =~ ^(normal|express)$ ]]
then
	NCPUS=( 1 2 4 6 12 24 48 ) #  based on Gadi NUMA domains for queue
	#NCPUS=( 4 6 12 24 48) # optional - may need to reduce the number of benchmark runs
	#NCPUS=( 8 ) # or test a single value not included in initial runs
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
	NCPUS=( 1 2 4 6 12 24 48 ) 
	#NCPUS=( 2 4 6 12 ) # optional - may need to reduce the number of benchmark runs
elif [[ "${queue}" =~ ^(normalbw|expressbw)$ ]]
then
	max_cpus=28 
	max_jobfs=400  
	mem_per_cpu=9 
	jobfs_per_cpu=$(( $max_jobfs / $max_cpus ))
	NCPUS=( 1 7 14 28 )
	#NCPUS=( 7 14 28 ) # optional - may need to reduce the number of benchmark runs
else
	printf "Resource parameters for ${queue} not defined.\nPlease add queue details to this script and re-submit.\n"
	exit
fi

################################################
### DO NOT EDIT BELOW THIS LINE 
################################################

script=${tool}_benchmark.pbs
outdir=${tool}/${prefix}
logs=./PBS_logs/${tool}

mkdir -p PBS_logs ${tool} ${outdir} ${logs}

 
for ncpus in "${NCPUS[@]}"
do
   mem=$(( ncpus * ${mem_per_cpu}))
   jobfs=$(( ncpus * ${jobfs_per_cpu}))
   
   if [[ ${ncpus} == ${max_cpus} ]]
   then 
   	mem=$(( $mem - 2 ))
	jobfs=${max_jobfs}
   fi
   
    
   job_name=${short}_${ncpus}N_${mem}M
   outfile_prefix=${queue}_${ncpus}NCPUS_${mem}MEM 
   dot_e=${logs}/${queue}_${ncpus}NCPUS_${mem}MEM_${prefix}.e
   dot_o=${logs}/${queue}_${ncpus}NCPUS_${mem}MEM_${prefix}.o
   
   
   if [[ $2 == 'test' ]]
   then
   	printf "################################################\n### TESTING\n################################################\n"
	printf "\n* Will run ${script} at CPU valus of ${NCPUS[@]}\n\n"
	test=true
   	bash $script
   	exit 
   fi
   
   printf "\nBenchmarking ${tool} on queue ${queue} for ${prefix} with ${ncpus} NCPUS and ${mem} MEM with job ID: "
      
   qsub \
   	-q ${queue} \
   	-l ncpus=${ncpus} \
	-l mem=${mem}GB \
	-l jobfs=${jobfs}GB \
	-o ${dot_o} \
	-e ${dot_e} \
	-N ${job_name} \
	-v ncpus="${ncpus}",outfile_prefix="${outfile_prefix}",prefix="${prefix}",outdir="${outdir}" \
	${script}
    
   sleep 2
   echo
done