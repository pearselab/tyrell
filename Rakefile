################################
# Headers ######################
################################
# Dependencies and wrapper functions
require './src/tyrell-util.rb'

# Sub-tasks (see below for groups with these names)
require './src/tyrell-download.rb'
require './src/tyrell-clean.rb'
require './src/tyrell-setup.rb'
require './src/tyrell-ms1_env_us.rb'
require './src/uk-r0-env.rb'

################################
# Global task definitions ######
################################
# Default task: help
task :default => :help
desc "Tyrell command overview"
task :help do
  puts "Tyrell - COVID-19 data/analysis management software"
  puts "\t\t\t\t\thttps://github.com/pearselab/tyrell"  
  puts "Useful commands:"
  puts "  rake install         - Setup Tyrell dependencies"
  puts "  rake ms1_env_us      - Repeat Smith et al. 2020 (DOI)"
  puts "  rake dwn_data_cases  - Download all case/mortality data"
  puts "  rake update_cases    - Update all case/mortality data"
  puts "  rake dwn_data        - Download all data (takes a long time)"
  puts "  rake cln_data        - Cleans (processes) all data (takes a long time)"
  puts "  rake save_space      - Delete raw-data unneeded after cleaning (RECOMMENDED)"
  puts "  rake reset           - Delete all 'cleaned' data in `clean-data`"
  puts "  rake clobber         - Delete all 'raw' data from `raw-data`"
  puts "  rake uk_modelling    - Run bayesian models for UK data, seperate from the US work"
  puts "  rake --tasks         - Lists everything Tyrell does (more than above)"
  puts "(Note: any missing/needed data is automatically downloaded;"
  puts " thus running `rake cln_data` will first run `rake dwn_data`)"
end

# Reset (clean)
CLEAN.include("clean-data/*")
CLEAN.include("ms-env/*.txt")
CLEAN.include("ms-env/*.pdf")
desc "Delete all 'cleaned' data from 'clean_data'"
task :reset => [:clean]
Rake::Task['clean'].clear_comments # Hides 'clean' from list of commands as name is confusing

# Clobber
CLOBBER.include("raw-data/*")
CLOBBER.include("imptf-models/*")
CLOBBER.include("rambaut-nomenclature/*")
Rake::Task['clobber'].comment = "Delete all data, including large downloads"

# Everything
desc "Run everything"
task :everything => [:before_everything, :install, :dwn_data, :cln_data, :ms1_env_us, :after_everything]
task :before_everything do
  puts "WARNING: About to run everything Tyrell can do. This takes a VERY long time"
  puts "\t and is likely NOT what you want to do. Run `rake help` for advice."
  puts "\t Press control-c or similar to cancel"
  puts "... regardless ..."
  puts ""
  puts "Starting ..."
end
task :after_everything do
  puts "Finished!"
end

# Install
desc "Install all software and setup tyrell folders"
task :install => [:before_install, "timestamp.yml", :folders, :r_packages]
task :before_install do
  puts "\t ... Installing software and setting up tyrell folders"
end

# Download data
desc "Download raw case data"
task :dwn_data_cases => ["raw-data/cases", :raw_jhu, "raw-data/cases/ecdc-cases.csv", "raw-data/cases/ecjrcdc-regions.csv", "raw-data/cases/ecjrcdc-countries.csv", "raw-data/cases/cvodidh-admin1.csv", "raw-data/cases/cvodidh-admin2.csv", "raw-data/cases/cvodidh-admin3.csv", "raw-data/cases/imperial-uk-pred.csv", "raw-data/cases/imperial-lmic-pred.csv", "raw-data/cases/ihme-summary.csv", "raw-data/cases/who-interventions.xlsx", "raw-data/cases/imperial-interventions.csv", "raw-data/cases/oxford-interventions.csv", "raw-data/cases/vaccinations.csv", :dwn_uk_deaths]

desc "Download all raw data"
task :dwn_data => [:before_dwn_data,
                   "raw-data/UK-population.xls", # need to do this first otherwise uk case script won't run
                   :dwn_data_cases,
                   "raw-data/gis", "raw-data/gis/denvfoimap-raster.RDS", :raw_gadm,
                   "raw-data/gis/NUTS_Level_1__January_2018__Boundaries", "raw-data/gis/Local_Authority_Districts__December_2019__Boundaries_UK_BFC",
                   "ext-data/",
                   "raw-data/google-mobility.csv", "raw-data/USstatesCov19distancingpolicy.csv", "raw-data/usa-regions.csv", 
                   "raw-data/pop-urban-pct-historical.xls", "ext-data/APM-Report.xls",
                   "raw-data/genetic", :raw_nxtstr, :raw_imptfmods, "raw-data/rambaut-nomenclature",
                   :clim_av, :pop_av, # new tasks here that download climate and pop data from new repo
                   :ms1_zenodo] # this task to pull the Rt data for our analysis from the zenodo version
                   
task :before_dwn_data do
  puts "\t ... Downloading raw data (can take a long time)"
end

# Clean data
desc "Clean (process) all raw data"
task :cln_data => [:before_cln_data, :cln_gadm, :cln_denvfoi_rasters, :cln_worldclim, :cln_airport_data]
task :before_cln_data do
  puts "\t ... Processing raw data"
end

# Save space
desc "Save disk space by deleting large `raw-data` files"
task :save_space do 
  puts "\t ... Saving disk space by deleting large, raw GIS files"
  Dir.chdir("raw-data/gis") do
    (FileUtils.rm Dir["cdsar5-1month_mean_Global_ea_2t_20*.grib"]) rescue {}
    (FileUtils.rm "cds-era5-temp-hourly.grib") rescue {}
    (FileUtils.rm "cds-era5-humid-hourly.grib") rescue {}
    (FileUtils.rm "cds-era5-uv-hourly.grib") rescue {}
    (FileUtils.rm "cds-cams-pm2pt5-hourly.grib") rescue {}
    (FileUtils.rm Dir["gadm36*"]) rescue {}
  end
end

# Update data
desc "Update case/mortality raw-data"
task :update_cases => [:before_update_cases, :update_case_data, :purge_clean_cases]
task :before_update_cases do
  puts "\t ... Updating changable raw data; purging relevant clean data"
end

desc "Update raw data"
task :update_case_data do
  FileUtils.rm_r "raw-data/cases"
  Rake.application[:dwn_data_cases].invoke
end

desc "Purge clean data"
task :purge_clean_cases do
  FileUtils.chdir("clean-data") do
    # ... right now, nothing ...
  end
end

# MS1 - environmental impacts on US COVID
desc "Repeating manusript #1 - environmental impacts"
task :ms1_env_us => [:before_ms1_env, :install, :ms1_r0_models, :ms1_rt_models, :ms1_build]
task :before_ms1_env do
  puts "\t ... Repeating MS#1 - US environmental impacts"
end

# External models (Imperial COVID Response models)
desc "Run externally-generated models"
task :ext_models => [:before_ext_models, :ext_imptf]
task :before_ext_models do
  puts "\t ... Running externally-generated models (takes a long time and is stochastic)"
end

task :ext_imptf => ["imptf-models/covid19model-1.0/results/base-12345.Rdata", "imptf-models/covid19model-2.0/results/base-12345.Rdata", "imptf-models/covid19model-3.0/results/base-12345.Rdata", "imptf-models/covid19model-4.0/results/Italy/results/base-12345-stanfit.Rdata", "imptf-models/covid19model-5.0/results/Brazil/results/base-12345-stanfit.Rdata"]
file "imptf-models/covid19model-1.0/results/base-12345.Rdata" do
  Dir.chdir("imptf-models/covid19model-1.0") do
    `PBS_JOBID=12345
    Rscript base.r > STDOUT-rake-base-12345`
  end
end
file "imptf-models/covid19model-2.0/results/base-12345.Rdata" do
  Dir.chdir("imptf-models/covid19model-2.0") do
    `PBS_JOBID=12345
    Rscript base.r > STDOUT-rake-base-12345`
  end
end
file "imptf-models/covid19model-3.0/results/base-12345.Rdata" do
  Dir.chdir("imptf-models/covid19model-3.0") do
    `PBS_JOBID=12345
    Rscript base_general.r -F > STDOUT-rake-base-12345`
  end
end
file "imptf-models/covid19model-4.0/results/Italy/results/base-12345-stanfit.Rdata" do
  Dir.chdir("imptf-models/covid19model-4.0") do
    `PBS_JOBID=12345
    Rscript base-Italy.r -F > STDOUT-rake-base-12345`
  end
end
file "imptf-models/covid19model-5.0/results/Brazil/results/base-12345-stanfit.Rdata" do
  Dir.chdir("imptf-models/covid19model-5.0") do
    `PBS_JOBID=12345
    Rscript base-Brazil.r > STDOUT-rake-base-12345`
  end
end
file "imptf-models/covid19model-6.0/results/usa/results/base-12345-stanfit.Rdata" do
  Dir.chdir("imptf-models/covid19model-6.0") do
    `PBS_JOBID=12345
    Rscript base-usa.r > STDOUT-rake-base-12345`
  end
end


# UK bayesian modelling in epidemia
desc "Modelling Rt across UK LTLA regions using epidemia"
task :uk_modelling => [:before_uk_modelling, :uk_ltla_mobility, :uk_regional_mobility, :cln_cdsear5_uk, :cln_uk_popdens, :join_uk_deaths_climate, :uk_epiedmia_models]
task :before_uk_modelling do
  puts "\t ... Cleaning UK data, then running epidemia model"
end
