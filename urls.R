#!/bin/env Rscript --vanilla

library( stringr)

http <- "http://vre1.dkrz.de:8080/thredds/fileServer/isi_mipEnhanced"
## model <- c( "HadGEM2-ES", "IPSL-CM5A-LR", "WATCH_Forcing_Data")
## model <- c( "HadGEM2-ES", "IPSL-CM5A-LR")
modelDir <- unlist( str_split( Sys.getenv( "modelDir"), " "))
scenario <- "rcp8p5"
var <- c( "tasmax_v1", "tasmin_v1", "pr_v2", "rsds_v1")

historicalPeriods <-
  c(
    "1950", "1951-1960",
    "1961-1970", "1971-1980", "1981-1990", "1991-2000",
    "2001-2005")

scenarioPeriods <-
  c(
    "2006-2010",
    "2011-2020", "2021-2030", "2031-2040", "2041-2050", "2051-2060",
    "2061-2070", "2071-2080", "2081-2090", "2091-2099")

df <-
  rbind( 
    expand.grid(
      modelDir= modelDir,
      scenario= "historical",
      var= var,
      years= historicalPeriods),
    expand.grid(
      modelDir= modelDir,
      scenario= scenario,
      var= var,
      years= scenarioPeriods))

df <- with( df, df[ order( modelDir, scenario, var, years), ])

zipFiles <-
  with( df, sprintf( "%s/%s/%s/%s_bced_1960_1999_%s_%s_%s.zip",
                    modelDir, scenario, var,
                    str_extract( var, "[^_]+"),
                    tolower( modelDir), scenario, years))

## zipUrls <- paste( http, zipFiles, sep="/")

## zipUrlsForWget <- zipUrls[ !file.exists( ncFiles)]
## write( zipUrlsForWget, file= "")

cat( "export zipFiles =", zipFiles, sep= " \\\n")

## wget <- "wget --no-verbose --append-output wget.log -c -nc -nH --cut-dirs=3 -x"

## cat(
##   sprintf(
##     "%s:\n\t%s %s\n\n",
##     zipFiles, wget, zipUrls),
##   sep= "")

##write( zipUrls, file= "")

