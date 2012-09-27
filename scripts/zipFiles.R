#!/bin/env Rscript --vanilla

library( stringr)

model    <- unlist( str_split( Sys.getenv( "model"), " "))
scenario <- unlist( str_split( Sys.getenv( "scenario"), " "))

var <-
  if( model %in% c( "IPSL-CM5A-LR", "MIROC-ESM-CHEM", "GFDL-ESM2M", "NorESM1-M")) {
    c( "tasmax_v1", "tasmin_v1", "pr_v2", "rsds_v1")
  } else if( model == "HadGEM2-ES") {
    c( "tasmax_v2", "tasmin_v2", "pr_v3", "rsds_v2")
  }

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
      model= model,
      scenario= "historical",
      var= var,
      years= historicalPeriods),
    expand.grid(
      model= model,
      scenario= scenario,
      var= var,
      years= scenarioPeriods))

df <- with( df, df[ order( model, scenario, var, years), ])

zipFiles <-
  with( df, sprintf( "nc/%s/%s/%s/%s_bced_1960_1999_%s_%s_%s.zip",
                    model, scenario, var,
                    str_extract( var, "[^_]+"),
                    tolower( model), scenario, years))

cat( "export zipFiles =", zipFiles, sep= " \\\n")
