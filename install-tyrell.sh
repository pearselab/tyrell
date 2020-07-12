#!/bin/bash

# Install Ruby and R
# NOTE: Only for Linux; Mac/Windows Google please
apt install ruby r-base-dev chromium-chromedriver gdal-bin

#libv8-dev libprotobuf-dev protobuf-compiler
# - last three for rmapshaper (and its dependencies)


# Install Ruby gems
# NOTE: Only for Linux/Mac; Windows is perhaps the same?
gem install rake open-uri rubyzip yaml selenium-webdriver

# Install Python libraries
pip install cdsapi
