
library( plyr)
library( stringr)
library( chron)

## options( error= recover)

## Sys.setenv(
##   model= "HadGEM2-ES",
##   scenario= "rcp2p6 rcp4p5 rcp6p0 rcp8p5",
##   qsubArgs= "-N nc_wth_gen -l walltime=02:00:00")

   model <- unlist( str_split( Sys.getenv(    "model"), " "))
scenario <- unlist( str_split( Sys.getenv( "scenario"), " "))
qsubArgs <- unlist( Sys.getenv( "qsubArgs"))

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
    patt= "^nc_wth_gen\\.[1-5]\\.100\\.[0-9]{1,3}\\.out$",
    full.names= TRUE)

parseNcWthGenOut <-
  function( stdOutFile) {
    ## lines <- readLines( stdOutFile)
    ## wallTime <- str_match( lines, "^Resources.*?walltime=(..:..:..)")
    data.frame(
      path= stdOutFile,
      size= file.info( stdOutFile)[, "size"])
      ##, wtime= times( wallTime[ !is.na( wallTime[,2]), 2][1]))
  }

outFileInfo <- ldply( stdOutFiles, parseNcWthGenOut)

## file.remove( with( wallTimes, as.character( path[ wtime >= maxWallTime])) )

tooShort <-
  with(
    outFileInfo,
    as.character(
      path[ size < minOutFileSize]))

## cat( tooShort)

removed <- file.remove( tooShort)

cat( sprintf( "\n%s of %s abbreviated PBS output files removed.\n",
             length( which( removed)), length( tooShort)))
