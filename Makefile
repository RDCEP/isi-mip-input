#!/usr/bin/make -k -j4 -l6

# WGETRC stopped working when urls.Makefile was implemented.
# Must be something to do with make's environment.
# By not settting this variable wget now looks for ~/.wgetrc

# export WGETRC := $(CURDIR)/wgetrc 

# export modelDir = HadGEM2-ES IPSL-CM5A-LR
export model = HadGEM2-ES
# export scenario = rcp2p6 rcp4p5 rcp6p0 rcp8p5
export scenario = rcp2p6 rcp4p5 rcp6p0 rcp8p5
export scratchDir = wth
export wthChunks = 100
export qsubArgs = -N nc_wth_gen -l walltime=02:00:00
export qsubArgsCdo = -N cdo -l walltime=00:30:00

vpath %.R scripts

zipFiles.make: zipFiles.R Makefile
	Rscript --vanilla $< > $@

-include zipFiles.make

$(zipFiles): 
#
# Currently we are using globusonline.org manually to transfer the data.
# Eventually we will attempt to automate this through the command-line interface.
#
# 
# 	wget --no-verbose --append-output wget.log --no-clobber --no-host-directories --cut-dirs=3 \
#           --force-directories --directory-prefix=nc \
# 	  http://vre1.dkrz.de:8080/thredds/fileServer/isi_mipEnhanced/$@

# wget: $(zipFiles)

test:
	find $(modelDir) -type f -not -name '*.nc' -execdir unzip -t '{}' \;

NC = $(patsubst %.zip,%.nc,$(zipFiles))

$(NC): %.nc: %.zip
	unzip -n -d $(dir $@) $<

unzip: $(NC)

split.make: split.R Makefile
	Rscript --vanilla $< > $@

-include split.make

$(annualDirs):
	mkdir -p $@

# merge the historical files with the scenarios via symlinks
# and repeat 2099 as 2100

# export futureDirs = $(shell find nc/wth_gen_input/ -mindepth 3 -type d -not -regex ".*/historical/.*")

split: $(annualNcFiles)

$(finalYearLinks): %_2100.nc: %_2099.nc
	ln -vs $< $@

links: split $(historicalLinks) $(finalYearLinks)

clean:
	find wth -mindepth 2 -maxdepth 2 -type d -exec rm -rf '{}' \;

wth_gen:
	$(MAKE) --directory=$@ nc_wth_gen

export LD_LIBRARY_PATH := /autonfs/home/dmcinern/lib:$(LD_LIBRARY_PATH)

wth.make: wth.R Makefile
	Rscript --vanilla $< > $@

-include wth.make

$(wthDirs):
	mkdir -p $@

missingLogFiles = \
  $(filter-out \
    $(foreach m, $(model), \
      $(foreach s, $(scenario), \
        $(wildcard wth/$(m)/$(s)/nc_wth_gen.out.*))), \
    $(wthLogFiles))

wth: $(missingLogFiles)
#	rsync -a $(scratchDir) .

wth_grid.txt: # wth_gen
	find wth/HadGEM2-ES -mindepth 2 -type d | cut -d/ -f4 | sort | head > wth_grid.txt

scenarios:
# download the scenario data from somewhere
	cp -v ~jelliott/rcp8p5_*.tar.gz scenarios
	find scenarios -name "*.tar.gz" -execdir tar xzf \{\} \;

.PHONY: wget test unzip rmzip split links wth_gen wth scenarios




