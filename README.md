# Gadi-benchmarking
Template scripts to automate submission of identical benchmark tasks with increasing compute resources. 

This is to benchmark resources for multi-threading tools, to help determine the optimal number of CPUs and queue type for the job on a single task before submtting the job on many tasks. Benchmarking in this way is critical to ensuring efficient and responsible use of HPC, saving time and compute costs in the long run. 

## Overview
Given the need to frequently benchmark bioinformatics tools when developing pipelines, this repository contains a pair of sample scripts that can be adapted for use to other tools. 

The template consists of a pair of scripts:
* `<tool>_benchmark_run.sh` : sets up the resources for each benchmark run
* `<tool>_benchmark.pbs` : is launched by the above, once for each identical analysis at the different resource thresholds

The CPU, memory and jobfs settings are setup according to the architecture of the nodes on the queue. 

Currently, resource settings are defined for the following queues, being those that we most frequently use:
* normal
* express
* hugemem
* normalbw
* expressbw

Feel free to add other queue details!

Outputs and logs are uniquely named according to resources, queue and user-supplied prefix. This is to prevent over-write and filename clashes when running multiple benchmarks. 

## Usage

### 1. Rename the scripts

Change the names of the pair of scripts, replacing `tool` with the name of the tool you are benchmarking.

### 2. Add your tool commands to the benchmarking job script

Open `<tool>_benchmark.pbs` with your preferred text editor, and perform the following edits:

* Edit `-P` PBS directive to your NCI project
* Edit `-l storage` PBS directive to your required NCI storage paths, ensuring to use the [correct syntax for this directive](https://opus.nci.org.au/display/Help/PBS+Directives+Explained#PBSDirectivesExplained--lstorage=%3Cscratch/a00+gdata/xy11+massdata/a00%3E)
* Edit `-l walltime` to be sufficient for the lowest-resourced run of your job
* Add your script body between `YOUR SCRIPT HERE` and `END YOUR SCRIPT` headers. 
    * This means ALL COMMANDS REQUIRED TO RUN YOUR TOOL
    * Include `module loads` but not directives
    * This will be ideally copy pasted from another functional script you have used to establish your tool command/s
    * Ensure you have left the last line `end_test=end` intact
    * Use the variables `outfile_prefix` and `outdir` to name the outputs within your script
    * Variable `prefix` may be used for inputs, if relevant to your setup

### 3. Add your tool and prefix details to the run script

Open `<tool>_benchmark_run.sh` with your preferred text editor, and edit the following user-supplied variables:
* `prefix` : A prefix that will be included in output directory path and PBS log file names. This is to enable running benchmarking at the same resources on multiple samples/inputs in different runs without over-writing outputs and logs. Can also be used to assign inputs within the benchmarking command script, but this is not mandatory. If there is no need for an input-specific prefix, please use any value such as 'A' or 'Run1' 
* `tool` : Name of the tool being benchmarked. This will be used to name output directory and  PBS logs. Must be identical to the name used to rename the scripts. 
* `short` : Abbreviated name of tool for PBS job name

#### Optional: Changing the default CPU values tested

The default script tests for 7 CPU values for 48-core nodes `NCPUS=( 1 2 4 6 12 24 48 )` and 4 values for 28-core nodes `NCPUS=( 1 7 14 28 )`. This is in keeping with the NUMA domain architecture on the nodes.  

In some cases, some CPU values may not be warranted for testing (eg if 1 CPU does not provide enough mem) depending on the tool you are benchmarking. Simply hash out the full list of CPU values, and create an NCPUS array with your chosen CPU values.  
 
### 4. Testing

To run in test mode, provide the word 'test' as the second (optional) argument on the run command line, for example:

```
bash <tool>_benchmark_run.sh normal test
```

This will print out variables that are parsed from the run script to the PBS script for the first CPU value. It will also print out a copy of your script, interpolating any variables exported from the run script.

Note that this test does NOT test functionality of your tool commands. It is for a quick manual inspection before submission. 

To check functionality and compatability, options include:

* Wrap the tool run command in a printf statement, and call the PBS script from the run script with a bash call rather than qsub, then exit. The run script includes `set -a` so all variables are exported to the PBS script. If done correctly, this will print out your run command with ALL variables interpolated, helping to spot any obvious issues
* Edit the `NCPUS` array for the queue you are benchmarking to include only one CPU value, then submit. If this completes successfully, submit for the remaining NCPUS values. 

### 5. Run benchmarks on a range of values

Specify the queue to benchmark on as first and only argument to the script. Currently, only one queue can be can be benchmarked per issue of the below command. To benchmkark on multiple queues at once, simply re-issue the command with a different queue name supplied as argument. File names (outputs as well as PBS logs) are all unique across queue tests, allowing as many runs concurrently as desired. 


```
bash <tool>_benchmark_run.sh <queue>
```

## Outputs

* Outputs are written to `<tool>/<prefix>/<queue>_<CPUs>NCPUS_<MEM>MEM`
    * This requires that the user's tool command/s have correctly applied the `outdir` and `outfile_prefix` variables to name outputs, as instructed
* PBS logs are written to `PBS_logs/<tool>/<queue>_<CPUs>NCPUS_<MEM>MEM_<prefix>`

## Summarising benchmark resource usage
Use https://github.com/Sydney-Informatics-Hub/HPC_usage_reports/blob/master/gadi_usage_report.pl to create resource summaries that can be easily ported into Excel. You will probably need to instruct Excel to split the data on spaces. 

Change into the PBS logs directory and run the above script with no arguments to summarise resources on all logs in the directory. 

## Using benchmarks 

Once you have identified which resources provide the optimal trade-off between walltime, SU usage and CPU efficiency, use these values to set up your larger parallel or multi-sample runs. 

For parallel jobs running many small sub-tasks, it is ideal to repeat benchmarking on a sub-set of tasks (say 2 nodes worth) to ensure that CPU efficiency is maintained when many small tasks are running at once, before submitting a very large parallel job. This can be done by simply running a smaller subset of your job, and comparing the CPU efficiency of that job to the CPU efficiency achieved in your single-task benchmarking. Note that small variance is expected, based on varying system load at the time of job execution. If you observe a large variation, consider repeating your subset run at a larger and smaller subset value. Does the CPU efficiency follow a pattern of decline with increasing levels of parallelisation? If yes, explore possible causes and solutions before scaling up to the full job. Contact [NCI helpdesk](http://help.nci.org.au/) for assistance if required. 
