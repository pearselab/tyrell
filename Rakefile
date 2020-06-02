################################
# Headers ######################
################################
require 'rake'
require 'rake/clean'

require './src/tyrell-util.rb'

################################
# Global tasks #################
################################
task :default => :build

desc "Run analyses"
task :build => [:before_build, :install, :dwn_data, :cln_data, :after_build]
task :before_build do
  puts "Starting ..."
end
task :after_build do
  puts "Finished!"
end

CLOBBER.include("raw-data/*")
CLOBBER.include("imptf-models/*")
CLOBBER.include("rambaut-nomenclature/*")
CLEAN.include("clean-data/*")
CLEAN.include("figures/*")
CLEAN.include("models/*")
CLEAN.include("forecasts/*")

################################
# Install software and tyrell ##
################################
desc "Install all software and setup tyrell folders"
task :install => [:before_install, "timestamp.yml", :folders, :r_packages]
task :before_install do
  puts "\t ... Installing software and setting up tyrell folders"
end

desc "Install R packages"
task :r_packages do `Rscript "src/packages.R"` end

desc "Setup tyrell folders"
task :folders => ["raw-data", "clean-data", "figures", "models", "forecasts", "imptf-models"]
directory 'raw-data'
directory 'clean-data'
directory 'figures'
directory 'models'
directory 'forecasts'
directory 'imptf-models'

desc "Setup timestamping"
file "timestamp.yml" do File.open("timestamp.yml", "w") end

################################
# Download raw data ############
################################
desc "Download all raw data"
task :dwn_data => [:before_dwn_data, :raw_jhu, "raw-data/ecdc-cases.csv", "raw-data/imperial-europe-pred.csv", :raw_ihme, :raw_nxtstr, "raw-data/who-interventions.xlsx", "raw-data/imperial-interventions.csv", :raw_imptfmods, "rambaut-nomenclature", "raw-data/denvfoimap-raster.RDS", :raw_gadm]
task :before_dwn_data do
  puts "\t ... Downloading raw data (can take a long time)"
end

gadm_shapefiles = ["raw-data/gadm36_0.cpg", "raw-data/gadm36_0.dbf","raw-data/gadm36_0.prj","raw-data/gadm36_0.shp","raw-data/gadm36_0.shx","raw-data/gadm36_1.cpg","raw-data/gadm36_1.dbf","raw-data/gadm36_1.prj","raw-data/gadm36_1.shp","raw-data/gadm36_1.shx","raw-data/gadm36_2.cpg","raw-data/gadm36_2.dbf","raw-data/gadm36_2.prj","raw-data/gadm36_2.shp","raw-data/gadm36_2.shx","raw-data/gadm36_3.cpg","raw-data/gadm36_3.dbf","raw-data/gadm36_3.prj","raw-data/gadm36_3.shp","raw-data/gadm36_3.shx","raw-data/gadm36_4.cpg","raw-data/gadm36_4.dbf","raw-data/gadm36_4.prj","raw-data/gadm36_4.shp","raw-data/gadm36_4.shx","raw-data/gadm36_5.cpg","raw-data/gadm36_5.dbf","raw-data/gadm36_5.prj","raw-data/gadm36_5.shp","raw-data/gadm36_5.shx"]
desc "Download GADM global shapefiles"
task :raw_gadm => gadm_shapefiles
def raw_gadm_func(shapefiles)
  Dir.chdir("raw-data") do 
    unzip(stream_file("https://biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip", "gadm.zip"))
    FileUtils.rm "gadm.zip"
    FileUtils.rm "license.txt"
  end
  shapefiles.map {|x| date_metadata(x)}
end
gadm_shapefiles.each do |sub_file|
  file sub_file do raw_gadm_func(gadm_shapefiles) end
end

desc "Download Johns Hopkins data"
task :raw_jhu => ["raw-data/jh-global-confirmed.csv", "raw-data/jh-us-confirmed.csv", "raw-data/jh-us-deaths.csv", "raw-data/jh-global-deaths.csv", "raw-data/jh-global-recovered.csv"]
file "raw-data/jh-global-confirmed.csv" do dwn_file("raw-data", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv", "jh-global-confirmed.csv") end
file "raw-data/jh-us-confirmed.csv" do dwn_file("raw-data", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv", "jh-us-confirmed.csv") end
file "raw-data/jh-us-deaths.csv" do dwn_file("raw-data", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv", "jh-us-deaths.csv") end
file "raw-data/jh-global-deaths.csv" do dwn_file("raw-data", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv", "jh-global-deaths.csv") end
file "raw-data/jh-global-recovered.csv" do dwn_file("raw-data", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv", "jh-global-recovered.csv") end

desc "Download Institute for Health Metrics and Evaluation (IHME)"
ihme_files = ["raw-data/ihme-summary.csv", "raw-data/ihme-hospitalisation.csv"]
task :raw_ihme => ihme_files
def raw_ihme(ihme_files)
  Dir.chdir("raw-data") do
    unzip(stream_file("https://ihmecovid19storage.blob.core.windows.net/latest/ihme-covid19.zip", "ihme.zip"))
    FileUtils.rm "ihme.zip"
    FileUtils.mv Dir["*/Hospitalization_all_locs.csv"][0], "ihme-hospitalisation.csv"
    FileUtils.mv Dir["*/Summary_stats_all_locs.csv"][0], "ihme-summary.csv"
    FileUtils.rm_r Dir["*/"]
  end
  ihme_files.map {|x| date_metadata(x)}
end
ihme_files.each {|x| file x do raw_ihme(ihme_files) end}

file "raw-data/jh-global-confirmed.csv" do dwn_file("raw-data", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv", "jh-global-confirmed.csv") end

desc "Download ECDC cases"
file "raw-data/ecdc-cases.csv" do dwn_file("raw-data", "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", "ecdc-cases.csv") end

desc "Download Imperial COVID-19 Europe predictions"
file "raw-data/imperial-europe-pred.csv" do dwn_file("raw-data", "https://mrc-ide.github.io/covid19estimates/data/results.csv", "imperial-europe-pred.csv") end

desc "Download NextStrain data"
nxtstr_files = ["raw-data/nxtstr-sel-meta.tsv", "raw-data/nxtstr-meta.tsv", "raw-data/nxtstr-authors.tsv", "raw-data/nxtstr-tree-mut.tre", "raw-data/nxtstr-tree-date.tre"]
task :raw_nxtstr => nxtstr_files
def raw_nxtstr(nxtstr_files)
  options = Selenium::WebDriver::Chrome::Options.new#(args: ['headless'])
  #options.add_preference(:download, "directory_upgrade": true, "prompt_for_download": false, "default_directory": Dir.pwd)
  driver = Selenium::WebDriver.for(:chrome, options: options)
  driver.navigate.to "https://nextstrain.org/ncov/global"
  sleep 15
  first = driver.find_elements(css: "button")[-1]
  first.click
  sleep 2
  downloads = driver.find_elements(css: "button")[0..4]
  downloads.map {|x| x.click; sleep 5}
  Dir.chdir("raw-data") do
    FileUtils.mv "#{File.expand_path("~")}/Downloads/nextstrain_ncov_global_selected_metadata.tsv", "nxtstr-sel-meta.tsv"
    FileUtils.mv "#{File.expand_path("~")}/Downloads/nextstrain_ncov_global_metadata.tsv", "nxtstr-meta.tsv"
    FileUtils.mv "#{File.expand_path("~")}/Downloads/nextstrain_ncov_global_authors.tsv", "nxtstr-authors.tsv"
    FileUtils.mv "#{File.expand_path("~")}/Downloads/nextstrain_ncov_global_tree.nwk", "nxtstr-tree-mut.tre"
    FileUtils.mv "#{File.expand_path("~")}/Downloads/nextstrain_ncov_global_timetree.nwk", "nxtstr-tree-date.tre"
  end
  nxtstr_files.map {|x| date_metadata(x)}
end
nxtstr_files.each {|x| file x do
                     begin
                       raw_nxtstr(nxtstr_files)
                     rescue Exception => e
                       puts "\t ... ... Selenium missing; skipping NextStrain; don't try to fix please"
                     end
                   end}

desc "Download WHO intervention data"
file "raw-data/who-interventions.xlsx" do
  Dir.chdir("raw-data") do
    unzip(stream_file("https://www.who.int/docs/default-source/documents/phsm/20200514-phsm-who-int.zip", "who.zip"))
    FileUtils.mv "data_export_NCOV_PHM_V_RAW_PHSM.xlsx", "who-interventions.xlsx"
    FileUtils.rm ["Glossary of COVID-related PHSM_15_upload.pdf","4PHSM data flow and dataset descriptions.pdf", "who.zip"]
  end
end

desc "Download Imperial intervention data"
file "raw-data/imperial-interventions.csv" do
  Dir.chdir("raw-data") do
    stream_file("https://github.com/ImperialCollegeLondon/covid19model/raw/master/data/interventions.csv", "imperial-interventions.csv")
  end
end

desc "Download Imperial Task Force releases"
imptf_folders = ["imptf-models/covid19model-1.0", "imptf-models/covid19model-2.0", "imptf-models/covid19model-3.0", "imptf-models/covid19model-4.0", "imptf-models/covid19model-5.0", "imptf-models/covid19model-6.0"]
task :raw_imptfmods => imptf_folders
def raw_imptfmods(imptf_folders)
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v1.0.zip", "tf1.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v2.0.zip", "tf2.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v3.0.zip", "tf3.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v4.0.zip", "tf4.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v5.0.zip", "tf5.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v6.0.zip", "tf6.zip"))
    FileUtils.rm ["tf1.zip", "tf2.zip", "tf3.zip", "tf4.zip", "tf5.zip", "tf6.zip"]
  end
  imptf_folders.map {|x| date_metadata(x)}
end
imptf_folders.each {|x| file x do raw_imptfmods(imptf_folders) end}

desc "Download Rambaut et al. phylo-nomenclature"
directory "rambaut-nomenclature" do
  unzip(stream_file("https://github.com/hCoV-2019/lineages/archive/master.zip", "rambaut-nomenclature.zip"))
  FileUtils.mv "lineages-master", "rambaut-nomenclature"
  FileUtils.rm "rambaut-nomenclature.zip"
end

desc "Download DENVfoiMap raster data"
file "raw-data/denvfoimap-raster.RDS" do
  stream_file("https://mrcdata.dide.ic.ac.uk/resources/DENVfoiMap/all_squares_env_var_0_1667_deg.rds", "raw-data/denvfoimap-raster.RDS")
end

################################
# Running external models ######
################################
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

################################
# Clean data ###################
################################
desc "Process all raw data"
task :cln_data => [:before_cln_data, :cln_gadm, :cln_denvfoi_rasters, "clean-data/worldclim-countries.RDS"]
task :before_cln_data do
  puts "\t ... Processing raw data"
end

desc "Clean and process GADM data"
task :cln_gadm => ["clean-data/gadm-countries.RDS", "clean-data/gadm-states.RDS"]
def gadm_cleaning()
  `Rscript src/clean-gadm.R`
  date_metadata "clean-data/gadm-countries.RDS"
  date_metadata "clean-data/gadm-states.RDS"
end
file "clean-data/gadm-countries.RDS" do gadm_cleaning() end
file "clean-data/gadm-states.RDS" do gadm_cleaning() end


desc "Clean WORLDCLIM data"
file "clean-data/worldclim-countries.RDS" => ["clean-data/gadm-countries.RDS","clean-data/gadm-states.RDS"] do
  `Rscript src/worldclim-countries.R`
  # Remove extra .rds files (Michael, fix this in the script?)
  FileUtils.rm ["gadm36_AUT_0_sp.rds","gadm36_DEU_0_sp.rds","gadm36_FRA_0_sp.rds","gadm36_NOR_0_sp.rds","gadm36_BEL_0_sp.rds","gadm36_DNK_0_sp.rds","gadm36_GBR_0_sp.rds","gadm36_SWE_0_sp.rds","gadm36_CHE_0_sp.rds","gadm36_ESP_0_sp.rds","gadm36_ITA_0_sp.rds"]
  FileUtils.rm_r "wc10"
  date_metadata "clean-data/worldclim-countries.RDS"
end

desc "Clean DENVfoiMap raster data"
task :cln_denvfoi_rasters => ["clean-data/denvfoimap-rasters-countries.csv", "clean-data/denvfoimap-rasters-states.csv", "clean-data/gadm-countries.csv","clean-data/gadm-states.csv"]
def denvfoimap_rasters()
  `Rscript "src/denvfoimap-rasters.R"`
  date_metadata "clean-data/denvfoimap-rasters-countries.csv"
  date_metadata "clean-data/denvfoimap-rasters-states.csv"
end
file "clean-data/denvfoimap-rasters-countries.csv" do denvfoimap_rasters() end
file "clean-data/denvfoimap-rasters-states.csv" do denvfoimap_rasters() end

################################
# Update data ##################
################################
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

################################
# Fit models ###################
################################
desc "Fitting our models"
task :fit_models => [:before_fit_models, :fit_proposal]
task :before_fit_models do
  puts "\t ... Fitting our models"
end

desc "Fitting proposal models"
task :fit_proposal do
  puts "Yeah, I'm working on it, OK?..."
end

desc "Fitting modified Imperial models"
task :fit_env_imp do
  puts "Hey, if you're expecting this to work... Don't do that"
  FileUtils.cp "bayes-env/stan-europe.R", "imptf-models/covid19model-6.0/"
  FileUtils.cp "bayes-env/stan-europe.stan", "imptf-models/covid19model-6.0/stan-models/"
  FileUtils.cp "clean-data/climate_array.RDS", "imptf-models/covid19model-6.0/"
  Dir.chdir "imptf-models/covid19model-6.0/" do
  `Rscript stan-europe.R > STDOUT-europe`
  end
  Dir.chdir "bayes-env" do
    `Rscript downstream.R > raw-results.txt`
  end
end
