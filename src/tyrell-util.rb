require 'rake'
require 'rake/clean'
require 'fileutils'
require 'yaml'
require 'zip'
require 'open-uri'
require 'selenium-webdriver'

def stream_file(url, save_name)
  download = open(url)
  IO.copy_stream(download, save_name)
  return save_name
end

def unzip(file)
  Zip::File.open(file) do |zip_file|
    zip_file.each {|x| x.extract}
  end
end

def date_metadata(entry, opts_yaml="timestamp.yml")
  opts = YAML.load_file(opts_yaml)
  unless opts then opts = Hash.new end
  opts[entry] = Time.now.to_s
  File.open(opts_yaml, "w") {|x| x.write(opts.to_yaml)}
end

def dwn_file(folder, url, save_name, opts_yaml="timestamp.yml")
  Dir.chdir(folder) do 
    stream_file(url, save_name)
  end
  date_metadata("#{folder}/#{save_name}", opts_yaml)
end

def shp_fls(stem, drop_cpg=false)
  if drop_cpg
    return ["dbf","prj","shp","shx"].map {|x| "#{stem}.#{x}"}
  else
    return ["cpg","dbf","prj","shp","shx"].map {|x| "#{stem}.#{x}"}
  end
end
