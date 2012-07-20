
library( stringr)

     model <- unlist( str_split( Sys.getenv(      "model"), " "))
  scenario <- unlist( str_split( Sys.getenv(   "scenario"), " "))
scratchDir <- unlist( str_split( Sys.getenv( "scratchDir"), " "))
 wthChunks <- unlist( str_split( Sys.getenv(  "wthChunks"), " "))
  qsubArgs <- unlist( Sys.getenv( "qsubArgs"))

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
    period= 1:5,
    chunk= 1:wthChunks)

wthLogFile <-
  function( model, scenario, period, chunk,
           out= TRUE) {
    sprintf(
      "%s/%s/%s/nc_wth_gen.%s.%s.%s.%s",
      scratchDir, model, scenario,
      if( out) "out" else "err",
      period, wthChunks, chunk)
  }

wthMakeRule <-
  function( model, scenario, period, chunk) {
  stdOut <- wthLogFile( model, scenario, period, chunk)
  stdErr <- wthLogFile( model, scenario, period, chunk, out= FALSE)
  paste(
    sprintf(
      "%s: split wth_gen | %s",
      stdOut, dirname( stdOut)),
##    "@echo started $@ at $$(date)",
    sprintf(
      "echo wth_gen/nc_wth_gen %s nc/wth_gen_input/%s/%s %s GENERIC%s.WTH %s %s | qsub %s -d %s -o %s -e %s",
      periodYears[ period], model, scenario,
      dirname( stdOut), period, wthChunks, chunk,
      qsubArgs, getwd(), stdOut, stdErr),
##    "@echo completed $@ at $$(date)",    
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
      period,
      chunk)),
  sep= " \\\n")

cat(
  "\n",
  with(
    df,
    mapply(
      wthMakeRule,
      model,
      scenario,
      period,
      chunk)),
  sep= "\n\n")

