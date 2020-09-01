#!/bin/bash
# calculate daily means from the raw climate data
# climate data operators program must be set up first

cdo daymean raw-data/cds-era5-humid-hourly.grib raw-data/cds-era5-humid-dailymean.grib
cdo daymean raw-data/cds-era5-temp-hourly.grib raw-data/cds-era5-temp-dailymean.grib
cdo daymean raw-data/cds-era5-uv-hourly.grib raw-data/cds-era5-uv-dailymean.grib

# then delete the huge raw files

rm raw-data/cds-era5-humid-hourly.grib raw-data/cds-era5-temp-hourly.grib raw-data/cds-era5-uv-hourly.grib
