desc "Fit R0 environmental models"
task :r0_models => ["clean-data/climate_and_R0_USA.csv","clean-data/climate_and_lockdown_Rt_USA.csv"] do
  `Rscript ms-env/r0-models-plots.R > ms-env/STDOUT-r0-regression-models.txt`
end


desc "Fit Rt epidemiological models"
task :rt_models => ["temp-midday-states","population-density-states"].map!{|x| "clean-data/#{x}.RDS"} + [:raw_imptfmods] do
  datestamp = Time.now.strftime("%d%m%Y-%H%M")
  FileUtils.cp ["ms-env/rt-bayes-model.R","ms-env/rt-bayes-model.stan"], "imptf-models/covid19model-6.0/"
  Dir.chdir "imptf-models/covid19model-6.0/" do
    `Rscript rt-bayes-model.R #{datestamp} > ../../ms-env/STDOUT-rt-bayes-model-#{datestamp}.txt`
    #FileUtils.rm ["rt-bayes-model.R", "rt-bayes-model.stan"]
  end
  `Rscript ms-env/rt-bayes-downstream.R > ms-env/rt-bayes-downstream.txt`
end


desc "Fit Rt inverse epidemiological models"
task :rt_inv_models => ["temp-midday-states","population-density-states"].map!{|x| "clean-data/#{x}.RDS"} + [:raw_imptfmods] do
  datestamp = Time.now.strftime("%d%m%Y-%H%M")
  FileUtils.cp ["ms-env/rt-bayes-invmodel.R","ms-env/rt-bayes-invmodel.stan"], "imptf-models/covid19model-6.0/"
  Dir.chdir "imptf-models/covid19model-6.0/" do
    `Rscript rt-bayes-invmodel.R #{datestamp} > ../../ms-env/STDOUT-rt-bayes-invmodel-#{datestamp}.txt`
    #FileUtils.rm ["rt-bayes-invmodel.R", "rt-bayes-invmodel.stan"]
  end
  #`Rscript ms-env/rt-bayes-downstream.R > ms-env/rt-bayes-downstream.txt`
end


desc "Build MS#1 manuscript"
task :ms1_build do
  FileUtils.chdir("ms-env") do
    `pdflatex -interaction=batchmode cov-env-ms.tex
    bibtex cov-env-ms
    pdflatex -interaction=batchmode cov-env-ms.tex
    pdflatex -interaction=batchmode cov-env-ms.tex
    pdflatex -interaction=batchmode cov-env-supplement.tex
    bibtex cov-env-supplement
    pdflatex -interaction=batchmode cov-env-supplement.tex
    pdflatex -interaction=batchmode cov-env-supplement.tex`
    FileUtils.rm Dir["*.aux", "*.blg", "*.bbl", "*.soc", "*.toc", "*.log", "*.out"]
  end
end
