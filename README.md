# Tyrell - COVID-19 Seasonal data/modelling/forecasting toolkit

Pearse Lab

## Overview

A tool to allow us to build, and then track, a common set of data, models, and forecasts to model the impact of environment, and so role of seasonality, in the transmission of SARS-CoV-2.

## Installation

Ensure you have Ruby (>= 2.5.1) and R (>= 3.6.3) installed on your computer. Then ensure the Ruby gems `rake`, `open-uri`, `rubyzip`, and `yaml` are installed (something like `sudo gem install rake` etc. should do the trick). All other dependencies are installed by the script; check error logs if something seems not to be working. A rough guide of what you should be typing is in `install-tyrell.sh`.

## Usage

Open a terminal window and type `rake`. Wait a while (several gigabytes of data are downloaded and processed). Note that `metadata.yml` is updated every time new files are downloaded, time-stamping everything with when it was accessed.

To delete processed files, run `rake clean`. To delete all downloaded files, run `rake clobber`. Folders and the `metadata.yml` file are not affected by these commands. Note that these folders will be created by this script, and have been added to the `.gitignore` to remind you not to share data, but rather processing code.

## Contributing

If it 'ain't in the `Rakefile`, it 'ain't being accepted.

## Why the name?

The light that burns twice as bright burns half as long, and COVID-19 has burned so very, very brightly.
