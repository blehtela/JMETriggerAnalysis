#!/bin/bash -e

if [ $# -ne 1 ]; then
  printf "\n%s\n\n" ">> argument missing - specify path to output directory"
  exit 1
fi

NEVT=50000
ODIR=${1}

declare -A samplesMap

# QCD pthat 15-3000
samplesMap["Phase2HLTTDR_QCD_Flat_Pt-15to3000_14TeV_PU200"]="/QCD_Pt-15To3000_TuneCP5_Flat_14TeV-pythia8/Phase2Spring24DIGIRECOMiniAOD-PU200_Trk1GeV_140X_mcRun4_realistic_v4-v1/GEN-SIM-DIGI-RAW-MINIAOD"

# additional options for bdriver
opts="--submit"

L1_CFG=${CMSSW_BASE}/src/JMETriggerAnalysis/NTuplizers/test/jmeTriggerNTuple_L1Only_cfg.py
python3 ${CMSSW_BASE}/src/JMETriggerAnalysis/NTuplizers/test/jescJRA_cfg.py reco=default dumpPython=.tmp_cfg.py

for sampleKey in ${!samplesMap[@]}; do
  sampleName=${samplesMap[${sampleKey}]}

  # number of events per sample
  numEvents=${NEVT}
  if [[ ${sampleKey} == *MinBias* ]]; then
    numEvents=2000000
  fi

  FINAL_OUTPUT_DIR=/eos/user/t/tchatzis/MTDtiming_samples/${ODIR}/${sampleKey}

  if [ -d ${FINAL_OUTPUT_DIR} ]; then
    printf "%s\n" "directory for saving jobs outputs already exists: ${FINAL_OUTPUT_DIR}"
    read -p "Do you want to rewrite it? [y/n]" yn
    case $yn in
      [Yy]* ) rm -rf ${FINAL_OUTPUT_DIR}; echo "Continuing the process...";;
      [Nn]* ) echo "Exiting..."; exit 1;;
      * ) echo "Please answer with y/n.";;
    esac
  fi

  mkdir -p ${FINAL_OUTPUT_DIR}

  if [ -d ./${ODIR}/${sampleKey} ]; then
    rm -rf ./${ODIR}/${sampleKey}
  fi

  # The updated bdriver runs the L1 cfg first in the Condor scratch area,
  # then runs the HLT cfg on file:L1_output_*.root and stages out only out_*.root.
  if [[ "${sampleName}" == *"GEN-SIM-DIGI-RAW"* ]]; then
  bdriver -c .tmp_cfg.py -cl1 ${L1_CFG} --customize-cfg -m ${numEvents} -n 100 --cpus 1 --memory 2G --time 02:00:00 ${opts} --batch-system htc \
  -d ${sampleName} -p 0 -o ${ODIR}/${sampleKey} \
  --final-output ${FINAL_OUTPUT_DIR} \
  --customise-commands \
  '# output [TFileService]' \
  "if hasattr(process, 'TFileService'):" \
  '  process.TFileService.fileName = opts.output'
  else
  bdriver -c .tmp_cfg.py -cl1 ${L1_CFG} --customize-cfg -m ${numEvents} -n 100 --cpus 1 --memory 2G --time 01:30:00 ${opts} --batch-system htc \
  -d ${sampleName} -p 1 -o ${ODIR}/${sampleKey} \
  --final-output ${FINAL_OUTPUT_DIR} \
  --customise-commands \
  '# output [TFileService]' \
  "if hasattr(process, 'TFileService'):" \
  '  process.TFileService.fileName = opts.output'
  fi

  unset numEvents sampleName

done

unset sampleKey

rm -f .tmp_cfg.py

unset opts samplesMap NEVT ODIR FINAL_OUTPUT_DIR L1_CFG
