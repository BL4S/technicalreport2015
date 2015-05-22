#!/usr/bin/make -f
#
# Makefile for pdflatex projects using bibtex for references
#
# Timothy Brooks 2012 <brooks@cern.ch>
#

SHELL = /bin/bash

latexfile   = report
pdffile     = technicalreport2015

tex_dir     = tex_src
bib_dir     = bib
fig_dir     = figures
img_dir     = img
img_src_dir = img_src
bibstyle    = styles/my-lim-num.bst

TEX         = pdflatex -halt-on-error -file-line-error
BIB         = bibtex -terse
GLS         = makeglossaries
HAVE_RUBBER = "$(shell rubber --version 2> /dev/null)"

tex  = $(wildcard $(tex_dir)/*.tex) $(latexfile).tex
tex += $(wildcard $(fig_dir)/*.tex)
bib  = $(wildcard $(bib_dir)/*.bib)
img  = $(patsubst $(img_src_dir)/%.svg, $(img_dir)/%.png, $(wildcard $(img_src_dir)/*.svg))
img += $(patsubst $(img_src_dir)/%.eps, $(img_dir)/%.pdf, $(wildcard $(img_src_dir)/*.eps))
img += $(patsubst $(img_src_dir)/%.png, $(img_dir)/%.png, $(wildcard $(img_src_dir)/*.png))
img += $(patsubst $(img_src_dir)/%.pdf, $(img_dir)/%.pdf, $(wildcard $(img_src_dir)/*.pdf))

ifneq ($(HAVE_RUBBER), "")
  deps = $(tex) $(bib) $(img)
else
  deps = $(latexfile).aux $(latexfile).bbl $(latexfile).gls
endif

.PHONY: all, rubber, pdflatex, latex

all: $(pdffile).pdf
test: test_figures.pdf

ifneq ($(HAVE_RUBBER),"")
$(pdffile).pdf: rubber
else
$(pdffile).pdf: pdflatex
endif

rubber: $(deps)
	rubber --pdf $(latexfile).tex
	rubber-info --check $(latexfile).tex
	mv $(latexfile).pdf $(pdffile).pdf

pdflatex: $(deps)
	PDFwords="NONE" ;\
	while [ "$${oldPDFwords}" != "$${PDFwords}" ] ; do \
	oldPDFwords=$${PDFwords} ;\
	$(TEX) $(latexfile) ;\
	PDFwords=`tail -n2 have_gls.log | head -n1 | cut -d" " -f2` ;\
	done
	mv $(latexfile).pdf $(pdffile).pdf
	# $(MAKE) tmpclean

latex: $(deps)
	latex $(latexfile)
	dvipdf $(latexfile)

test_figures.pdf: test_figures.tex $(tex) images
ifneq ($(HAVE_RUBBER),"")
	rubber --pdf -f $<
	rubber-info --check $<
else
	$(TEX) $<
endif

$(latexfile).aux: $(img) $(tex)
	$(TEX) $(latexfile)

$(latexfile).bbl: $(bib) | $(latexfile).aux $(bibstyle)
	$(BIB) $(latexfile)

$(latexfile).glo: $(tex) | $(latexfile).bbl
	$(TEX) $(latexfile)

$(latexfile).gls: $(tex) | $(latexfile).glo
	$(GLS) $(latexfile)

$(img_dir)/%.png: $(img_src_dir)/%.svg | $(img_dir)
	inkscape --without-gui --file=$< --export-png=$@ --export-area-drawing

$(img_dir)/%.pdf: $(img_src_dir)/%.eps | $(img_dir)
	epstopdf $< -o $@

$(img_dir)/%.png: $(img_src_dir)/%.png | $(img_dir)
	ln -fs ../$< $@

$(img_dir)/%.pdf: $(img_src_dir)/%.pdf | $(img_dir)
	ln -fs ../$< $@

$(img_dir):
	mkdir -p $(img_dir)

images: $(img)

clean: tmpclean
	rm -f $(latexfile).aux $(latexfile).bbl $(latexfile).glo $(latexfile).gls $(latexfile).brf
	rm -f $(pdffile).pdf

tmpclean: logclean
	rm -f $(latexfile).lof $(latexfile).lot $(latexfile).nav $(latexfile).out $(latexfile).snm $(latexfile).toc $(latexfile).xdy

logclean:
	rm -f $(latexfile).log $(latexfile).blg $(latexfile).glg

imgclean:
	rm -f $(img)
