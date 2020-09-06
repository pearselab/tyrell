desc "Clean and process GADM data"
task :cln_gadm => shp_fls("clean-data/gadm-countries",true) + shp_fls("clean-data/gadm-states",true)+ shp_fls("clean-data/gadm-counties",true)
def gadm_cleaning()
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-countries.shp raw-data/gadm36_0.shp`
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-states.shp raw-data/gadm36_1.shp`
  `ogr2ogr -simplify 0.005 -f "ESRI Shapefile" clean-data/gadm-counties.shp raw-data/gadm36_2.shp`
  (shp_fls("clean-data/gadm-countries")+shp_fls("clean-data/gadm-states")+shp_fls("clean-data/gadm-counties")).each {|x| date_metadata(x)}
end
(shp_fls("clean-data/gadm-countries",true)+shp_fls("clean-data/gadm-states",true)+shp_fls("clean-data/gadm-counties",true)).each do |sub_file|
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

desc "Pre-process CDS-EAR5 hourly temperature/humidity/uv data"
task :cln_cdsear5_hourly => ["raw-data/cds-era5-humid-dailymean.grib", "raw-data/cds-era5-temp-dailymean.grib", "raw-data/cds-era5-uv-dailymean.grib"]
def cln_cdsear5_hourly()
  `cdo daymean raw-data/cds-era5-humid-hourly.grib raw-data/cds-era5-humid-dailymean.grib`
  `cdo daymean raw-data/cds-era5-temp-hourly.grib raw-data/cds-era5-temp-dailymean.grib`
  `cdo daymean raw-data/cds-era5-uv-hourly.grib raw-data/cds-era5-uv-dailymean.grib`
  date_metadata "raw-data/cds-era5-humid-dailymean.grib"
  date_metadata "raw-data/cds-era5-temp-dailymean.grib"
  date_metadata "raw-data/cds-era5-uv-dailymean.grib"
end
file "raw-data/cds-era5-humid-dailymean.grib" => "raw-data/cds-era5-humid-hourly.grib" do cln_cdsear5_hourly() end
file "raw-data/cds-era5-temp-dailymean.grib" => "raw-data/cds-era5-temp-hourly.grib" do cln_cdsear5_hourly() end
file "raw-data/cds-era5-uv-dailymean.grib" => "raw-data/cds-era5-uv-hourly.grib" do cln_cdsear5_hourly() end


desc "Delete the hourly climate data in the interests of space saving"
task :delete_cdsear5_hourly do
  FileUtils.chdir("raw-data") do
    FileUtils.rm ["cds-era5-humid-hourly.grib", "cds-era5-temp-hourly.grib", "cds-era5-uv-hourly.grib"]
  end
end  

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
file "clean-data/temp-dailymean-countries.RDS" => shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/temp-dailymean-states.RDS" => shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
file "clean-data/humid-dailymean-countries.RDS" => shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/humid-dailymean-states.RDS" => shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end
file "clean-data/uv-dailymean-countries.RDS" => shp_fls("clean-data/gadm-countries",true) do cln_cdsear5_daily() end
file "clean-data/uv-dailymean-states.RDS" => shp_fls("clean-data/gadm-states",true) do cln_cdsear5_daily() end


desc "Clean and process NASA GPW population density data"
task :cln_gpw_popdens => ["clean-data/population-density-countries.RDS","clean-data/population-density-states.RDS"]
def cln_gpw_popdens()
  `Rscript src/clean_popdensity_data.R`
  date_metadata "clean-data/population-density-countries.RDS"
  date_metadata "clean-data/population-density-states.RDS"
end
file "clean-data/population-density-countries.RDS" => "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif" do cln_gpw_popdens() end
file "clean-data/population-density-states.RDS" => "ext-data/gpw_v4_population_density_rev11_2020_15_min.tif" do cln_gpw_popdens() end

desc "Combine cleaned environmental data with R0/Rt estimates"
task :join_R_climate => ["clean-data/climate_and_R0_USA.csv","clean-data/climate_and_lockdown_Rt_USA.csv", "clean-data/daily_climate_and_Rt_USA.csv"]
def join_R_climate()
  `Rscript src/combine-R0-and-environment-USA.R`
  date_metadata "clean-data/climate_and_R0_USA.csv"
  date_metadata "clean-data/climate_and_lockdown_Rt_USA.csv"
  date_metadata "clean-data/daily_climate_and_Rt_USA.csv"
end
file "clean-data/climate_and_R0_USA.csv" => ["clean-data/temp-midday-states.RDS", "clean-data/humid-midday-states.RDS", "clean-data/population-density-states.RDS", "raw-data/imperial-usa-pred-2020-05-25.csv", "raw-data/google-mobility.csv", "raw-data/USstatesCov19distancingpolicy.csv", "clean-data/gadm-states.RDS"] do join_R_climate() end
file "clean-data/climate_and_lockdown_Rt_USA.csv" do join_R_climate() end
file "clean-data/daily_climate_and_Rt_USA.csv" do join_R_climate() end
