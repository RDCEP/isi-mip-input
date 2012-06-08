#!/bin/env Rscript --vanilla

library( stringr)

http <- "http://vre1.dkrz.de:8080/thredds/fileServer/isi_mipEnhanced"
## model <- c( "HadGEM2-ES", "IPSL-CM5A-LR", "WATCH_Forcing_Data")
model <- "HadGEM2-ES"
scenario <- c( "historical", "rcp8p5")
var <- c( "tasmax_v1", "tasmin_v1", "pr_v2", "rsds_v1")
years <- c( "1950", "1951-1960",
           "1961-1970", "1971-1980", "1981-1990", "1991-2000",
           "2001-2005", "2006-2010",
           "2011-2020", "2021-2030", "2031-2040", "2041-2050", "2051-2060",
           "2061-2070", "2071-2080", "2081-2090", "2091-2099")

df <- expand.grid( model= model, scenario= scenario, var= var, years= years)

ncFiles <-
  with( df, sprintf( "%s/%s/%s/%s_bced_1960_1999_%s_%s_%s.nc",
                    model, scenario, var,
                    str_extract( var, "[^_]+"),
                    tolower( model), scenario, years))

zipUrls <-
  with( df, sprintf( "%s/%s/%s/%s/%s_bced_1960_1999_%s_%s_%s.zip",
                    http, model, scenario, var,
                    str_extract( var, "[^_]+"),
                    tolower( model), scenario, years))

write( zipUrls[ !file.exists( ncFiles)], file= "")
