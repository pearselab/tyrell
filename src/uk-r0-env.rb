# Tasks for UK analysis

desc "Fit Rt epidemiological models"
task :uk_epiedmia_models => ["clean-data/climate-and-deaths-UK-LTLA.csv"] do
  datestamp = Time.now.strftime("%d%m%Y-%H%M") 
  `Rscript uk-env/epidemia_ltla.R #{datestamp} > uk-env/STDOUT-ltla-model-#{datestamp}.txt`
end
