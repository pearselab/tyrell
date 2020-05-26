#!/bin/bash

# Install Ruby and R
# NOTE: Only for Linux; Mac/Windows Google please
apt install ruby r-base-dev chromium-chromedriver


# Install Ruby gems
# NOTE: Only for Linux/Mac; Windows is perhaps the same?
gem install rake open-uri rubyzip yaml selenium-webdriver
