#!/usr/bin/make -k -j4 -l6

# WGETRC stopped working when urls.Makefile was implemented.
# Must be something to do with make's environment.
# By not settting this variable wget now looks for ~/.wgetrc

# export WGETRC := $(CURDIR)/wgetrc 

DIR = HadGEM2-ES IPSL-CM5A-LR
SOURCE = $(foreach dir,$(DIR),$(subst source,$(dir),"bridled:/scratch/local/nbest/isi-mip-input/source"))
NC  = $(patsubst %.zip,%.nc,$(ZIP))
ANNUAL = $(shell Rscript --vanilla annual.R)

urls.Makefile: urls.R
	Rscript --vanilla urls.R > $@

-include urls.Makefile

wget: $(ZIP)

rsync:
	rsync -av --include="*.zip" $(SOURCE) .

test:
	find $(DIR) -type f -not -name '*.nc' -execdir unzip -t '{}' \;

# rmzip:
# 	find $(DIR) -regex '.*zip\(\?auth\)?$$' -execdir rm '{}' \;

# $(ZIP): %.zip: %.nc
# 	zip -mTo -b /tmp -d $(dir $@) $@ $<

# rezip: $(ZIP)

$(NC): %.nc: %.zip
	unzip -n -d $(dir $@) $<
	cdo splityear -sellonlatbox,-180,180,-60,67 $@ annual/$(firstword $(subst /, ,$@))/$(basename $(notdir $@))_
#	rm $<

unzip: $(NC)

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




