#!/bin/bash

#python3 plotEfficienciesDPNote.py \
#  --input /eos/user/t/tchatzis/DPNoteSubmitter2025CJEC/JetMET0_Run2025CV2/ \
#  --merged_file /eos/user/t/tchatzis/DPNoteSubmitter2025CJEC/merged_test3.root \
#  --config ./plotsEfficiencies_configs/2025data_config.yaml \
#  --output_dir /eos/user/t/tchatzis/JetMET_eraC_test3/

#python3 plotEfficienciesDPNote.py \
#  --input /eos/user/t/tchatzis/DPNoteSubmitterNew/ \
#  --merged_file /eos/user/t/tchatzis/DPNoteSubmitterNew/merged.root \
#  --config ./plotsEfficiencies_configs/dpnote_config.yaml \
#  --output_dir /eos/user/t/tchatzis/DPNotePlotsTest/




python3 plotEfficienciesDPNote.py \
  --input /eos/user/b/blehtela/STEAM_Mar2026_OUT_20mar2026/JetMET/ \
  --merged_file /eos/user/b/blehtela/STEAM_Mar2026_OUT_20mar2026/JetMET/JetMETmerged.root \
  --config ./plotsEfficiencies_configs/2025data_config.yaml \
  --output_dir /eos/user/b/blehtela/STEAM_Mar2026_OUT_20mar2026/JetMET/


python3 plotEfficienciesDPNote.py \
  --input /eos/user/b/blehtela/STEAM_Mar2026_OUT_20mar2026/Muon/ \
  --merged_file /eos/user/b/blehtela/STEAM_Mar2026_OUT_20mar2026/Muon/Muonmerged.root \
  --config ./plotsEfficiencies_configs/2025data_config.yaml \
  --output_dir /eos/user/b/blehtela/STEAM_Mar2026_OUT_20mar2026/Muon/


