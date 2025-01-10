import os
############# USER DEFINED ##################################################
# Directory with input files
#input_directory = "/eos/user/t/tchatzis/JRA_NTuples_Winter24"
input_directory = "/eos/user/b/blehtela/JRA_NTuples_Winter24"
#logfile_directory = os.environ['CMSSW_BASE']+'/src/blehtela-forks/JMETriggerAnalysis/JESCorrections/test/htc_out_2024'
logfile_dirname = "htc_out_2024"

#bpix_categories = ['noBPix','BPix','BPixPlus','BPixMinus']
bpix_categories = ['noBPix','BPix'] #try with only two now, maybe jobs ran too long
flatPU_label = 'FlatPU0to80'
noPU_label = 'NoPU'

#############################################################################

# Loop over each input file
#with open("sub_jecs_total_forBPix.htc", "w") as job_script:
#with open("sub_jecs_test_07jan_bettina.htc", "w") as job_script: #different name for my testing phase

#create directory for log files (rename, if wanting to overwrite, could set exist_ok=True)
os.makedirs(logfile_dirname, exist_ok=False)

for bpix_cat in bpix_categories:
    jet_categories = ['ak4pfHLT','ak8pfHLT']
    #jet_categories = ['ak4pfHLT'] #try only ak4 to see if it does all steps then
    if bpix_cat == 'noBPix':
        jet_categories = ['ak4pfHLT','ak8pfHLT','ak4caloHLT','ak8caloHLT']
        #jet_categories = ['ak4pfHLT','ak4caloHLT'] #only ak4 (see above)
    for jet_cat in jet_categories:
        filename = f"sub_jecs_total_{bpix_cat}_{jet_cat}.htc"
        with open(filename, "w") as job_script: #different name for my testing phase
            # Common parts in all jobs
            job_script.write("executable            = fitJESCs\n")
            job_script.write("getenv                = True\n")
            job_script.write("should_transfer_files = YES\n")
            job_script.write("when_to_transfer_output = ON_EXIT_OR_EVICT\n")
            job_script.write("output_destination =  %s\n"%(os.environ['CMSSW_BASE']+'/src/blehtela-forks/JMETriggerAnalysis/JESCorrections/test'))
            job_script.write("MY.XRDCP_CREATE_DIR = True\n")
            job_script.write("MY.WantOS = \"el8\"\n")
            job_script.write("\n"*5)
            job_script.write(f"transfer_output_files = JESCs_2024_{bpix_cat}\n")
 
            job_script.write("\n"*5)
            job_script.write(f"arguments    =  -i_nopu {input_directory}/JRA_{noPU_label}{bpix_cat}.root -i_flatpu {input_directory}/JRA_{flatPU_label}{bpix_cat}.root -o JESCs_2024_{bpix_cat} -b -j {jet_cat} -n 1000000\n")
            job_script.write(f"output       = {logfile_dirname}/{bpix_cat}_{jet_cat}.out\n")
            job_script.write(f"error        = {logfile_dirname}/{bpix_cat}_{jet_cat}.err\n")
            job_script.write(f"log          = {logfile_dirname}/{bpix_cat}_{jet_cat}.log\n")
            #job_script.write("+JobFlavour           = \"workday\"\n")
            job_script.write("+JobFlavour           = \"tomorrow\"\n") #try a bit longer in case jobs run too long
            #job_script.write("+JobFlavour           = \"testmatch\"\n") #try a even longer
            job_script.write("queue\n")

            job_script.close()

            print("Submitting: condor_submit ",filename)
            os.system(f'condor_submit {filename}')


