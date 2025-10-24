#!/bin/bash

cd /afs/cern.ch/work/b/blehtela/private/jmetrigger/CMSSW_15_0_11/src
eval `scramv1 runtime -sh`
cd - &> /dev/null

set -e

if [ -f /eos/home-b/blehtela/puppiTests_15Oct2025/puppiStudies_142XmixedPFPuppi/puppiJetsTest_19Sep2025_v1__0.root ]; then \
  rm -f /eos/home-b/blehtela/puppiTests_15Oct2025/puppiStudies_142XmixedPFPuppi/puppiJetsTest_19Sep2025_v1__0.root; fi;

/afs/cern.ch/work/b/blehtela/private/jmetrigger/CMSSW_15_0_11/src/JMETriggerAnalysis/NTupleAnalysis/test/run.py \
 -i /eos/user/b/blehtela/puppiStudies/puppiStudies_142XmixedPFPuppi/puppiJetsTest_19Sep2025_v1.root \
 -o /eos/home-b/blehtela/puppiTests_15Oct2025/puppiStudies_142XmixedPFPuppi/puppiJetsTest_19Sep2025_v1__0.root \
 -p JMETriggerAnalysisDriverRun3 \
 --skipEvents 0 \
 --maxEvents 100 \
 -cfg efficiencies_puppistudies

touch /afs/cern.ch/work/b/blehtela/private/jmetrigger/CMSSW_15_0_11/src/JMETriggerAnalysis/NTupleAnalysis/test/PuppiTriggerAnalysisSubmitterV5manyNtuplesJOBSDIRTest/puppiStudies_142XmixedPFPuppi/jobs/puppiStudies_142XmixedPFPuppi/puppiJetsTest_19Sep2025_v1__0.completed
