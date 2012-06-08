
# WGETRC := ./.wgetrc 


wget: urls.txt
#	rm wget.log
	xargs --verbose -P10 -r -n1 -a urls.txt \
	  wget --no-verbose --append-output wget.log \
	    -c -nc -nH --cut-dirs=3 -x

urls.txt: urls.R
	Rscript --vanilla urls.R > urls.txt

DIR = HadGEM2-ES IPSL-CM5A-LR
ZIP = $(shell find $(DIRS) -type f -name '*.zip')
NC  = $(patsubst %.zip,%.nc,$(ZIP))

$(NC): %.nc: %.zip
	unzip -n -d $(dir $@) $<
	rm $<

unzip: wget $(NC)

$(ZIP): %.zip: %.nc
	zip -mTo -b /tmp -d $(dir $@) $@ $<

rezip: $(ZIP)

# unzip:
# 	find HadGEM2-ES IPSL-CM5A-LR -type f -not -name '*.nc' -execdir unzip -n '{}' \;

test:
	find HadGEM2-ES IPSL-CM5A-LR -type f -not -name '*.nc' -execdir unzip -t '{}' \;

rmzip:
	find HadGEM2-ES IPSL-CM5A-LR -regex '.*zip\(\?auth\)?$$' -execdir rm '{}' \;

.PHONY: wget test unzip rmzip




