# Gadi-benchmarking
Template scripts to automate submission of identical benchmark tasks with increasing compute resources

## Overview
Given the need to frequently benchmark bioinformatics tools when developing pipelines, this repository contains a pair of sample scripts that can be adapted for use to other tools. 

The template consists of a pair of scripts:
* `<tool>_benchmark_run.sh` sets up the resources for each benchmark run
* `<tool>_benchmark.pbs` is launched by the above, once for each identical analysis at the different resource thresholds

The CPU, memory and jobfs settings are setup according to the architecture of the nodes on the queue. 

Currently, resource settings are defined for the following queues, being those that we most frequently use:
* normal
* express
* hugemem
* normalbw
* expressbw

Feel free to add other queue details!

Outputs and logs are uniquely named according to resources, queue and sample ID. This is to prevent over-write and filename clashes when running multiple benchmarks. 

## Usage
### Inputs and run command customised for your tool 

Within  `<tool>_benchmark.pbs`:
* Specify project for accounting at `#PBS -P`
* Specify disk access at `#PBS -lstorage`
* Load modules
* Specify tmp dirs that may be required
* Specify the  run command/s to your needs

Within `<tool>_benchmark_run.sh`: 
* Specify inputs, required directories etc
* At minimum, script needs `sample`, `tool` (name of tool, used to name outputs), and `short` (short name of tool, used for job name)
* `tool` must also be the same as used to name the pair of benchmark scripts
* Ensure that all variables required by the actual job run command are parsed with '-v' within the qsub command
* Ensure compatibility between the scripts, ie are all required variables set up and parsed across correctly 
* Please observe the `### DO NOT EDIT BELOW THIS LINE ###` instruction

### Changing the default CPU values tested
The default script tests for 7 CPU values for 48-core nodes `NCPUS=( 1 2 4 6 12 24 48 )` and 4 values for 28-core nodes `NCPUS=( 1 7 14 28 )`. This is in keeping with the NUMA domain architecture on the nodes.  

In some cases, some CPU values may not be warranted for testing (eg if 1 CPU does not provide enough mem) depending on the tool you are benchmarking. Simply hash out the full list of CPU values, and create an NCPUS array with your chosen CPU values.  
 
### Testing
It is recommended to test this  before submission, simply done by wrapping the qsub command in a printf block to echo out the commands. 
Note this will of course not test compatability with the pbs job script, so consider running on one CPU value first before submitting the full suite of runs. 

### To run
Specify the queue to benchmark on as first and only argument to the script. Currently, only one quue can be can be benchmarked per issue of the below command. To test on multiple queues at once, simply re-issue the command with the other queue name. File names (outputs as well as PBS logs) are all unique across queue tests, allowing as many runs concurrently as desired. 

```
bash <tool>_benchmark_run.sh <queue>
```

### Outputs
* Analysis outputs are placed within `<tool>_benchmarking`
* PBS logs are placed within `./PBS_logs/<tool>_benchmarks`
* Sample name and resources (queue, CPUs, MEM) should all be included within the tool output file names as specified within `<tool>_benchmark.pbs`

### Summarising benchmarks
Use https://github.com/Sydney-Informatics-Hub/HPC_usage_reports/blob/master/gadi_usage_report.pl to create resource summaries that can be easily ported into Excel
