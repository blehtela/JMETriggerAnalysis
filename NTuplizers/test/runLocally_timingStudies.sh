#!/bin/bash -e

# Run first the L1 step (note : very very big file output... ~100MB/Evt )
# cmsRun jmeTriggerNTuple_L1Only_cfg.py maxEvents=5 skipEvents=5 output=L1_output_timingStudies.root	#just to see if it runs
#cmsRun jmeTriggerNTuple_L1Only_cfg.py maxEvents=100 skipEvents=5 output=L1_output_timingStudies.root	#a few more events to actually see sth :)
cmsRun jmeTriggerNTuple_L1Only_cfg.py maxEvents=300 skipEvents=5 output=L1_output_timingStudies.root	#Try to get a bit more stats despite running locally on lxplus


# HLT step with analyser that producer JMETrigger NTuple tree structure.
cmsRun jmeTriggerNTuple_timingStudies_cfg.py inputFiles=file:L1_output_timingStudies.root

# Remove the large FEVTDEBUGHLT outputs
# rm Phase2*HLT.root
# rm L1_output.root

