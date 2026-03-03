#!/bin/bash -e

# Taken from SWGuideGlobalHLT page : https://twiki.cern.ch/twiki/bin/view/CMSPublic/SWGuideGlobalHLT
hltGetConfiguration /dev/CMSSW_16_0_0/GRun \
   --globaltag 151X_dataRun3_HLT_v1 \
   --data \
   --unprescale \
   --output minimal \
   --max-events 100 \
   --eras Run3_2025 --l1-emulator uGT --l1 L1Menu_Collisions2025_v1_3_0_xml \
   --input /store/data/Run2025G/EphemeralHLTPhysics0/RAW/v1/000/398/183/00000/002bbd0c-b9ed-4758-b7a6-e2e13149ca34.root \
   > hltData_tmp.py


# dump configuration (note: CMSSW_16_0_0_GRun)
edmConfigDump hltData_tmp.py > "${CMSSW_BASE}"/src/JMETriggerAnalysis/Common/python/configs/HLT_dev_CMSSW_16_0_0_GRun_configDump_data.py

#test running it
#cmsRun tmp.py &> test.log
#cmsRun hltData.py &> hltData.log

#rm -f tmp.py
rm -f hltData_tmp.py



