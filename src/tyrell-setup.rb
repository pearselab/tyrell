
desc "Install R packages"
task :r_packages do `Rscript "src/packages.R"` end

desc "Setup tyrell folders"
task :folders => ["raw-data", "clean-data", "imptf-models", "ext-data"]
directory 'raw-data'
directory 'raw-data/cases'
directory 'clean-data'
directory 'imptf-models'
directory 'ext-data'

desc "Setup timestamping"
file "timestamp.yml" do File.open("timestamp.yml", "w") end

task :setup_cds_api do
  unless File.exists?("config.yml") then
    puts "\t ... ... No config.yml file; cannot configure CDS data download"
    next
  end
  config = YAML.load_file("config.yml")
  unless config["cds"]["key"] and config["cds"]["key"]!="your-key-here" then
    puts "\t ... ... CDS API key missing; cannot download CDS data"
    next
  end
  if File.exists?(File.expand_path("~/.cdsapirc")) then
    puts "\t ... ... ~/.cdsapirc exists; assuming correctly formatted"
    next
  end
  config = YAML.load_file("config.yml")
  if config["cds"]["key"] then
    cds_key = config["cds"]["key"]
    File.open(File.expand_path("~/.cdsapirc"), "w") do |file|
      file << "url: https://cds.climate.copernicus.eu/api/v2\n"
      file << "key: #{cds_key}\n"
    end
    puts "\t ... ... CDS key found; ~/.cdsapirc created; this will be not displayed again"
    puts "\t ... ... ... Remember to register and accept the terms of this download!"
    next
  end
  puts "\t ... ... ~/.cdsapirc does not exist; no CDS API key given; CDS download not possible"
end

task :setup_nasa_api do
  unless File.exists?("config.yml") then
    puts "\t ... ... No config.yml file; cannot configure NASA data download"
    next
  end
  config = YAML.load_file("config.yml")
  unless config["nasa"]["user"] and config["nasa"]["user"]!="your-username-here" then
    puts "\t ... ... NASA username missing; cannot download NASA data"
    next
  end
  unless config["nasa"]["passwd"] and config["nasa"]["passwd"]!="your-password-here" then
    puts "\t ... ... NASA password missing; cannot download NASA data"
    next
  end
  if File.exists?(File.expand_path("~/.netrc")) then
    puts "\t ... ... ~/.netrc exists; assuming contains NASA credentials"
    next
  end
  config = YAML.load_file("config.yml")
  if config["nasa"]["user"] and config["nasa"]["passwd"] then
    nasa_user = config["nasa"]["user"]
    nasa_passwd = config["nasa"]["passwd"]
    File.open(File.expand_path("~/.netrc"), "w") do |file|
      file << "machine urs.earthdata.nasa.gov login #{nasa_user} password #{nasa_passwd}\n"
    end
    
    puts "\t ... ... NASA credentials found; ~/.netrc created; this will be not displayed again"
  end
  puts "\t ... ... ~/.netrc does not exist; no CDS API key given; CDS download not possible"
  if File.exists?(File.expand_path("~/.urs_cookies")) then
    puts "\t ... ... ~/.urs_cookies exists; assuming valid"
  else
    File.open(File.expand_path("~/.urs_cookies"), "w") do |file|
      file << ""
    end
    puts "\t ... ... blank ~/.urs_cookies created; this will not be displayed again"
  end
end
