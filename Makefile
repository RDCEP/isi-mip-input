#!/usr/bin/make -k -j4 -l6

export WGETRC := ./.wgetrc 

DIR = HadGEM2-ES IPSL-CM5A-LR
SOURCE = $(foreach dir,$(DIR),$(subst source,$(dir),"bridled:/scratch/local/nbest/isi-mip-input/source"))
ZIP = $(shell find $(DIR) -type f -name '*.zip')
NC  = $(patsubst %.zip,%.nc,$(ZIP))
ANNUAL = $(shell Rscript --vanilla annual.R)

wget: urls.txt
#	rm wget.log
	xargs --verbose -P10 -r -n1 -a urls.txt \
	  wget --no-verbose --append-output wget.log \
	    -c -nc -nH --cut-dirs=3 -x

urls.txt: urls.R
	Rscript --vanilla urls.R > urls.txt

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
	find grid -mindepth 2 -maxdepth 2 -type d -exec rm -rf '{}' \;

wth_gen: # unzip
	Rscript --vanilla wth_gen_input.R
	$(MAKE) --directory=$@ all


.PHONY: wget rsync test unzip rmzip wth_gen




