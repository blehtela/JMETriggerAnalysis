#!/bin/bash -e

# Taken from SWGuideGlobalHLT page : https://twiki.cern.ch/twiki/bin/view/CMSPublic/SWGuideGlobalHLT
#hltGetConfiguration /dev/CMSSW_16_0_0/GRun \
#hltGetConfiguration /dev/CMSSW_16_0_0/GRun/V2 \
#hltGetConfiguration /dev/CMSSW_16_0_0/GRun/V30 \
#use the version shipped with this release in HLTrigger/Configuration/python/HLT_GRun_cff.py
hltGetConfiguration /dev/CMSSW_16_0_0/GRun \
   --globaltag 160X_dataRun3_HLT_v1 \
   --data \
   --unprescale \
   --output minimal \
   --max-events 100 \
   --eras Run3_2026 --l1-emulator uGT --l1 L1Menu_Collisions2026_v1_1_0_xml \
   --path MC_*,HLTriggerF*,Status*,HLT_PFJet60_v*,HLT_PFJet140_v*,HLT_PFJet320_v*,HLT_PFJet500_v*,HLT_PFHT160_v*,HLT_PFHT180_v*,HLT_PFHT200_v*,HLT_PFHT780_v*,HLT_PFHT890_v*,HLT_PFHT1050_v*,HLT_PFMET*_PFMHT*_IDTight_v*,HLT_IsoMu27*,HLT_METnoMu*,HLT_PFJet40_GPUvsCPU_v* \
   --input /store/data/Run2025G/EphemeralHLTPhysics0/RAW/v1/000/398/183/00000/002bbd0c-b9ed-4758-b7a6-e2e13149ca34.root \
   > hltData_tmp.py

# copies of only the lines that i updated in the command above (on 03.03.2026)
#hltGetConfiguration /dev/CMSSW_16_0_0/GRun/V2 \
#--globaltag 151X_dataRun3_HLT_v1 \
#--eras Run3_2025 --l1-emulator uGT --l1 L1Menu_Collisions2025_v1_3_0_xml \

# added some more paths (on 15.04.2026), keep extra HT paths, should i also add more single jet paths? (for MET as before)
#   --path MC_*,HLTriggerF*,Status*,HLT_PFJet60_v*,HLT_PFJet140_v*,HLT_PFJet320_v*,HLT_PFJet500_v*,HLT_PFHT780_v*,HLT_PFHT890_v*,HLT_PFHT1050_v*,HLT_PFMET*_PFMHT*_IDTight_v*,HLT_IsoMu27*,HLT_METnoMu*,HLT_PFJet40_GPUvsCPU_v* \

#updated also this
#    --eras Run3_2026 --l1-emulator uGT --l1 L1Menu_Collisions2026_v1_0_0_xml \


# dump configuration (note: CMSSW_16_0_0_GRun)
edmConfigDump hltData_tmp.py > "${CMSSW_BASE}"/src/JMETriggerAnalysis/Common/python/configs/HLT_dev_CMSSW_16_0_0_GRun_configDump_data_selectedPaths.py

#test running it
#cmsRun tmp.py &> test.log
#cmsRun hltData.py &> hltData.log

#rm -f tmp.py
rm -f hltData_tmp.py



