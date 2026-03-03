#!/bin/bash
source env.sh
# ______                       _   _____                  _   
# | ___ \                     | | |_   _|                | |  
# | |_/ /_ _ _ __ ___  ___  __| |   | | _ __  _ __  _   _| |_ 
# |  __/ _` | '__/ __|/ _ \/ _` |   | || '_ \| '_ \| | | | __|
# | | | (_| | |  \__ \  __/ (_| |  _| || | | | |_) | |_| | |_ 
# \_|  \__,_|_|  |___/\___|\__,_|  \___/_| |_| .__/ \__,_|\__|
#                                            | |              
#          

#boolean for PUPPI vs other efficiency checks
puppiStudy=false

# Default values
#BASE_DIR=/eos/user/t/tchatzis/JetTriggers_DPNote/
#BASE_DIR=/eos/user/b/blehtela/puppiStudies/puppiStudies_142XmixedPFPuppi/ #where the input is (i put one hadded file there)
###BASE_DIR=x/eos/user/b/blehtela/puppiStudies/ #puppiStudies_142XmixedPFPuppi/ #input, around 237 files a 6k events each.

#BASE_DIR=inputTest/ #try locally
#from above base_dir, have files here: QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8/crab_puppiStudies_142XmixedPFPuppi/250917_130444/0000/out_31.root
#BASE_DIR=/eos/user/b/blehtela/jmetrigger/puppiTests/ #/histoInputTest/
#for tests use this: histoInputTest/test_puppi_recoOption-mixedPFPuppi-and-AK8_1k-events_10Sep2025_NEW.root
##OUT_EOS_DIR=jmetrigger/PuppiTriggerAnalysisSubmitterV3manyNtuplesOUTDIR
#OUT_EOS_DIR=puppiTests_15Oct2025_V6_newTEST
###OUT_EOS_DIR=xpuppiTests_15Oct2025_jetTriggers

if [ "$puppiStudy" = true ]; then
    echo "Setting PUPPI study directories (input, output, jobs)"
    BASE_DIR=/eos/user/b/blehtela/puppiStudies/
    OUT_EOS_DIR=puppiTests_15Oct2025_jetTriggers
    JOBS_DIR_NAME=PuppiTests_15Oct2025_jetTriggers_JOBDIR
    dataKeys=(
        puppiStudies_142XmixedPFPuppi # USE THIS on eos; testing with one file only
    )
else
    echo "Setting directories (input, output, jobs)"
    BASE_DIR=/eos/cms/store/group/phys_jetmet/blehtela/checkCAtuning_06Feb2026/  #/eos/user/b/blehtela/checkECALmasking_25Oct2025/
    #OUT_EOS_DIR=checkCAtuning_10feb2026_OUT         #ECALmasking_27oct2025_OUT
    #JOBS_DIR_NAME=checkCAtuning_10feb2026_JOBDIR    #ECALmasking_27oct2025_JOBDIR
    OUT_EOS_DIR=checkCAtuning_11feb2026_OUT         #ECALmasking_27oct2025_OUT
    JOBS_DIR_NAME=checkCAtuning_11feb2026_JOBDIR    #ECALmasking_27oct2025_JOBDIR
    dataKeys=( 
        checkCAtuning_06Feb2026_Muon0-Run2025G-v1_default
        checkCAtuning_06Feb2026_Muon0-Run2025G-v1_updatedCAtuningTRK
    )
fi

echo "$BASE_DIR"


#JOBS_DIR_NAME=PuppiTriggerAnalysisSubmitterV3manyNtuplesJOBSDIR
#JOBS_DIR_NAME=PuppiTriggerAnalysisSubmitterV6manyNtuplesJOBSDIR_newTEST
#JOBS_DIR_NAME=PuppiTests_15Oct2025_jetTriggers_JOBDIR

# Flags for condor jobs
monitor_jobs=0
resubmit_jobs=0

# Define dataKeys manually here if you want
#dataKeys=(
  #histoInputTest
  #testfiles
  ##puppiStudies_142XmixedPFPuppi # USE THIS on eos; testing with one file only
  #QCD_Bin-PT-15to7000_Par-PT-flat2022_TuneCP5_13p6TeV_pythia8 #this includes more files!
  #JetMET0_Run2022CV1
#)

#DRIVER_CONFIG=performances_raw     #efficiencies_raw      #efficiencies_miniaod #update this!!
DRIVER_CONFIG=efficiencies_raw
#DRIVER_CONFIG=efficiencies_puppistudies    #for puppi
# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --base-dir) # Base dir. Could be on EOS or anywhere.
            BASE_DIR="$2"
            shift 2
            ;;
        --out-eos-dir) # Output is stored in an EOS dir.
            OUT_EOS_DIR="$2"
            shift 2
            ;;
        --jobs-dir-name) # Name of condor submissions jobs directory. This is appearing locally.
            JOBS_DIR_NAME="$2"
            shift 2
            ;;
        --driver-config) # Name of file to use for plugin configuration. See analysisDriver_configurations directory for such configs examples.
            DRIVER_CONFIG="$2"
            shift 2
            ;;
        --data-keys) # Comma seperated list of keys of data sub-directories to be used. If none is given will just take everything inside the BASE_DIR.
            IFS=',' read -r -a dataKeys <<< "$2"
            shift 2
            ;;
        --monitor-jobs) # Flag in which the script will just run to check the condor job statuses
            monitor_jobs=1
            shift
            ;;    
        --resubmit-jobs) # Flag in which the script will just run to check the condor job statuses and resubmit
            resubmit_jobs=1
            shift
            ;;    
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--base-dir DIR] [--out-eos-dir DIR] [--jobs-dir-name NAME] [--driver-config PLUGIN_CONFIGURATION_YAML_FILE] [--data-keys key1,key2,...] [--monitor-jobs] [--resubmit-jobs]"
            exit 1
            ;;
    esac
done

#   ___              _           _         ___       _         
#  / _ \            | |         (_)       |_  |     | |        
# / /_\ \_ __   __ _| |_   _ ___ _ ___      | | ___ | |__  ___ 
# |  _  | '_ \ / _` | | | | / __| / __|     | |/ _ \| '_ \/ __|
# | | | | | | | (_| | | |_| \__ \ \__ \ /\__/ / (_) | |_) \__ \
# \_| |_/_| |_|\__,_|_|\__, |___/_|___/ \____/ \___/|_.__/|___/
#                       __/ |                                  
#                      |___/                                   

# If dataKeys array is empty, fill it from directories in BASE_DIR
if [ ${#dataKeys[@]} -eq 0 ]; then
    echo "No manual dataKeys given - scanning ${BASE_DIR}..."
    mapfile -t dataKeys < <(find "${BASE_DIR}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
fi

FIRST_USER_LETTER=${USER:0:1}

for dataKey in "${dataKeys[@]}"; do
  echo ${dataKey}
  # directory with input JMETriggerNTuple(s)
  INPDIR=${BASE_DIR}${dataKey}"/*/*/*/*" #the stars are due to crab-directory structure (double-check how many)
  ##INPDIR=${BASE_DIR}${dataKey} #"/*"
  echo "input directory searched: "
  echo $INPDIR
  #INPDIR=${BASE_DIR}${dataKey}"*"
  #directory with outputs of NTupleAnalysis
  #OUTDIR=./${JOBS_DIR_NAME}/${dataKey}
  OUTDIR=${JOBS_DIR_NAME}/${dataKey} #new (08.10.2025)
  OUTPUTDIR=${BASE_DIR}/${OUT_EOS_DIR}/${dataKey} #new (11.02.2026)
  #OUTPUTDIR=/eos/user/${FIRST_USER_LETTER}/${USER}/${OUT_EOS_DIR}/${dataKey}/

  mkdir -p ${OUTDIR}

  if [ "$monitor_jobs" -eq 1 ]; then
      if [ "$resubmit_jobs" -eq 0 ]; then
        # Just monitor existing jobs
        batch_monitor.py -i "${OUTDIR}/jobs"
      else
        # Just monitor and resubmit existing jobs
        batch_monitor.py -i "${OUTDIR}/jobs" -r
      fi
  else
    mkdir ${OUTDIR}/ntuples #just for test (08.10.2025)
    # Jobs creation
    [ -d ${OUTDIR}/ntuples ] || (ln -sf ${INPDIR} ${OUTDIR}/ntuples)
    #batch_driver.py -l 1 -n 10000000000000000000 -p JMETriggerAnalysisDriverRun3 -cfg ${DRIVER_CONFIG} \
    batch_driver.py -l 1 -n 100000 -p JMETriggerAnalysisDriverRun3 -cfg ${DRIVER_CONFIG} \
    -i ${INPDIR}/*.root -o ${OUTDIR}/jobs \
    -od ${OUTPUTDIR} \
    --JobFlavour microcentury
    
    mkdir -p ${OUTPUTDIR}
    # Jobs submission
    batch_monitor.py -i ${OUTDIR}/jobs -r #--repe -f 1200
  fi
done

unset recoKey recoKey

