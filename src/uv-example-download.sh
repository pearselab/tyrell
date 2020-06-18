#!/bin/bash
#
# To download UV data from the NASA GES DISC data archive (https://disc.gsfc.nasa.gov/) using wget
# First you have to register for an earthdata account: https://wiki.earthdata.nasa.gov/display/EL/How+To+Register+For+an+EarthData+Login+Profile
# Then you have to link GES DISC data to your account: https://disc.gsfc.nasa.gov/earthdata-login
# Then follow instructions here to set up .netrc and .urs_cookies files: https://disc.gsfc.nasa.gov/data-access#mac_linux_wget
# Alternatively there's instructions there for curl instead of wget
#
# Now you're (finally) ready to download data with wget (or curl)
# Instructions here: https://disc.gsfc.nasa.gov/information/howto?title=How%20to%20Download%20Data%20Files%20from%20HTTPS%20Service%20with%20wget
#
# Description of the UV data we want to use is here: https://disc.gsfc.nasa.gov/datasets/OMUVBG_003/summary?keywords=OMUVB
# Direct download links here: https://acdisc.gsfc.nasa.gov/data/Aura_OMI_Level2G/OMUVBG.003/
# 
# Download of one file looks like this: wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --content-disposition <url>
# with url being the link to the data.
# Example for one file here:

wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --content-disposition https://acdisc.gsfc.nasa.gov/data/Aura_OMI_Level2G/OMUVBG.003/2020/OMI-Aura_L2G-OMUVBG_2020m0611_v003-2020m0614t090001.he5 -P ../raw-data/
