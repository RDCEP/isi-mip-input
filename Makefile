#!/usr/bin/make -k -j4 -l6

# WGETRC stopped working when urls.Makefile was implemented.
# Must be something to do with make's environment.
# By not settting this variable wget now looks for ~/.wgetrc

# export WGETRC := $(CURDIR)/wgetrc 

# export modelDir = HadGEM2-ES IPSL-CM5A-LR
export model = IPSL-CM5A-LR
export scenario = rcp2p6 rcp4p5 rcp6p0 rcp8p5

vpath %.R scripts

zipFiles.make: zipFiles.R
	Rscript --vanilla $< > $@

-include zipFiles.make

$(zipFiles): 
# 	wget --no-verbose --append-output wget.log --no-clobber --no-host-directories --cut-dirs=3 \
#           --force-directories --directory-prefix=nc \
# 	  http://vre1.dkrz.de:8080/thredds/fileServer/isi_mipEnhanced/$@

# wget: $(zipFiles)

test:
	find $(modelDir) -type f -not -name '*.nc' -execdir unzip -t '{}' \;

NC = $(patsubst %.zip,%.nc,$(zipFiles))

$(NC): %.nc: | %.zip
	unzip -n -d $(dir $@) $<

unzip: $(NC)

split.make: split.R 
	Rscript --vanilla $< > $@

-include split.make

# merge the historical files with the scenarios via symlinks
# and repeat 2099 as 2100

futureDirs = $(shell find nc/wth_gen_input/ -mindepth 3 -type d -not -regex ".*/historical/.*")

split: $(annualNcFiles)
	for dir in $(futureDirs); \
        do \
          pushd $$dir; \
          var=$$(echo $$dir |cut -d/ -f5); \
          ln -vs ../../historical/$${var}/$${var}_* .; \
          ln -vs $${var}_2099.nc $${var}_2100.nc; \
          popd; \
        done

#	for var in tmin tmax precip solar; do cd nc/wth_gen_input/IPSL-CM5A-LR/rcp8p5/$${var}; ln -vs $${var}_2099.nc $${var}_2100.nc; cd -; done


clean:
	find wth -mindepth 2 -maxdepth 2 -type d -exec rm -rf '{}' \;

wth_gen:
	$(MAKE) --directory=$@ nc_wth_gen

export LD_LIBRARY_PATH := /autonfs/home/dmcinern/lib:$(LD_LIBRARY_PATH)

wth.make: wth.R 
	Rscript --vanilla $< > $@

-include wth.make

$(wthDirs):
	mkdir -p $@

wth: $(wthLogFiles)

# wth/IPSL-CM5A-LR/rcp8p5/GENERIC1.LOG: split wth_gen
# 	mkdir -p $(dir $@)
# 	wth_gen/nc_wth_gen 1950 1980 nc/wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

# wth/IPSL-CM5A-LR/rcp8p5/GENERIC2.LOG: split wth_gen
# 	mkdir -p $(dir $@)
# 	wth_gen/nc_wth_gen 1980 2010 nc/wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

# wth/IPSL-CM5A-LR/rcp8p5/GENERIC3.LOG: split wth_gen
# 	mkdir -p $(dir $@)
# 	wth_gen/nc_wth_gen 2010 2040 nc/wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

# wth/IPSL-CM5A-LR/rcp8p5/GENERIC4.LOG: split wth_gen
# 	mkdir -p $(dir $@)
# 	wth_gen/nc_wth_gen 2040 2070 nc/wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

# wth/IPSL-CM5A-LR/rcp8p5/GENERIC5.LOG: split wth_gen
# 	mkdir -p $(dir $@)
# 	wth_gen/nc_wth_gen 2070 2100 nc/wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

# wth: wth/IPSL-CM5A-LR/rcp8p5/GENERIC1.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC2.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC3.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC4.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC5.LOG


wth_grid.txt: # wth_gen
	find wth/HadGEM2-ES -mindepth 2 -type d | cut -d/ -f4 | sort | head > wth_grid.txt

scenarios:
# download the scenario data from somewhere
	tar xzf rcp8p5_soy.tar.gz -C scenarios

.PHONY: wget rsync test unzip rmzip split wth_gen wth




