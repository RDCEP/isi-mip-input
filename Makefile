#!/usr/bin/make -k -j4 -l6

# WGETRC stopped working when urls.Makefile was implemented.
# Must be something to do with make's environment.
# By not settting this variable wget now looks for ~/.wgetrc

# export WGETRC := $(CURDIR)/wgetrc 

# export modelDir = HadGEM2-ES IPSL-CM5A-LR
export modelDir = IPSL-CM5A-LR

urls.Makefile: urls.R
	Rscript --vanilla urls.R > $@

-include urls.Makefile

$(zipFiles):
	wget --no-verbose --append-output wget.log -c -nc -nH --cut-dirs=3 -x \
	  http://vre1.dkrz.de:8080/thredds/fileServer/isi_mipEnhanced/$@

wget: $(zipFiles)

# SOURCE = $(foreach dir,$(modelDir),$(subst source,$(dir),"bridled:/scratch/local/nbest/isi-mip-input/source"))

# rsync:
# 	rsync -av --include="*.zip" $(SOURCE) .

test:
	find $(modelDir) -type f -not -name '*.nc' -execdir unzip -t '{}' \;

NC = $(patsubst %.zip,%.nc,$(zipFiles))

$(NC): %.nc: %.zip
	unzip -n -d $(dir $@) $<

unzip: $(NC)

split.Makefile: split.R 
	Rscript --vanilla split.R > $@

-include split.Makefile

split: $(annualNcFiles)
# merge the hitorical files with the scenarios via symlinks
	for dir in $(find wth_gen_input/IPSL-CM5A-LR -mindepth 2 -type d -not -regex ".*/historical/.*"); do cd $dir; var=$(echo $dir |cut -d/ -f4); ln -fs ../../historical/${var}/${var}_* .; cd -; done
# repeat 2099 as 2100
	for var in tmin tmax precip solar; do cd wth_gen_input/IPSL-CM5A-LR/rcp8p5/${var}; ln -vs ${var}_2099.nc ${var}_2100.nc; cd -; done

clean:
	find wth -mindepth 2 -maxdepth 2 -type d -exec rm -rf '{}' \;

wth_gen: # unzip
	$(MAKE) --directory=$@ nc_wth_gen

export LD_LIBRARY_PATH := /autonfs/home/dmcinern/lib:$(LD_LIBRARY_PATH)

wth/IPSL-CM5A-LR/rcp8p5/GENERIC1.LOG: wth_gen
	mkdir -p $(dir $@)
	wth_gen/nc_wth_gen 1950 1980 wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

wth/IPSL-CM5A-LR/rcp8p5/GENERIC2.LOG: wth_gen
	mkdir -p $(dir $@)
	wth_gen/nc_wth_gen 1980 2010 wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

wth/IPSL-CM5A-LR/rcp8p5/GENERIC3.LOG: wth_gen
	mkdir -p $(dir $@)
	wth_gen/nc_wth_gen 2010 2040 wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

wth/IPSL-CM5A-LR/rcp8p5/GENERIC4.LOG: wth_gen
	mkdir -p $(dir $@)
	wth_gen/nc_wth_gen 2040 2070 wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

wth/IPSL-CM5A-LR/rcp8p5/GENERIC5.LOG: wth_gen
	mkdir -p $(dir $@)
	wth_gen/nc_wth_gen 2070 2100 wth_gen_input/IPSL-CM5A-LR/rcp8p5/ $(dir $@) $(notdir $(basename $@)).WTH 1 1 > $@

wth: wth/IPSL-CM5A-LR/rcp8p5/GENERIC1.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC2.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC3.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC4.LOG wth/IPSL-CM5A-LR/rcp8p5/GENERIC5.LOG

wth_grid.txt: # wth_gen
	find wth/HadGEM2-ES -mindepth 2 -type d | cut -d/ -f4 | sort | head > wth_grid.txt

scenarios:
	# download the scenario data from somewhere
	tar xzf rcp8p5_soy.tar.gz -C scenarios

.PHONY: wget rsync test unzip rmzip split wth_gen wth




