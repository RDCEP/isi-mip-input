
library( stringr)

     model <- unlist( str_split( Sys.getenv(      "model"), " "))
  scenario <- unlist( str_split( Sys.getenv(   "scenario"), " "))
scratchDir <- unlist( str_split( Sys.getenv( "scratchDir"), " "))

## model <-
##   "IPSL-CM5A-LR"
## scenario <-
##   unlist(
##     str_split(
##       "rcp2p6 rcp4p5 rcp6p0 rcp8p5",
##       " "))

periodYears <-
  c(
    "1950 1980",
    "1980 2010",
    "2010 2040",
    "2040 2070",
    "2070 2100")

df <-
  expand.grid(
    model= model,
    scenario= scenario,
    period= 1:5)

wthLogFile <- function( model, scenario, period) {
  sprintf(
    "%s/%s/%s/GENERIC%d.LOG",
    scratchDir, model, scenario, period)
}

wthMakeRule <- function( model, scenario, period) {
  log <- wthLogFile( model, scenario, period)
  paste(
    sprintf(
      "%s: split wth_gen | %s",
      log, dirname( log)),
    "@echo started $@ at $$(date)",
    sprintf(
      "wth_gen/nc_wth_gen %s nc/wth_gen_input/%s/%s/ %s GENERIC%d.WTH 1 1 > $@",
      periodYears[ period], model, scenario, dirname( log), period),
    "@echo completed $@ at $$(date)",    
    sep= "\n\t")
}

cat(
  "wthDirs = ",
  paste(
    scratchDir,
    apply(
      unique( df[, c("model", "scenario")]),
      1,
      paste, collapse= "/"),
    sep= "/"),
  sep= " \\\n")
    
cat(
  "wthLogFiles = ",
  with(
    df,
    mapply(
      wthLogFile,
      model,
      scenario,
      period)),
  sep= " \\\n")

cat(
  "\n",
  with(
    df,
    mapply(
      wthMakeRule,
      model,
      scenario,
      period)),
  sep= "\n\n")

