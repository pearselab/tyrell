################################
# Case/mortality ###############
################################
desc "Download Johns Hopkins data"
task :raw_jhu => ["raw-data/cases/jh-global-confirmed.csv", "raw-data/cases/jh-us-confirmed.csv", "raw-data/cases/jh-us-deaths.csv", "raw-data/cases/jh-global-deaths.csv", "raw-data/cases/jh-global-recovered.csv"]
file "raw-data/cases/jh-global-confirmed.csv" do dwn_file("raw-data/cases", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv", "jh-global-confirmed.csv") end
file "raw-data/cases/jh-us-confirmed.csv" do dwn_file("raw-data/cases", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv", "jh-us-confirmed.csv") end
file "raw-data/cases/jh-us-deaths.csv" do dwn_file("raw-data/cases", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv", "jh-us-deaths.csv") end
file "raw-data/cases/jh-global-deaths.csv" do dwn_file("raw-data/cases", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv", "jh-global-deaths.csv") end
file "raw-data/cases/jh-global-recovered.csv" do dwn_file("raw-data/cases", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv", "jh-global-recovered.csv") end

desc "Download Institute for Health Metrics and Evaluation (IHME) data/predictions"
file "raw-data/cases/ihme-summary.csv" do
  Dir.chdir("raw-data/cases") do
    Dir.mkdir "tmp-ihme"
    Dir.chdir("tmp-ihme") do 
      unzip(stream_file("https://ihmecovid19storage.blob.core.windows.net/latest/ihme-covid19.zip", "ihme.zip"))
      FileUtils.rm "ihme.zip"
      FileUtils.mv Dir["*/Summary_stats_all_locs.csv"][0], "../ihme-summary.csv"
    end
    FileUtils.rm_r "tmp-ihme"
  end
  date_metadata("raw-data/cases/ihme-summary.csv")
end

file "raw-data/cases/jh-global-confirmed.csv" do dwn_file("raw-data/cases", "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv", "jh-global-confirmed.csv") end

desc "Download ECDC cases"
file "raw-data/cases/ecdc-cases.csv" do dwn_file("raw-data/cases", "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv", "ecdc-cases.csv") end

desc "Download EC-JRC region summary"
file "raw-data/cases/ecjrcdc-regions.csv" do dwn_file("raw-data/cases", "https://github.com/ec-jrc/COVID-19/raw/master/data-by-region/jrc-covid-19-all-days-by-regions.csv", "ecjrc-regions.csv") end
desc "Download EC-JRC country summary"
file "raw-data/cases/ecjrcdc-countries.csv" do dwn_file("raw-data/cases", "https://github.com/ec-jrc/COVID-19/raw/master/data-by-country/jrc-covid-19-all-days-by-country.csv", "ecjrc-countries.csv") end

desc "Download COVID-19 Data Hub admin1 case data"
file "raw-data/cases/cvodidh-admin1.csv" do dwn_file("raw-data/cases", "https://storage.covid19datahub.io/data-1.csv", "cvodidh-admin1.csv") end
desc "Download COVID-19 Data Hub admin2 case data"
file "raw-data/cases/cvodidh-admin2.csv" do dwn_file("raw-data/cases", "https://storage.covid19datahub.io/data-2.csv", "cvodidh-admin2.csv") end
desc "Download COVID-19 Data Hub admin3 case data"
file "raw-data/cases/cvodidh-admin3.csv" do dwn_file("raw-data/cases", "https://storage.covid19datahub.io/data-3.csv", "cvodidh-admin3.csv") end

desc "Download Imperial COVID-19 Europe predictions"
file "raw-data/cases/imperial-europe-pred.csv" do dwn_file("raw-data/cases", "https://mrc-ide.github.io/covid19estimates/data/results.csv", "imperial-europe-pred.csv") end

desc "Download Imperial COVID-19 USA predictions"
file "raw-data/cases/imperial-usa-pred.csv" do dwn_file("raw-data/cases", "https://mrc-ide.github.io/covid19usa/downloads/data-model-estimates.csv", "imperial-usa-pred.csv") end

desc "Download Imperial COVID-19 USA predictions specific to Imperial Report 23 release"
file "raw-data/cases/imperial-usa-pred-2020-05-25.csv" do dwn_file("raw-data/cases", "https://mrc-ide.github.io/covid19usa/downloads/archive/2020-05-25/data-model-estimates.csv", "imperial-usa-pred-2020-05-25.csv") end

desc "Download Imperial COVID-19 LMIC predictions"
file "raw-data/cases/imperial-lmic-pred.csv" do
  Dir.chdir "raw-data/cases" do
    unzip(stream_file("https://github.com/mrc-ide/global-lmic-reports/raw/master/data/2020-06-09_v2.csv.zip", "lmic.zip"))
    FileUtils.mv "2020-06-09_v2.csv", "imperial-lmic-pred.csv"
    FileUtils.rm "lmic.zip"
  end
  date_metadata "raw-data/cases/imperial-lmic-pred.csv"
end

desc "Download WHO intervention data"
file "raw-data/cases/who-interventions.xlsx" do
  Dir.chdir("raw-data/cases") do
    unzip(stream_file("https://www.who.int/docs/default-source/documents/phsm/20200514-phsm-who-int.zip", "who.zip"))
    FileUtils.mv "data_export_NCOV_PHM_V_RAW_PHSM.xlsx", "who-interventions.xlsx"
    FileUtils.rm ["Glossary of COVID-related PHSM_15_upload.pdf","4PHSM data flow and dataset descriptions.pdf", "who.zip"]
  end
end

desc "Download Imperial intervention data"
file "raw-data/cases/imperial-interventions.csv" do
  Dir.chdir("raw-data/cases") do
    stream_file("https://github.com/ImperialCollegeLondon/covid19model/raw/master/data/interventions.csv", "imperial-interventions.csv")
  end
end

desc "Download Oxford intervention data"
file "raw-data/cases/oxford-interventions.csv" do
  Dir.chdir("raw-data/cases") do
    stream_file("https://github.com/OxCGRT/covid-policy-tracker/raw/master/data/OxCGRT_latest.csv", "oxford-interventions.csv")
  end
end

################################
# GIS ##########################
################################
gadm_shapefiles = shp_fls("raw-data/gis/gadm36_0") + shp_fls("raw-data/gis/gadm36_1") +shp_fls("raw-data/gis/gadm36_2") +shp_fls("raw-data/gis/gadm36_3") + shp_fls("raw-data/gis/gadm36_4") + shp_fls("raw-data/gis/gadm36_5")
desc "Download GADM global shapefiles"
task :raw_gadm => gadm_shapefiles
def raw_gadm_func(shapefiles)
  Dir.chdir("raw-data/gis") do 
    unzip(stream_file("https://biogeo.ucdavis.edu/data/gadm3.6/gadm36_levels_shp.zip", "gadm.zip"))
    FileUtils.rm "gadm.zip"
    FileUtils.rm "license.txt"
  end
  shapefiles.map {|x| date_metadata(x)}
end
gadm_shapefiles.each do |sub_file|
  file sub_file do raw_gadm_func(gadm_shapefiles) end
end

desc "Download DENVfoiMap raster data"
file "raw-data/gis/denvfoimap-raster.RDS" do
  stream_file("https://mrcdata.dide.ic.ac.uk/resources/DENVfoiMap/all_squares_env_var_0_1667_deg.rds", "raw-data/gis/denvfoimap-raster.RDS")
end

# we dont need to do this anymore, so rake is no longer calling this task
desc "Download CDS AR5 climate data"
cds_ar5_files = ["cdsar5-1month_mean_Global_ea_2t_201901_v02.grib","cdsar5-1month_mean_Global_ea_2t_201902_v02.grib","cdsar5-1month_mean_Global_ea_2t_201903_v02.grib","cdsar5-1month_mean_Global_ea_2t_201904_v02.grib","cdsar5-1month_mean_Global_ea_2t_201905_v02.grib","cdsar5-1month_mean_Global_ea_2t_201906_v02.grib","cdsar5-1month_mean_Global_ea_2t_201907_v02.grib","cdsar5-1month_mean_Global_ea_2t_201908_v02.grib","cdsar5-1month_mean_Global_ea_2t_201909_v02.grib","cdsar5-1month_mean_Global_ea_2t_201910_v02.grib","cdsar5-1month_mean_Global_ea_2t_201911_v02.grib","cdsar5-1month_mean_Global_ea_2t_201912_v02.grib","cdsar5-1month_mean_Global_ea_2t_202001_v02.grib","cdsar5-1month_mean_Global_ea_2t_202002_v02.grib","cdsar5-1month_mean_Global_ea_2t_202003_v02.grib","cdsar5-1month_mean_Global_ea_2t_202004_v02.grib","cdsar5-1month_mean_Global_ea_2t_202005_v02.grib","cdsar5-1month_mean_Global_ea_r2_201901_v02.grib","cdsar5-1month_mean_Global_ea_r2_201902_v02.grib","cdsar5-1month_mean_Global_ea_r2_201903_v02.grib","cdsar5-1month_mean_Global_ea_r2_201904_v02.grib","cdsar5-1month_mean_Global_ea_r2_201905_v02.grib","cdsar5-1month_mean_Global_ea_r2_201906_v02.grib","cdsar5-1month_mean_Global_ea_r2_201907_v02.grib","cdsar5-1month_mean_Global_ea_r2_201908_v02.grib","cdsar5-1month_mean_Global_ea_r2_201909_v02.grib","cdsar5-1month_mean_Global_ea_r2_201910_v02.grib","cdsar5-1month_mean_Global_ea_r2_201911_v02.grib","cdsar5-1month_mean_Global_ea_r2_201912_v02.grib","cdsar5-1month_mean_Global_ea_r2_202001_v02.grib","cdsar5-1month_mean_Global_ea_r2_202002_v02.grib","cdsar5-1month_mean_Global_ea_r2_202003_v02.grib","cdsar5-1month_mean_Global_ea_r2_202004_v02.grib","cdsar5-1month_mean_Global_ea_r2_202005_v02.grib"].map! {|x| "raw-data/gis/#{x}"}
task :raw_cds_ar5 => cds_ar5_files
def raw_cds_ar5(files)
  unless File.exists? File.expand_path("~/.cdsapirc") then return false end
  Dir.chdir("raw-data/gis") do
    `python3 ../../src/cds-ar5.py`
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


desc "Get hourly CDS-ERA5 temperature data"
file "raw-data/gis/cds-era5-temp-hourly.grib" do
  Dir.chdir("raw-data/gis") do `python3 ../../src/cds-era5-temp.py` end
  date_metadata "raw-data/gis/cds-era5-temp-hourly.grib"
end
desc "Get hourly CDS-ERA5 humidity data"
file "raw-data/gis/cds-era5-humid-hourly.grib" do
  Dir.chdir("raw-data/gis") do `python3 ../../src/cds-era5-humid.py` end
  date_metadata "raw-data/gis/cds-era5-humid-hourly.grib"
end
desc "Get hourly CDS-ERA5 UV data"
file "raw-data/gis/cds-era5-uv-hourly.grib" do
  Dir.chdir("raw-data/gis") do `python3 ../../src/cds-era5-uv.py` end
  date_metadata "raw-data/gis/cds-era5-uv-hourly.grib"
end

desc "Get NASA GPW 30s population density data - large file, 300mb"
file "ext-data/gpw_v4_population_density_rev11_2020_2pt5_min.tif" do
  puts "To get a missing external data dependency:"
  puts "(1) Go to https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11"
  puts "(2) Register and agree to terms"
  puts "(3) Go to https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_30_sec_tif.zip"
  puts "(4) Extract the .tif file and put it in 'ext-data'"
end

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

desc "Get google mobility data"
file "raw-data/google-mobility.csv" do dwn_file("raw-data", "https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv", "google-mobility.csv") end


################################
# Genetic ######################
################################
desc "Download NextStrain data"
nxtstr_files = ["nxtstr-sel-meta.tsv", "nxtstr-meta.tsv", "nxtstr-authors.tsv", "nxtstr-tree-mut.tre", "nxtstr-tree-date.tre"].map! {|x| "raw-data/genetic/#{x}"}
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
  Dir.chdir("raw-data/genetic") do
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


################################
# Imperial Task Force Models ###
################################
desc "Download Imperial Task Force releases"
imptf_folders = ["imptf-models/covid19model-1.0", "imptf-models/covid19model-2.0", "imptf-models/covid19model-3.0", "imptf-models/covid19model-4.0", "imptf-models/covid19model-5.0", "imptf-models/covid19model-6.0", "imptf-models/squire-master"]
task :raw_imptfmods => imptf_folders
directory "imptf-models/covid19model-1.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v1.0.zip", "tf1.zip"))
    FileUtils.rm "tf1.zip"
  end
  date_metadata("imptf-models/covid19model-1.0")
end
directory "imptf-models/covid19model-2.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v2.0.zip", "tf2.zip"))
    FileUtils.rm "tf2.zip"
  end
  date_metadata("imptf-models/covid19model-2.0")
end
directory "imptf-models/covid19model-3.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v3.0.zip", "tf3.zip"))
    FileUtils.rm "tf3.zip"
  end
  date_metadata("imptf-models/covid19model-3.0")
end
directory "imptf-models/covid19model-4.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v4.0.zip", "tf4.zip"))
    FileUtils.rm "tf4.zip"
  end
  date_metadata("imptf-models/covid19model-4.0")
end
directory "imptf-models/covid19model-5.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v5.0.zip", "tf5.zip"))
    FileUtils.rm "tf5.zip"
  end
  date_metadata("imptf-models/covid19model-5.0")
end
directory "imptf-models/covid19model-6.0" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/ImperialCollegeLondon/covid19model/archive/v6.0.zip", "tf6.zip"))
    FileUtils.rm "tf6.zip"
  end
  date_metadata("imptf-models/covid19model-6.0")
end
directory "imptf-models/squire-master" do
  Dir.chdir("imptf-models") do
    unzip(stream_file("https://github.com/mrc-ide/squire/archive/master.zip", "squire.zip"))
    FileUtils.rm "squire.zip"
  end
  date_metadata("imptf-models/squire-master")
end

# Tidy things up by copying the intervention data to raw-data
desc "Copy USA intervention data from imp model 6"
file "raw-data/USstatesCov19distancingpolicy.csv" => ["imptf-models/covid19model-6.0"] do
  FileUtils.cp "imptf-models/covid19model-6.0/usa/data/USstatesCov19distancingpolicy.csv", "raw-data/"
  date_metadata("raw-data/USstatesCov19distancingpolicy.csv")
end


################################
# Miscellaneous ################
################################
desc "Download Rambaut et al. phylo-nomenclature"
directory "raw-data/rambaut-nomenclature" do
  Dir.chdir "raw-data" do
    unzip(stream_file("https://github.com/hCoV-2019/lineages/archive/master.zip", "rambaut-nomenclature.zip"))
    FileUtils.mv "lineages-master", "rambaut-nomenclature"
    FileUtils.rm "rambaut-nomenclature.zip"
  end
  date_metadata("raw-data/rambaut-nomenclature")
end
