# Tyrell - COVID-19 data/analysis/forecasting toolkit

[Pearse Lab, Imperial College London](http://pearselab.com/)

## Overview

We use _Tyrell_ to build and keep track of a common set of data, models, and forecasts as part of our work on COVID-19. It forms a perfect audit trail of how we compile and then analyse data, and you can track its development and changes through exploring its Git(Hub) archive. 

_If you are interested in reproducing the analysis within one of our manuscripts, please read the_ **quickstart - reproducing an analysis** _section below_. Using this software to rebuild and reanalyse everything from scratch can take a very long time, and following these quickstart procedures will likely give you access to everything you need within a few minutes rather than several hours/days.

## Quickstart - reproducing an analysis

### Smith et al. (2020) DOI: 10.1101/2020.09.12.20193250
To work with the data and outputs in our manuscript:

1. Download this zip-file (https://www.dropbox.com/s/pc41n0k3nps86ff/tyrell-ms1envus-Smith2020etal-20200916.zip?dl=0).
2. Unzip it on your computer.
3. The folder `ms-env` contains everything you need: 
   1. Data are in the folder `clean-data`.
   2. Independent regression scripts are in files starting with `r0-`.
   3. Semi-mechanistic model scripts and posterior distributions are in files starting with `rt-`.
4. (Optional) This file (https://www.dropbox.com/s/8kakwt67zi0s2cg/rt-bayes-27082020-0358.Rdata?dl=0) contains the workspace from the Bayesian run used in the manuscript. It is 4.1Gb in size, but is available for download if you wish.

If you want to re-build everything (data and analyses) from scratch, follow the installation instructions below and then run `rake ms1_env_US`. Note that this will take several days even on a computer with 12 processor cores, and you are responsible for checking your Bayesian model outputs for validity. To run everything from scratch, you will need to carry out installation steps 1-6 and 8-10 below.

## Installation
Strictly, the only requirement of _Tyrell_ is Ruby, and if you only want to download case/mortality data that would be sufficient (step 1). If you want to conduct statistical analyses (e.g., reproduce a manuscript) you will need to install R (step 3), and if you want to process GIS data you will need to install Python (step 2) and (depending on the data you need) setup additional data options (steps 4 onwards).

Generally speaking, _Tyrell_ will try and do something and, if it can't because your machine isn't set up to do it, it will carry on anyway after letting you know. Such warnings are not errors: if you don't want to download phylogenetic data, then don't worry if Tyrell is telling you that you can't, for example! Our advice is to carry out the first three steps, and then see what happens when you try running a command. If _Tyrell_ tells you it can't get a file or run a particular command, come back here and find the installation instructions for that command.

`config.yml` is used by _Tyrell_ to keep track of things like the number of processors it can use on your computer, and API keys for data downloads. Below, we assume that you have copied the file `dummy_config.yml` to create a file called `config.yml` in the same directory. _Tyrell_ will look for this file and use the options you store inside it.

1. **Ruby**.
   1. Ensure you have Ruby (>= 2.5.1) installed (use something like `ruby --version` to check).
   2. Ensure the Ruby gems `rake`, `open-uri`, `rubyzip`, `selenium-webdriver`, and `yaml` are installed (use something like `sudo gem install rake open-uri rubyzip selenium-webdriver yaml`).
2. **Python**. 
   1. Ensure you have Python 3 installed on your computer, and that it runs when you type `python3` into your terminal (use something like `python3 --version` to check).
   2. Install the egg `cdsapi` (use something like `sudo pip install cdsapi`).
3. **R**.
   1. Ensure you have R (>= 3.6.3) installed on your computer, and that it runs when you type `Rscript` into your terminal.
   2. Change the parameter `mc.cores` in the `r` block within `config.yml` to tell _Tyrell_ how many processor cores it can use for R scripts. 
   3. _Tyrell_ will try to install all required R packages for you when you need them, but if you like you can run something like `Rscript src/packages.R` now. We recommend doing so and looking at the output: sometimes installing R packages can be hard and, if you're on a Linux system, you make find looking at the package error messages instructive.
4. **CDS AR5 climate data** - follow these instructions if you want to download these data
   1. Register for an API key at https://cds.climate.copernicus.eu/#!/home
   2. Fill in your `key` information in the `cds` block of `config.yml`.
   3. Select from here (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels?tab=form) 'Reanalysis', 'temperature' and 'relative humidity', '1000hPa', '2020', 'January, February, March, April, May', all days, all times, 'Whole available region', 'GRIB', and then submit/agree to the download requirements.
   4. Select from here (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form) 'Reanalysis', 'Radiation and heat: Downward UV radiation at the surface', '2020', 'January, February, March, April, May', all days, all times, 'Whole available region', 'GRIB', and then submit/agree to the download requirements.
5. **Climate Data Operators** - install this program if you want to download and then process the CDS data (point 4 above). There are two ways to do that:
   1. On Ubuntu use `sudo apt install cdo` (likely something similar for other Linux distributions).
   2. Follow the instructions here https://code.mpimet.mpg.de/projects/cdo/wiki#Installation-and-Supported-Platforms to install on other computers.
6. **RGDAL** - install this if you want to process/clean GIS data. Two options:
   1. On Ubuntu run `sudo apt install gdal-bin` (something similar for other Linux distributions).
   2. On other operating systems, go to https://gdal.org/index.html and follow instructions there.
7. **Downloading NASA data** - follow these instructions if you want to download these data. 
   1. Register for an earthdata account following the instructions here (https://wiki.earthdata.nasa.gov/display/EL/How+To+Register+For+an+EarthData+Login+Profile).
   2. Link GES DISC data to your account following the instructions here https://disc.gsfc.nasa.gov/earthdata-login.
   3. Add your username and password to `config.yml` in the `nasa` block.
8. **LaTeX**. If you wish to re-build manuscripts from scratch, you will need to install LaTeX (https://www.latex-project.org/get/).
9. **External NASA data dependencies**. There are three NASA datasets for which it is impossible to automate their download; their installation instructions are below. You will be given these instructions by Tyrell if you need them, but here they are as well for completeness. They should be put in the folder `ext-data`, which _Tyrell_ will create for you when it is first run (see instructions below).
   1. **NASA GPW 30s population density data**.
     1. Go to https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11
     2. Register and agree to terms
     3. Go to https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_30_sec_tif.zip and download the file (should start automatically)
     4. Extract the `.tif` file and put it in `ext-data`
   2. **NASA GPW 2pt5 population density data**.
      1. Go to https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11
      2. Register and agree to terms
      3. Go to https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_2pt5_min_tif.zip and download the file (should start automatically)
      4. Extract the `.ti`f file and put it in `ext-data`
   3. **NASA GPW 15min population density data**.
      1. Go to https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-density-rev11
      2. Register and agree to terms
      3. Go to https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_15_min_tif.zip and download the file (should start automatically)
      4. Extract the `.tif` file and put it in `ext-data`
10. **External airport data dependency**. Download instructions for an airport arrivals external dataset whose download cannot be automated. You will be given these instructions by Tyrell if you need them, but here they are as well for completeness. They should be put in the folder `ext-data`, which _Tyrell_ will create for you when it is first run (see instructions below).
   1. Go to https://aspm.faa.gov/apm/sys/AnalysisAP.asp and perform the following commands in the tabs listed
   2. Output: analysis: - all flights; ms excel, no sub-totals
   3. Dates: range: 01 Feb --> 01 May
   4. Airports: click 'ASPM 77' to fill all
   5. Grouping: select airport, date
   6. Select filters: use schedule
   7. click 'Run'
   8. download the resulting .xls file and save it into `ext-data` as `APM-Report.xls`


## Usage

Open a terminal window and type `rake`. This will list the most commonly-used _Tyrell_ commands. _Tyrell_ is really just a reasonably large `Rakefile` (https://github.com/ruby/rake), meaning it is a series of nested dependencies. So if, for example, you want to reproduce Smith et al. (2020; DOI: [10.1101/2020.09.12.20193250](https://doi.org/10.1101/2020.09.12.20193250)) by typing `rake ms1_env_US`, it will check what data are needed to run the analysis, what data you have already downloaded and processed, and then grab whatever new data you need. This makes it easy to use as a shared workflow: different people can work on different projects, each with shared data dependencies, and _Tyrell_ will keep track of everything for you.

A good first command is probably `rake dwn_data_cases`. This will download lots of case/mortality data for you, and put it in `raw-data`. As part of its setup process, _Tyrell_ will create new folders within itself to store data for you. It will also create a file called that `timestamp.yml` is updated every time new files are downloaded, time-stamping everything so you know what you're working with. If you come back to _Tyrell_ tomorrow and want to update everything on your computer, consider running `rake update_cases` to download the latest versions of all the case data. If you wanted to update one particular file, you could simply delete it from your computer and then run `rake dwn_data_cases` again - _Tyrell_ will notice that file is missing and will replace it with the latest version.

To remove all processed ('clean') data, run `rake reset`. To delete all downloaded files, run `rake clobber`. Folders and the `timestamp.yml` file are not affected by these commands, but `timestamp.yml` will be updated if you re-process or re-download a file. If you are doing some GIS processing, you may find the command `rake save_space` useful; it deletes some very large GIS files that _Tyrell_ downloads and that are only used once to generate much smaller clean data.

## Contributing / support

You're more than welcome to make a pull request with code suggestions, or to ask questions over email (will.pearse@imperial.ac.uk) or in the issues above. Please remember, however, that we are under no obligation to accept pull requests or to help you with your own analyses. Providing all of our underlying code in a widely-used reproducible framework (Rake) was an extremely time-consuming and taxing process; we likely do not have the time to help you install dependencies.

## Why the name?

The light that burns twice as bright burns half as long, and COVID-19 has burned so very, very brightly.
