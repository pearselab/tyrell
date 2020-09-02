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

################################
# Global task definitions ######
################################
# Default task: help
task :default => :help
desc "Tyrell command overview"
task :help do
  puts "Tyrell - COVID-19 data/analysis management software"
  puts ""  
  puts "Useful commands:"
  puts "\trake install         - Setup Tyrell dependencies (RECOMMENDED first command)"
  puts "\trake ms1_env_US      - Repeat US environmental impacts MS (Smith et al. 2020 DOI)"
  puts "\trake dwn_data_cases  - Download all case/mortality data"
  puts "\trake cln_data_cases  - Cleans (processes) all case/mortality data"
  puts "\trake update_data     - Update data with latest releases"
  puts "\trake dwn_data        - Download all data (including GIS data - takes a long time)"
  puts "\trake cln_data        - Cleans (processes) all data (including GIS data - takes a long time)"
  puts "\trake save_space      - Deletes large 'raw' files not needed after cleaning (RECOMMENDED)"
  puts "\trake reset           - Delete all 'cleaned' data from `rake cln_data`"
  puts "\trake clobber         - Delete all 'raw' data from `rake raw_data`"
  puts "\trake --tasks         - Lists all tasks Tyrell can perform (many more than above)"
  puts "\trake "
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
task :everything => [:before_everything, :install, :dwn_data, :cln_data, :ms1_env, :after_everything]
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
task :install => [:before_install, "timestamp.yml", :folders, :r_packages, :setup_cds_api,:setup_nasa_api]
task :before_install do
  puts "\t ... Installing software and setting up tyrell folders"
end

# Download data
desc "Download all raw data"
task :dwn_data => [:before_dwn_data, :raw_jhu, "raw-data/ecdc-cases.csv", "raw-data/ecjrcdc-regions.csv", "raw-data/ecjrcdc-countries.csv", "raw-data/uk-phe-deaths.csv", "raw-data/uk-phe-cases.csv", "raw-data/cvodidh-admin1.csv", "raw-data/cvodidh-admin2.csv", "raw-data/cvodidh-admin3.csv", "raw-data/imperial-europe-pred.csv", "raw-data/imperial-usa-pred.csv", "raw-data/imperial-usa-pred-2020-05-25.csv", "raw-data/imperial-lmic-pred.csv", :raw_ihme, :raw_nxtstr, "raw-data/who-interventions.xlsx", "raw-data/imperial-interventions.csv", "raw-data/oxford-interventions.csv", :raw_imptfmods, "raw-data/rambaut-nomenclature", "raw-data/denvfoimap-raster.RDS", :raw_gadm, "raw-data/cds-era5-temp-hourly.grib", "raw-data/cds-era5-humid-hourly.grib", "raw-data/cds-era5-uv-hourly.grib", "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif", "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif", "raw-data/google-mobility.csv", :copy_usa_interventions]
task :before_dwn_data do
  puts "\t ... Downloading raw data (can take a long time)"
end

# Clean data
desc "Process all raw data"
task :cln_data => [:before_cln_data, :cln_gadm, :cln_denvfoi_rasters, :cln_worldclim, :cln_cdsear5_hourly, :delete_cdsear5_hourly, :cln_cdsear5_daily, :cln_gpw_popdens, :join_R_climate]
task :before_cln_data do
  puts "\t ... Processing raw data"
end

# Update data
desc "Update raw-data and purge calculated clean-data"
task :update_data => [:before_update_data, :update_raw_data, :purge_clean_data]
task :before_update_data do
  puts "\t ... Updating changable raw data; purging relevant clean data"
end

desc "Update raw data"
task :update_raw_data do
  FileUtils.chdir("raw-data") do
    FileUtils.rm Dir["ihme-*"]
    FileUtils.rm Dir["jh-*"]
    FileUtils.rm Dir["imperial-*"]
    FileUtils.rm Dir["nxtstr-*"]
  end
  FileUtils.rm_r "rambaut-nomenclature/"
  Rake.application[:dwn_data].invoke
end

desc "Purge clean data"
task :purge_clean_data do
  FileUtils.chdir("clean-data") do
    # ... right now, nothing ...
  end
end

# MS1 - environmental impacts on US COVID
desc "Repeating manusript #1 - environmental impacts"
task :ms1_env => [:before_ms1_env, :r0_models, :rt_models, :ms1_build]
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




