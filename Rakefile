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
task :dwn_data => [:before_dwn_data, :raw_jhu, "raw-data/ecdc-cases.csv", "raw-data/imperial-europe-pred.csv", :raw_ihme, :raw_nxtstr, :raw_imptfmods, :raw_gadm]
task :before_dwn_data do
  puts "\t ... Downloading all raw data (can take a long time)"
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
  begin
    options = Selenium::WebDriver::Chrome::Options.new#(args: ['headless'])
  rescue
    puts "\t ... ... Selenium missing; skipping NextStrain; don't try to fix please"
    return false
  end
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
nxtstr_files.each {|x| file x do raw_nxtstr(nxtstr_files) end}

desc "Download Imperial Task Force releases"
imptf_folders = ["imptf-models/covid19model-1.0", "imptf-models/covid19model-2.0", "imptf-models/covid19model-3.0", "imptf-models/covid19model-4.0", "imptf-models/covid19model-5.0"]
task :raw_imptfmods => imptf_folders
def raw_imptfmods(imptf_folders)
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v1.0.zip", "tf1.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v2.0.zip", "tf2.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v3.0.zip", "tf3.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v4.0.zip", "tf4.zip"))
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v5.0.zip", "tf5.zip"))
    FileUtils.rm ["tf1.zip", "tf2.zip", "tf3.zip", "tf4.zip", "tf5.zip"]
  end
  imptf_folders.map {|x| date_metadata(x)}
end
imptf_folders.each {|x| file x do raw_imptfmods(imptf_folders) end}

################################
# Clean data ###################
################################
desc "Process all raw data"
task :cln_data => [:before_cln_data, "clean-data/climate_array.RDS"]
task :before_cln_data do
  puts "\t ... Processing raw data"
end

desc "Clean climate data"
file "clean-data/climate_array.RDS" do
  `Rscript "src/climate-data.R"`
  # Remove extra .rds files (Michael, fix this in the script?)
  FileUtils.rm ["gadm36_AUT_0_sp.rds","gadm36_DEU_0_sp.rds","gadm36_FRA_0_sp.rds","gadm36_NOR_0_sp.rds","gadm36_BEL_0_sp.rds","gadm36_DNK_0_sp.rds","gadm36_GBR_0_sp.rds","gadm36_SWE_0_sp.rds","gadm36_CHE_0_sp.rds","gadm36_ESP_0_sp.rds","gadm36_ITA_0_sp.rds"]
  FileUtils.rm_r "wc10"
  date_metadata "clean-data/climate_array.RDS"
end

