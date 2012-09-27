#!/usr/bin/make -k -j4 -l6

# WGETRC stopped working when urls.Makefile was implemented.
# Must be something to do with make's environment.
# By not settting this variable wget now looks for ~/.wgetrc

# export WGETRC := $(CURDIR)/wgetrc 

# export model = HadGEM2-ES IPSL-CM5A-LR MIROC-ESM-CHEM GFDL-ESM2M NorESM1-M
export model = NorESM1-M
export scenario = rcp2p6 rcp4p5 rcp6p0 rcp8p5
export scratchDir = wth
export wthChunks = 8
export qsubArgs = -N nc_wth_gen -l walltime=4:00:00,mem=500mb
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
	mkdir -p $(dir $@)
	wget --progress=dot:mega --output-file $(patsubst %.zip,%.log,$@) \
--no-clobber --no-host-directories --cut-dirs=3 \
--force-directories --directory-prefix=nc \
http://vre1.dkrz.de:8080/thredds/fileServer/isi_mipEnhanced/$(patsubst nc/%,%,$@)

wget: $(zipFiles)

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
	ln -vfs $(notdir $<) $@

histLinks: $(historicalLinks) 

finalLinks: $(finalYearLinks)

links: $(historicalLinks) $(finalYearLinks)


clean:
	find wth -mindepth 2 -maxdepth 2 -type d -exec rm -rf '{}' \;
	rm wget.log

wth_gen:
	$(MAKE) --directory=$@ nc_wth_gen

export LD_LIBRARY_PATH := /autonfs/home/dmcinern/lib:$(LD_LIBRARY_PATH)

wth.make: wth.R Makefile
	Rscript --vanilla $< > $@

-include wth.make

$(wthDirs):
	mkdir -p $@

pbs: pbs.R
	Rscript --vanilla $<

missingLogFiles = \
  $(filter-out \
    $(foreach m, $(model), \
      $(foreach s, $(scenario), \
        $(wildcard wth/$(m)/$(s)/nc_wth_gen.*.out))), \
    $(wthLogFiles))

wth: links $(missingLogFiles)
#	rsync -a $(scratchDir) .

wth_grid.txt: # wth_gen
	find wth/HadGEM2-ES -mindepth 2 -type d | cut -d/ -f4 | sort | head > wth_grid.txt

scenarios:
# download the scenario data from somewhere
	# cp -v ~jelliott/rcp8p5_*.tar.gz scenarios
	# find scenarios -name "*.tar.gz" -execdir tar xzf \{\} --no-same-permissions --overwrite c\;
	# for crop in soy mai; do echo "tar xzf rcp8p5_${crop}.tar.gz --no-same-permissions --overwrite" | qsub -l walltime=12:00:00 -d $(pwd) -o rcp8p5_${crop}.out -e rcp8p5_${crop}.err; done
	for crop in soy mai; do echo "tar xzvf rcp8p5_${crop}.tar.gz --overwrite" | qsub -l walltime=36:00:00 -d $(pwd) -o rcp8p5_${crop}.out -e rcp8p5_${crop}.err; done
	echo 'find rcp8p5_mai rcp8p5_soy -type f -exec chmod -v u-x,g+rw,o+r \{\} \;' | qsub -l walltime=12:00:00 -d $(pwd)/scenarios

.PHONY: wget test unzip rmzip split links wth_gen wth scenarios histLinks finalLinks links




