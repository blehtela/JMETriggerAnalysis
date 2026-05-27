# JECs for Phase2

# Setup
In order to use the JECs scripts you need the JetMETAnalysis CMSSW package.
To do this the setup should be as follows:
```bash
cmsrel CMSSW_16_0_1_pre4
cd CMSSW_16_0_1_pre4/src
cmsenv
git cms-init

git clone https://github.com/theochatzis/JetMETAnalysis.git -b hlt_phase2

git clone https://github.com/theochatzis/JMETriggerAnalysis.git -b master_phase2

scram b -j 8
```

# Derivation
## Step1: Produce JRA NTuples
The JRA NTuples are flat NTuples that have the jets as tree entries and their properties as branches. It also has as branches the pt eta etc of the matched gen jets.
To produce such NTuples you can use the `NTuplizers/test/jescJRA_cfg.py` there is a local example you can try first to see things work:
```bash
./runLocallyJRA.sh
```
The input sample used should be always a FlatPt QCD sample in order to not bias the pT of the jet.

If this checks out to submit with condor you may use  `NTuplizers/test/scripts/makeNTuples_hltPhase2_JRA_updatedCondor`.

## Step2: The correction derivation
Take the output JRA NTuple files and hadd them. Then the full hadded output can be used as input for the fits procedure.
The code is in `NTuplizers/test/JESCorrections`.

In the `fitJESCs_phase2` executable change the name of the input sample with yours, and the campaign name as this will be given to the tags.

Later change the `fast_jecs` for the output names etc you may want to use. 

Then you can simply run:
```
./fast_jecs
```
This should run and produce the jecs in the `[output-dir]/ak4pfpuppiHLT/jesc/` as `.txt` format and `[output-dir]/ak4pfpuppiHLT/DBfile/` as sqlite `.db` file format.

# Checks of results
## Check ther raw responses distributions
Use the script `plot_raw_response_grids_by_eta.py` for example:

```bash
python3 plot_raw_response_grids_by_eta.py jescs_Phase2Spring24/ak4pfpuppiHLT/plots_step01/histogram_ak4pfpuppiHLTl1_step01.root --alg ak4pfpuppiHLT --normalize
```
## Check the fits
```bash
python3 python3 plot_abs_cor_vs_jetpt_grid.py jescs_Phase2Spring24/ak4pfpuppiHLT/l2p3.root -o AbsCorVsJetPt_grid.pdf --cols 4
```
## Check the corrected responses distributions
Use the script `plot_response_grids_by_eta.py` for example:

```bash
python3 plot_response_grids_by_eta.py ./jescs_Phase2Spring24/ak4pfpuppiHLT/plots_step04/ClosureVsRefPt.root --alg ak4pfpuppiHLT --normalize
```
