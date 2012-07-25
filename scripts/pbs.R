
library( plyr)
library( stringr)
library( chron)

   model <- unlist( str_split( Sys.getenv(    "model"), " "))
scenario <- unlist( str_split( Sys.getenv( "scenario"), " "))
qsubArgs <- unlist( Sys.getenv( "qsubArgs"))

## model <-
##   "IPSL-CM5A-LR"
## scenario <-
##   unlist(
##     str_split(
##       "rcp2p6 rcp4p5 rcp6p0",
##       " "))
## qsubArgs <-
##   "-N nc_wth_gen -l walltime=01:00:00"

maxWallTime <-
  str_match( qsubArgs,
            "walltime=(..:..:..)"
            )[,2]

minOutFileSize <- 115900

df <-
  expand.grid(
    model= model,
    scenario= scenario)

stdOutFiles <-
  list.files(
    path= with( df,
      mapply( paste, "wth", model, scenario, sep= "/")),
    patt= "^nc_wth_gen.out.[1-5].100.[0-9]{1,3}$",
    full.names= TRUE)

parseNcWthGenOut <-
  function( stdOutFile) {
    lines <- readLines( stdOutFile)
    wallTime <- str_match( lines, "^Resources.*?walltime=(..:..:..)")
    data.frame(
      path= stdOutFile,
      size= file.info( stdOutFile)[, "size"],
      wtime= times( wallTime[ !is.na( wallTime[,2]), 2][1]))
  }

wallTimes <- ldply( stdOutFiles, parseNcWthGenOut)

## file.remove( with( wallTimes, as.character( path[ wtime >= maxWallTime])) )

file.remove( with( wallTimes, as.character( path[ size < minOutFileSize])) )
