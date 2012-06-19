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


# wth_gen_input/HadGEM2-ES/rcp8p5/solar/solar_1950.nc: HadGEM2-ES/historical/pr_v2/pr_bced_1960_1999_hadgem2-es_historical_1950.nc
# 	cdo splityear -sellonlatbox,-180,180,-60,67 $< wth_gen_input/HadGEM2-ES/rcp8p5/solar/solar_

# wth_gen_input/HadGEM2-ES/historical/precip/precip_1951.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1952.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1953.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1954.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1955.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1956.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1957.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1958.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1959.nc wth_gen_input/HadGEM2-ES/historical/precip/precip_1960.nc: HadGEM2-ES/historical/pr_v2/pr_bced_1960_1999_hadgem2-es_historical_1951-1960.nc
# 	cdo splityear -sellonlatbox,-180,180,-60,67 $< wth_gen_input/HadGEM2-ES/historical/precip/precip_

# IPSL-CM5A-LR/rcp8p5/tasmin_v1/tasmin_bced_1960_1999_ipsl-cm5a-lr_rcp8p5_2091-2099.zip

# ANNUAL = $(shell Rscript --vanilla annual.R)

# $(ANNUAL):
# 	cdo splityear ???

# annual: unzip $(ANNUAL)

# because the annual files are not targets Make is not yet
# smart enough to skip the cdo splityear operation, which has
# no flag to avoid overwrites

clean:
	find wth -mindepth 2 -maxdepth 2 -type d -exec rm -rf '{}' \;

wth_gen: # unzip
	# Rscript --vanilla wth_gen_input.R
	$(MAKE) --directory=$@ all

wth_grid.txt: # wth_gen
	find wth/HadGEM2-ES -mindepth 2 -type d | cut -d/ -f4 | sort | head > wth_grid.txt

scenarios:
	# download the scenario data from somewhere
	tar xzf rcp8p5_soy.tar.gz -C scenarios

.PHONY: wget rsync test unzip rmzip wth_gen




