require 'fileutils'
require 'yaml'
require 'zip'
require 'open-uri'

def stream_file(url, save_name)
  download = open(url)
  IO.copy_stream(download, save_name)
end

def unzip(file)
  Zip::File.open(file) do |zip_file|
    zip_file.each {|x| x.extract}
  end
end

def date_metadata(entry, opts_yaml="metadata.yml")
  opts = YAML.load_file(opts_yaml)
  unless opts then opts = Hash.new end
  opts[entry] = Time.now.to_s
  File.open(opts_yaml, "w") {|x| x.write(opts.to_yaml)}
end

def dwn_file(folder, url, save_name, opts_yaml="metadata.yml")
  Dir.chdir(folder) do 
    stream_file(url, save_name)
  end
  date_metadata("#{folder}/#{save_name}", opts_yaml)
end

