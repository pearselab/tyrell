# Tyrell - COVID-19 Seasonal data/modelling/forecasting toolkit

Pearse Lab

## Overview

A tool to allow us to build, and then track, a common set of data, models, and forecasts to model the impact of environment, and so role of seasonality, in the transmission of SARS-CoV-2.

## Installation

Ensure you have Ruby (>= 2.5.1) and R (>= 3.6.3) installed on your computer. Then ensure the Ruby gems `rake`, `open-uri`, `rubyzip`, `selenium-webdriver`, and `yaml` are installed (something like `sudo gem install rake` etc. should do the trick), along with Python 3 (accessible through `python3`) and the egg `cdsapi` (something like `sudo pip install cdsapi` should work). All other dependencies are installed by the script; check error logs if something seems not to be working. A rough guide of what you should be typing is in `install-tyrell.sh`; you could even try running that script (perhaps with `sudo`) to see if that does it.

Downloading the NextStrain data involves setting up ChromeDriver, which `install-tyrell.sh` does, but don't worry if it isn't working yet for you.

Downloading the CDS AR5 climate data requires you to (1) register for an API key at https://cds.climate.copernicus.eu/#!/home, (2) copy `dummy_config.yml` to `config.yml` and then copy-paste your, and finally (3) select from here (https://cds.climate.copernicus.eu/cdsapp#!/dataset/ecv-for-climate-change?tab=form) 'surface air temp' and 'surface air relative humidity', 'monthly mean', '1 month', '2019 and 2020', all months, 'ERA5', 'zip', and then submit/agree to the download requirements. After that, Tom, you need to decide whether (a) we want daily data (probably, and if so then set that up :p) and (b) how we load this into R :D Perhaps rgdal::readGDAL can help?

## Usage

Open a terminal window and type `rake`. Wait a while (several gigabytes of data are downloaded and processed). Note that `timestamp.yml` is updated every time new files are downloaded, time-stamping everything with when it was accessed.

To delete processed files, run `rake clean`. To delete all downloaded files, run `rake clobber`. Folders and the `timestamp.yml` file are not affected by these commands. To update your downloaded data (e.g., with the latest infection counts) run `rake update_data`. Note that these folders will be created by this script, and have been added to the `.gitignore` to remind you not to share data, but rather processing code.

## Contributing

If it 'ain't in the `Rakefile`, it 'ain't being accepted.

## Why the name?

The light that burns twice as bright burns half as long, and COVID-19 has burned so very, very brightly.
