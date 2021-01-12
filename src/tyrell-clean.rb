desc "Clean and process GADM data"
task :cln_gadm => shp_fls("clean-data/gadm-countries",true) + shp_fls("clean-data/gadm-states",true)+ shp_fls("clean-data/gadm-counties",true)
def gadm_cleaning()
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-countries.shp raw-data/gis/gadm36_0.shp`
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-states.shp raw-data/gis/gadm36_1.shp`
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-counties.shp raw-data/gis/gadm36_2.shp`
  (shp_fls("clean-data/gadm-countries")+shp_fls("clean-data/gadm-states")+shp_fls("clean-data/gadm-counties")).each {|x| date_metadata(x)}
end
shp_fls("clean-data/gadm-countries",true).each do |sub_file|
  file sub_file => shp_fls("raw-data/gis/gadm36_0")do gadm_cleaning() end
end
shp_fls("clean-data/gadm-states",true).each do |sub_file|
  file sub_file => shp_fls("raw-data/gis/gadm36_1") do gadm_cleaning() end
end
shp_fls("clean-data/gadm-counties",true).each do |sub_file|
  file sub_file => shp_fls("raw-data/gis/gadm36_2") do gadm_cleaning() end
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

desc "Pre-process CDS-EAR5 hourly temperature/humidity/uv/pm2.5 data"
task :cln_cdsear5_hourly => ["raw-data/gis/cds-era5-humid-dailymean.grib", "raw-data/gis/cds-era5-temp-dailymean.grib", "raw-data/gis/cds-era5-uv-dailymean.grib"]
file "raw-data/gis/cds-era5-humid-dailymean.grib" => "raw-data/gis/cds-era5-humid-hourly.grib" do
  `cdo daymean raw-data/gis/cds-era5-humid-hourly.grib raw-data/gis/cds-era5-humid-dailymean.grib`
  date_metadata "raw-data/gis/cds-era5-humid-dailymean.grib"  
end
file "raw-data/gis/cds-era5-temp-dailymean.grib" => "raw-data/gis/cds-era5-temp-hourly.grib" do
  `cdo daymean raw-data/gis/cds-era5-temp-hourly.grib raw-data/gis/cds-era5-temp-dailymean.grib`
  date_metadata "raw-data/gis/cds-era5-temp-dailymean.grib"
end
file "raw-data/gis/cds-era5-uv-dailymean.grib" => "raw-data/gis/cds-era5-uv-hourly.grib" do
  `cdo daymean raw-data/gis/cds-era5-uv-hourly.grib raw-data/gis/cds-era5-uv-dailymean.grib`
  date_metadata "raw-data/gis/cds-era5-uv-dailymean.grib"
end
# not running until I can get the api download to work
#~ file "raw-data/gis/cds-cams-pm2pt5-dailymean.grib" => "raw-data/gis/cds-cams-pm2pt5-hourly.grib" do
  #~ `cdo daymean raw-data/gis/cds-cams-pm2pt5-hourly.grib raw-data/gis/cds-cams-pm2pt5-dailymean.grib`
  #~ date_metadata "raw-data/gis/cds-cams-pm2pt5-dailymean.grib"
#~ end

desc "Clean and process CDS-EAR5 mean daily temperature/humidity/uv data"
task :cln_cdsear5_daily => ["clean-data/temp-dailymean-countries.RDS","clean-data/temp-dailymean-states.RDS","clean-data/humid-dailymean-countries.RDS","clean-data/humid-dailymean-states.RDS","clean-data/uv-dailymean-countries.RDS","clean-data/uv-dailymean-states.RDS"]
def cln_cdsear5_daily()
  `Rscript src/clean_cds-era5.R`
  date_metadata "clean-data/temp-dailymean-countries.RDS"
  date_metadata "clean-data/temp-dailymean-states.RDS"
  date_metadata "clean-data/humid-dailymean-countries.RDS"
  date_metadata "clean-data/humid-dailymean-states.RDS"
  date_metadata "clean-data/uv-dailymean-countries.RDS"
  date_metadata "clean-data/uv-dailymean-states.RDS"
end
file "clean-data/temp-dailymean-countries.RDS" => ["raw-data/gis/cds-era5-temp-dailymean.grib"]+shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/temp-dailymean-states.RDS" => ["raw-data/gis/cds-era5-temp-dailymean.grib"]+shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
file "clean-data/humid-dailymean-countries.RDS" => ["raw-data/gis/cds-era5-humid-dailymean.grib"]+shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/humid-dailymean-states.RDS" => ["raw-data/gis/cds-era5-humid-dailymean.grib"]+shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
file "clean-data/uv-dailymean-countries.RDS" => ["raw-data/gis/cds-era5-uv-dailymean.grib"]+shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/uv-dailymean-states.RDS" => ["raw-data/gis/cds-era5-uv-dailymean.grib"]+shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end


desc "Clean and process CDS-EAR5 mean daily temperature/humidity/uv data across UK regions"
task :cln_cdsear5_uk => ["clean-data/temp-UK-NUTS.RDS","clean-data/humid-UK-NUTS.RDS","clean-data/uv-UK-NUTS.RDS","clean-data/temp-UK-LTLA.RDS","clean-data/humid-UK-LTLA.RDS","clean-data/uv-UK-LTLA.RDS"]
def cln_cdsear5_uk()
  `Rscript src/clean-daily-climate-UK.R`
  date_metadata "clean-data/temp-UK-NUTS.RDS"
  date_metadata "clean-data/temp-UK-LTLA.RDS"
  date_metadata "clean-data/humid-UK-NUTS.RDS"
  date_metadata "clean-data/humid-UK-LTLA.RDS"
  date_metadata "clean-data/uv-UK-NUTS.RDS"
  date_metadata "clean-data/uv-UK-LTLA.RDS"
end
file "clean-data/temp-UK-NUTS.RDS" => ["raw-data/gis/cds-era5-temp-dailymean.grib"]+shp_fls("raw-data/gis/NUTS_Level_1__January_2018__Boundaries",true) do cln_cdsear5_daily() end
file "clean-data/temp-UK-LTLA.RDS" => ["raw-data/gis/cds-era5-temp-dailymean.grib"]+shp_fls("raw-data/gis/Local_Authority_Districts__December_2019__Boundaries_UK_BFC",true) do cln_cdsear5_daily() end
file "clean-data/humid-UK-NUTS.RDS" => ["raw-data/gis/cds-era5-humid-dailymean.grib"]+shp_fls("raw-data/gis/NUTS_Level_1__January_2018__Boundaries",true) do cln_cdsear5_daily() end
file "clean-data/humid-UK-LTLA.RDS" => ["raw-data/gis/cds-era5-humid-dailymean.grib"]+shp_fls("raw-data/gis/Local_Authority_Districts__December_2019__Boundaries_UK_BFC",true) do cln_cdsear5_daily() end
file "clean-data/uv-UK-NUTS.RDS" => ["raw-data/gis/cds-era5-uv-dailymean.grib"]+shp_fls("raw-data/gis/NUTS_Level_1__January_2018__Boundaries",true) do cln_cdsear5_daily() end
file "clean-data/uv-UK-LTLA.RDS" => ["raw-data/gis/cds-era5-uv-dailymean.grib"]+shp_fls("raw-data/gis/Local_Authority_Districts__December_2019__Boundaries_UK_BFC",true) do cln_cdsear5_daily() end


desc "Clean and process CDS daily climate data, using population-weighted means"
task :cln_cdsear5_daily_weighted => ["clean-data/temp-dailymean-countries-popweighted.RDS","clean-data/temp-dailymean-states-popweighted.RDS","clean-data/humid-dailymean-countries-popweighted.RDS","clean-data/humid-dailymean-states-popweighted.RDS","clean-data/uv-dailymean-countries-popweighted.RDS","clean-data/uv-dailymean-states-popweighted.RDS", "clean-data/pm2pt5-dailymean-countries-popweighted.RDS", "clean-data/pm2pt5-dailymean-states-popweighted.RDS"]
def cln_cdsear5_daily_weighted()
  `Rscript src/clean-cds-weighted.R`
  date_metadata "clean-data/temp-dailymean-countries-popweighted.RDS"
  date_metadata "clean-data/temp-dailymean-states-popweighted.RDS"
  date_metadata "clean-data/humid-dailymean-countries-popweighted.RDS"
  date_metadata "clean-data/humid-dailymean-states-popweighted.RDS"
  date_metadata "clean-data/uv-dailymean-countries-popweighted.RDS"
  date_metadata "clean-data/uv-dailymean-states-popweighted.RDS"
  date_metadata "clean-data/pm2pt5-dailymean-countries-popweighted.RDS"
  date_metadata "clean-data/pm2pt5-dailymean-states-popweighted.RDS"
end
file "clean-data/temp-dailymean-countries-popweighted.RDS" => ["raw-data/gis/cds-era5-temp-dailymean.grib"]+shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/temp-dailymean-states-popweighted.RDS" => ["raw-data/gis/cds-era5-temp-dailymean.grib"]+shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
file "clean-data/humid-dailymean-countries-popweighted.RDS" => ["raw-data/gis/cds-era5-humid-dailymean.grib"]+shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/humid-dailymean-states-popweighted.RDS" => ["raw-data/gis/cds-era5-humid-dailymean.grib"]+shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
file "clean-data/uv-dailymean-countries-popweighted.RDS" => ["raw-data/gis/cds-era5-uv-dailymean.grib"]+shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/uv-dailymean-states-popweighted.RDS" => ["raw-data/gis/cds-era5-uv-dailymean.grib"]+shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
file "clean-data/pm2pt5-dailymean-countries-popweighted.RDS" => ["ext-data/ads-cams-pm2pt5-dailymean.grib"]+shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/pm2pt5-dailymean-states-popweighted.RDS" => ["ext-data/ads-cams-pm2pt5-dailymean.grib"]+shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
# ext-data will be raw-data/gis/ when I fix the api script

desc "Clean and process NASA GPW population density data"
task :cln_gpw_popdens => ["clean-data/population-density-countries.RDS","clean-data/population-density-states.RDS"]
def cln_gpw_popdens()
  `Rscript src/clean_popdensity_data.R`
  date_metadata "clean-data/population-density-countries.RDS"
  date_metadata "clean-data/population-density-states.RDS"
end
file "clean-data/population-density-countries.RDS" => "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif" do cln_gpw_popdens() end
file "clean-data/population-density-states.RDS" => "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif" do cln_gpw_popdens() end


desc "Clean and process UK population density data"
task :cln_uk_popdens => ["clean-data/population-density-UK-NUTS.RDS","clean-data/population-density-UK-LTLA.RDS"]
def cln_uk_popdens()
  `Rscript src/clean-popdensity-data-UK.R`
  date_metadata "clean-data/population-density-UK-NUTS.RDS"
  date_metadata "clean-data/population-density-UK-LTLA.RDS"
end
file "clean-data/population-density-UK-NUTS.RDS" => shp_fls("raw-data/gis/NUTS_Level_1__January_2018__Boundaries") do cln_uk_popdens() end
file "clean-data/population-density-UK-LTLA.RDS" => shp_fls("raw-data/gis/Local_Authority_Districts__December_2019__Boundaries_UK_BFC") do cln_uk_popdens() end


desc "Combine cleaned environmental data with USA R0/Rt estimates"
task :join_R_climate => ["clean-data/climate_and_R0_USA.csv","clean-data/climate_and_lockdown_Rt_USA.csv", "clean-data/daily_climate_and_Rt_USA.csv"]
def join_R_climate()
  `Rscript src/combine-R0-and-environment-USA.R`
  date_metadata "clean-data/climate_and_R0_USA.csv"
  date_metadata "clean-data/climate_and_lockdown_Rt_USA.csv"
  date_metadata "clean-data/daily_climate_and_Rt_USA.csv"
end
file "clean-data/climate_and_R0_USA.csv" => ["clean-data/temp-dailymean-states.RDS", "clean-data/humid-dailymean-states.RDS", "clean-data/population-density-states.RDS", "raw-data/cases/imperial-usa-pred-2020-05-25.csv", "raw-data/google-mobility.csv", "raw-data/USstatesCov19distancingpolicy.csv"]+shp_fls("clean-data/gadm-states",true) do join_R_climate() end
file "clean-data/climate_and_lockdown_Rt_USA.csv" do join_R_climate() end
file "clean-data/daily_climate_and_Rt_USA.csv" do join_R_climate() end


desc "Combine cleaned environmental data with UK death data"
task :join_uk_deaths_climate => ["clean-data/climate-and-deaths-UK-NUTS.csv", "clean-data/climate-and-deaths-UK-LTLA.csv"]
def join_uk_deaths_climate()
  `Rscript src/join-climate-deaths-UK.R`
  date_metadata "clean-data/climate-and-deaths-UK-NUTS.csv"
  date_metadata "clean-data/climate-and-deaths-UK-LTLA.csv"
end
file "clean-data/climate-and-deaths-UK-NUTS.csv" => ["raw-data/cases/uk-regional.csv", "raw-data/uk-regional-mobility.csv", "clean-data/population-density-UK-NUTS.RDS", "clean-data/temp-UK-NUTS.RDS"] do join_uk_deaths_climate() end
file "clean-data/climate-and-deaths-UK-LTLA.csv" => ["raw-data/cases/uk-ltla.csv", "raw-data/uk-ltla-mobility.csv", "clean-data/population-density-UK-LTLA.RDS", "clean-data/temp-UK-LTLA.RDS"] do join_uk_deaths_climate() end

