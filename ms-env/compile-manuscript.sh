#!/bin/bash

pdflatex -interaction=batchmode cov-env-ms.tex
bibtex cov-env-ms
pdflatex -interaction=batchmode cov-env-ms.tex
pdflatex -interaction=batchmode cov-env-ms.tex

pdflatex -interaction=batchmode cov-env-supplement.tex
bibtex cov-env-supplement
pdflatex -interaction=batchmode cov-env-supplement.tex
pdflatex -interaction=batchmode cov-env-supplement.tex

rm *.aux *.blg *.bbl *.soc *.toc *.log *.out

#xdg-open cov-env-ms.pdf &

