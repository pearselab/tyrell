################################
# Headers ######################
################################
require 'rake'
require 'rake/clean'

require './src/tyrell-util.rb'

def shp_fls(stem, drop_cpg=false)
  if drop_cpg
    return ["dbf","prj","shp","shx"].map {|x| "#{stem}.#{x}"}
  else
    return ["cpg","dbf","prj","shp","shx"].map {|x| "#{stem}.#{x}"}
  end
end

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
CLEAN.include("bayes-env/*.txt")

################################
# Install software and tyrell ##
################################
desc "Install all software and setup tyrell folders"
task :install => [:before_install, "timestamp.yml", :folders, :r_packages, :setup_cds_api]
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
directory 'ext-data'

desc "Setup timestamping"
file "timestamp.yml" do File.open("timestamp.yml", "w") end

task :setup_cds_api do
  unless File.exists?("config.yml") then
    puts "\t ... ... No config.yml file; cannot configure CDS data download"
    next
  end
  config = YAML.load_file("config.yml")
  unless config["cds"]["key"] and config["cds"]["key"]!="your-key-here" then
    puts "\t ... ... CDS API key missing; cannot download CDS data"
    next
  end
  if File.exists?(File.expand_path("~/.cdsapirc")) then
    puts "\t ... ... ~/.cdsapirc exists; assuming correctly formatted"
    next
  end
  config = YAML.load_file("config.yml")
  if config["cds"]["key"] then
    cds_key = config["cds"]["key"]
    File.open(File.expand_path("~/.cdsapirc"), "w") do |file|
      file << "url: https://cds.climate.copernicus.eu/api/v2\n"
      file << "key: #{cds_key}\n"
    end
    puts "\t ... ... CDS key found; ~/.cdsapirc created; this will be not displayed again"
    puts "\t ... ... ... Remember to register and accept the terms of this download!"
    next
  end
  puts "\t ... ... ~/.cdsapirc does not exist; no CDS API key given; CDS download not possible"
end

################################
# Download raw data ############
################################
desc "Download all raw data"
task :dwn_data => [:before_dwn_data, :raw_jhu, "raw-data/ecdc-cases.csv", "raw-data/uk-phe-deaths.csv", "raw-data/uk-phe-cases.csv", "raw-data/imperial-europe-pred.csv", "raw-data/imperial-usa-pred.csv", "raw-data/imperial-lmic-pred.csv", :raw_ihme, :raw_nxtstr, "raw-data/who-interventions.xlsx", "raw-data/imperial-interventions.csv", "raw-data/oxford-interventions.csv", :raw_imptfmods, "rambaut-nomenclature", "raw-data/denvfoimap-raster.RDS", :raw_gadm, :raw_cds_ar5, "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif", "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif"]
task :before_dwn_data do
  puts "\t ... Downloading raw data (can take a long time)"
end

gadm_shapefiles = shp_fls("raw-data/gadm36_0") + shp_fls("raw-data/gadm36_1") +shp_fls("raw-data/gadm36_2") +shp_fls("raw-data/gadm36_3") + shp_fls("raw-data/gadm36_4") + shp_fls("raw-data/gadm36_5")
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

desc "Download UK PHE deaths"
file "raw-data/uk-phe-deaths.csv" do
  Dir.chdir "raw-data" do
    `wget https://coronavirus.data.gov.uk/downloads/csv/coronavirus-deaths_latest.csv`
    FileUtils.mv "coronavirus-deaths_latest.csv", "uk-phe-deaths.csv"
  end
  date_metadata "uk-phe-deaths.csv"
end

desc "Download UK PHE cases"
file "raw-data/uk-phe-cases.csv" do
  Dir.chdir "raw-data" do
    `wget https://coronavirus.data.gov.uk/downloads/csv/coronavirus-cases_latest.csv`
    FileUtils.mv "coronavirus-cases_latest.csv", "uk-phe-cases.csv"
  end
  date_metadata "uk-phe-cases.csv"
end

desc "Download Imperial COVID-19 Europe predictions"
file "raw-data/imperial-europe-pred.csv" do dwn_file("raw-data", "https://mrc-ide.github.io/covid19estimates/data/results.csv", "imperial-europe-pred.csv") end

desc "Download Imperial COVID-19 USA predictions"
file "raw-data/imperial-usa-pred.csv" do dwn_file("raw-data", "https://mrc-ide.github.io/covid19usa/downloads/data-model-estimates.csv", "imperial-usa-pred.csv") end

desc "Download Imperial COVID-19 LMIC predictions"
file "raw-data/imperial-lmic-pred.csv" do
  Dir.chdir "raw-data" do
    unzip(stream_file("https://github.com/mrc-ide/global-lmic-reports-staging/raw/master/data/2020-06-09_v2.csv.zip", "lmic.zip"))
    FileUtils.mv "2020-06-09_v2.csv", "imperial-lmic-pred.csv"
    FileUtils.rm "lmic.zip"
  end
  date_metadata "imperial-LMIC-pred.csv"
end

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

desc "Download Oxford intervention data"
file "raw-data/oxford-interventions.csv" do
  Dir.chdir("raw-data") do
    stream_file("https://github.com/OxCGRT/covid-policy-tracker/raw/master/data/OxCGRT_latest.csv", "oxford-interventions.csv")
  end
end

desc "Download Imperial Task Force releases"
imptf_folders = ["imptf-models/covid19model-1.0", "imptf-models/covid19model-2.0", "imptf-models/covid19model-3.0", "imptf-models/covid19model-4.0", "imptf-models/covid19model-5.0", "imptf-models/covid19model-6.0", "imptf-models/squire-master"]
task :raw_imptfmods => imptf_folders
directory "imptf-models/covid19model-1.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v1.0.zip", "tf1.zip"))
    FileUtils.rm "tf1.zip"
  end
  date_metadata("covid19model-1.0")
end
directory "imptf-models/covid19model-2.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v2.0.zip", "tf2.zip"))
    FileUtils.rm "tf2.zip"
  end
  date_metadata("covid19model-2.0")
end
directory "imptf-models/covid19model-3.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v3.0.zip", "tf3.zip"))
    FileUtils.rm "tf3.zip"
  end
  date_metadata("covid19model-3.0")
end
directory "imptf-models/covid19model-4.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v4.0.zip", "tf4.zip"))
    FileUtils.rm "tf4.zip"
  end
  date_metadata("covid19model-4.0")
end
directory "imptf-models/covid19model-5.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v5.0.zip", "tf5.zip"))
    FileUtils.rm "tf5.zip"
  end
  date_metadata("covid19model-5.0")
end
directory "imptf-models/covid19model-6.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v6.0.zip", "tf6.zip"))
    FileUtils.rm "tf6.zip"
  end
  date_metadata("covid19model-6.0")
end
directory "imptf-models/squire-master" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/mrc-ide/squire/archive/master.zip", "squire.zip"))
    FileUtils.rm "squire.zip"
  end
  date_metadata("squire-master")
end


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

desc "Download CDS AR5 climate data"
cds_ar5_files = ["raw-data/cdsar5-1month_mean_Global_ea_2t_201901_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201902_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201903_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201904_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201905_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201906_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201907_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201908_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201909_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201910_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201911_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_201912_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_202001_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_202002_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_202003_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_202004_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_2t_202005_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201901_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201902_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201903_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201904_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201905_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201906_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201907_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201908_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201909_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201910_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201911_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_201912_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_202001_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_202002_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_202003_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_202004_v02.grib","raw-data/cdsar5-1month_mean_Global_ea_r2_202005_v02.grib"]
task :raw_cds_ar5 => cds_ar5_files
def raw_cds_ar5(files)
  unless File.exists? File.expand_path("~/.cdsapirc") then return false end
  Dir.chdir("raw-data") do
    `python3 ../src/cds-ar5.py`
    unzip("cds-ar5.zip")
    Dir["1month_mean_Global_ea*"].each do |filename|
      FileUtils.mv filename, "cdsar5-#{filename}"
    end
    FileUtils.rm "cds-ar5.zip"
  end
  files.map {|x| date_metadata(x)}
  # ... t is temperature, r is relative humidity
end
cds_ar5_files.each {|x| file x do raw_cds_ar5(cds_ar5_files) end}

desc "Get NASA GPW 2pt5 population density data"
file "ext-data/gpw_v4_population_density_rev11_2020_2pt5_min.tif" do
  puts "To get a missing external data dependency:"
  puts "(1) Go to https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11"
  puts "(2) Register and agree to terms"
  puts "(3) Go to https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_2pt5_min_tif.zip"
  puts "(4) Extract the .tif file and put it in 'ext-data'"
end
desc "Get NASA GPW 15min population density data"
file "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif" do
  puts "To get a missing external data dependency:"
  puts "(1) Go to https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11"
  puts "(2) Register and agree to terms"
  puts "(3) Go to https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_15_min_tif.zip"
  puts "(4) Extract the .tif file and put it in 'ext-data'"
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
task :cln_data => [:before_cln_data, :cln_gadm, :cln_denvfoi_rasters, :cln_worldclim, :cln_cdsar5_monthly, :cln_gpw_popdens]
task :before_cln_data do
  puts "\t ... Processing raw data"
end

desc "Clean and process GADM data"
task :cln_gadm => shp_fls("clean-data/gadm-countries",true) + shp_fls("clean-data/gadm-states",true)
def gadm_cleaning()
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-countries.shp raw-data/gadm36_0.shp`
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-states.shp raw-data/gadm36_1.shp`
  (shp_fls("clean-data/gadm-countries")+shp_fls("clean-data/gadm-states")).each {|x| date_metadata(x)}
end
(shp_fls("clean-data/gadm-countries",true)+shp_fls("clean-data/gadm-states",true)).each do |sub_file|
  file sub_file do gadm_cleaning() end
end

desc "Clean and process WORLDCLIM data"
task :cln_worldclim => ["clean-data/worldclim-countries.RDS","clean-data/worldclim-states.RDS"]
def cln_worldclim()
  `Rscript src/worldclim.R`
  date_metadata "clean-data/worldclim-countries.RDS"
  date_metadata "clean-data/worldclim-states.RDS"
end
file "clean-data/worldclim-countries.RDS" => shp_fls("clean-data/gadm-countries",true) do cln_worldclim() end
file "clean-data/worldclim-states.RDS" => shp_fls("clean-data/gadm-states",true) do cln_worldclim() end

desc "Clean DENVfoiMap raster data"
task :cln_denvfoi_rasters => ["clean-data/denvfoimap-rasters-countries.csv", "clean-data/denvfoimap-rasters-states.csv"]
def denvfoimap_rasters()
  `Rscript "src/denvfoimap-rasters.R"`
  date_metadata "clean-data/denvfoimap-rasters-countries.csv"
  date_metadata "clean-data/denvfoimap-rasters-states.csv"
end
file "clean-data/denvfoimap-rasters-countries.csv" do denvfoimap_rasters() end
file "clean-data/denvfoimap-rasters-states.csv" do denvfoimap_rasters() end


desc "Clean and process CDS-AR5 monthly temperature and humidity data"
task :cln_cdsar5_monthly => ["clean-data/relative-humidity-countries.RDS","clean-data/relative-humidity-states.RDS", "clean-data/absolute-humidity-countries.RDS","clean-data/absolute-humidity-states.RDS", "clean-data/temperature-countries.RDS","clean-data/temperature-states.RDS"]
def cln_cdsar5_monthly()
  `Rscript src/clean_CDS_data.R`
  date_metadata "clean-data/relative-humidity-countries.RDS"
  date_metadata "clean-data/relative-humidity-states.RDS"
  date_metadata "clean-data/absolute-humidity-countries.RDS"
  date_metadata "clean-data/absolute-humidity-states.RDS"
  date_metadata "clean-data/temperature-countries.RDS"
  date_metadata "clean-data/temperature-states.RDS"
end
file "clean-data/relative-humidity-countries.RDS" => shp_fls("clean-data/gadm-countries",true) do cln_cdsar5_monthly() end
file "clean-data/relative-humidity-states.RDS" => shp_fls("clean-data/gadm-states",true) do cln_cdsar5_monthly() end
file "clean-data/absolute-humidity-countries.RDS" => shp_fls("clean-data/gadm-countries",true) do cln_cdsar5_monthly() end
file "clean-data/absolute-humidity-states.RDS" => shp_fls("clean-data/gadm-states",true) do cln_cdsar5_monthly() end
file "clean-data/temperature-countries.RDS" => shp_fls("clean-data/gadm-countries",true) do cln_cdsar5_monthly() end
file "clean-data/temperature-states.RDS" => shp_fls("clean-data/gadm-states",true) do cln_cdsar5_monthly() end


desc "Clean and process NASA GPW population density data"
task :cln_gpw_popdens => ["clean-data/population-density-countries.RDS","clean-data/population-density-states.RDS"]
def cln_gpw_popdens()
  `Rscript src/clean_popdensity_data.R`
  date_metadata "clean-data/population-density-countries.RDS"
  date_metadata "clean-data/population-density-states.RDS"
end
file "clean-data/population-density-countries.RDS" => "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif" do cln_gpw_popdens() end
file "clean-data/population-density-states.RDS" => "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif" do cln_gpw_popdens() end


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
  FileUtils.cp ["bayes-env/stan-europe.R","bayes-env/stan-usa.R","bayes-env/stan-usa-pop.R","bayes-env/stan-brazil.R","bayes-env/stan-italy.R"], "imptf-models/covid19model-6.0/"
  FileUtils.cp ["bayes-env/stan-europe.stan","bayes-env/stan-usa.stan","bayes-env/stan-usa-pop.stan","bayes-env/stan-brazil.stan", "bayes-env/stan-italy.stan"], "imptf-models/covid19model-6.0/stan-models/"
  Dir.chdir "imptf-models/covid19model-6.0/" do
    `Rscript stan-europe.R > ../../bayes-env/STDOUT-europe`
    `Rscript stan-usa-pop.R > ../../bayes-env/STDOUT-usa-pop`
    #`Rscript stan-usa.R > ../../bayes-env/STDOUT-usa`
    `Rscript stan-brazil.R > ../../bayes-env/STDOUT-brazil`
    `Rscript stan-italy.R > ../../bayes-env/STDOUT-italy`
  end
  FileUtils.rm ["bayes-env/stan-europe.R","bayes-env/stan-usa.R","bayes-env/stan-usa-pop.R""bayes-env/stan-brazil.R","bayes-env/stan-italy.R", "bayes-env/stan-europe.stan","bayes-env/stan-usa.stan","bayes-env/stan-usa-pop.stan","bayes-env/stan-brazil.stan","bayes-env/stan-italy.stan"]
  `Rscript bayes-env/downstream.R > bayes-env/raw-results.txt`
end

desc "Estimating phylogenetic signal"
task :fit_phylo_signal do
  puts "Hey, if you're expecting this to be smart... Don't do that"
  `Rscript phylo-env/signal.R`
end
