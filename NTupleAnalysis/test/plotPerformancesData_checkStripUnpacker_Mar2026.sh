#!/bin/bash
source env.sh

# directory with input(s) 
#INPDIR=/eos/user/t/tchatzis/samples2023/
#INPDIR=/eos/cms/store/group/phys_jetmet/blehtela/checkCAtuning_06Feb2026/   #dataharvested_checkCAtuning_10Feb2026.root
#/eos/cms/store/group/phys_jetmet/blehtela/checkStripUnpacker_03Mar2026/checkStripUnpacker_08mar2026_OUT_performancesRAW/checkStripUnpacker_03Mar2026_Muon0-Run2025G-v1_default/dataharvested_checkStripUnpacker_08Mar2026_default.root
INPDIR=/eos/cms/store/group/phys_jetmet/blehtela/checkStripUnpacker_03Mar2026/checkStripUnpacker_08mar2026_OUT_performancesRAW/  #dataharvested_checkStripUnpacker_08Mar2026_[default, stripUnpackerTRKcase1].root

#OUTDIR=./plots_test_winter24
#OUTDIR=/eos/user/t/tchatzis/plots_calo_thresholds/
#OUTDIR=/eos/user/b/blehtela/plots_updatedCAtuning_Feb2026/
#OUTDIR=/eos/user/b/blehtela/plots_updatedCAtuning_Feb2026
#OUTDIR=/eos/user/b/blehtela/jmetrigger/plots_stripUnpacker_Mar2026
OUTDIR=/eos/user/b/blehtela/jmetrigger/plots_stripUnpacker_Mar2026_updateAttempt #trying to improve the legend


#DATANAME=dataharvested_checkCAtuning_11Feb2026.root
DATANAME=dataharvested_checkStripUnpacker_08Mar2026
#dataharvested_checkStripUnpacker_08Mar2026_[default, stripUnpackerTRKcase1].root



rm -rf ${OUTDIR}   #should keep this...removed it to check what happens
#mkdir ${OUTDIR}   #debugging attempt

#-i path:legend:linecolor:linestlye:markerstyle:markercolor:markersize
#reserving green (8) for offline maybe, so i will use a nice blue (65) for default and orange (93) for the changed one (instead of pink, 6)
#version_check_data_new \
jmePlots.py -k run3_jme_compareTRK6 \
-o ${OUTDIR} \
-i ${INPDIR}checkStripUnpacker_03Mar2026_Muon0-Run2025G-v1_default/harvesting/${DATANAME}_default.root:'default':65:1:24 \
   ${INPDIR}checkStripUnpacker_03Mar2026_Muon0-Run2025G-v1_stripUnpackerTRKcase1/harvesting/${DATANAME}_stripUnpackerTRKcase1.root:'het. strip unpacker':93:1:28 \
-l '#font[61]{CMS} #font[52]{Run-3 Data} Muon Dataset (Era 2025G)' -v 100

ls ${OUTDIR}

#jmePlots.py -k version_check_data_new \
#-o ${OUTDIR} \
#-i /eos/user/t/tchatzis/samples2023/test_calojet_default/harvesting/data.root:'Default CaloTower':1:1:20 \
#   /eos/user/t/tchatzis/samples2023/test_calojet_ecal_thresh/harvesting/data.root:'PF RecHit Threshold':632:1:20 \
#-l '#font[61]{CMS} #font[52]{Run-3 Data} Muon Dataset (Era G)'

# jmePlots.py -k version_check_data_new \
# -o ${OUTDIR} \
# -i /eos/user/t/tchatzis/samples2023/before_fpix_default/harvesting/data.root:'No FPix issue':632:1:20 \
#    /eos/user/t/tchatzis/samples2023/after_fpix_default/harvesting/data.root:'FPix issue (w/o doublets)':800:1:20 \
#    /eos/user/t/tchatzis/samples2023/after_fpix_doublet/harvesting/data.root:'FPix issue (w/ doublets)':1:1:20 \
# -l '#font[61]{CMS} #font[52]{Run-3 Data} EphemeralHLTPhysics Era F'


rm ${OUTDIR}/NoSelection/*mass*.png
#rm ${OUTDIR}/NoSelection/*MatchedTo*_pt_over*.png

# organize plots into folders

Regions=(
EtaIncl_
HB_
#HBPt0_
#HBPt1_
#HBPt2_
#HBPt3_
#HEPt0_
#HEPt1_
#HEPt2_
#HEPt3_
HE1_
HE2_
HF_
# BPix_plus4_
# BPix_minus4_
# BPix_plus8_
# BPix_minus8_
BPix_
BPixVeto_
FPix_
FPixVeto_
)

#These i had in my config performances_raw.yaml of the submitted
#jetCategoryLabels:
#  - _EtaIncl
#  - _Eta2p5
#  - _HB
#  - _HE1
#  - _HE2
#  - _HF
#  - _BPix
#  - _BPixVeto
#  - _FPix
#  - _FPixVeto


ls ${OUTDIR}/NoSelection

for region_name in "${Regions[@]}"; do

  echo "Moving plots for region ${region_name}. In NoSelection folder, we have: "   #debugging
  ls -laht ${OUTDIR}/NoSelection/*${region_name}*.png

  mkdir -p ${OUTDIR}/NoSelection/${region_name}
  #ls ${OUTDIR}/NoSelection/${region_name} #debugging
  mv ${OUTDIR}/NoSelection/*${region_name}*.png ${OUTDIR}/NoSelection/${region_name}

  mkdir -p ${OUTDIR}/NoSelection/${region_name}/efficiency
  mkdir -p ${OUTDIR}/NoSelection/${region_name}/response
  mkdir -p ${OUTDIR}/NoSelection/${region_name}/resolution
  mkdir -p ${OUTDIR}/NoSelection/${region_name}/jet_content
  mkdir -p ${OUTDIR}/NoSelection/${region_name}/kinematics
  
  mv ${OUTDIR}/NoSelection/${region_name}/*eff.png ${OUTDIR}/NoSelection/${region_name}/efficiency
  mv ${OUTDIR}/NoSelection/${region_name}/*Mean*.png ${OUTDIR}/NoSelection/${region_name}/response
  mv ${OUTDIR}/NoSelection/${region_name}/*RMS*.png ${OUTDIR}/NoSelection/${region_name}/resolution
  mv ${OUTDIR}/NoSelection/${region_name}/*Multiplicity*.png ${OUTDIR}/NoSelection/${region_name}/jet_content
  mv ${OUTDIR}/NoSelection/${region_name}/*Fraction*.png ${OUTDIR}/NoSelection/${region_name}/jet_content
  mv ${OUTDIR}/NoSelection/${region_name}/*.png ${OUTDIR}/NoSelection/${region_name}/kinematics
done

#rm ${OUTDIR}/NoSelection/*.png

unset INPDIR region_name Regions OUTDIR pt_region_number
