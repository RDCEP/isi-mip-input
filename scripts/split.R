
library( stringr)

Sys.setenv(
  model= "HadGEM2-ES",
  scenario= "rcp2p6 rcp4p5 rcp6p0 rcp8p5",
  qsubArgsCdo= "-N cdo -l walltime=00:30:00")

model <-
  unlist( str_split( Sys.getenv(    "model"), " "))
scenario <-
  unlist( str_split( Sys.getenv( "scenario"), " "))
qsubArgsCdo <-
  unlist( Sys.getenv( "qsubArgsCdo"))

## zipFiles <- unlist( str_split( Sys.getenv( "zipFiles"), " "))

zipFiles <-
  list.files(
    sprintf( "nc/%s", model),
    pattern= "zip$",
    full.names= TRUE,
    recursive= TRUE)

wthVars <-
  c(
    pr= "precip",
    tasmin= "tmin",
    tasmax= "tmax",
    rsds= "solar")

zipFileDf <-
  data.frame(
    str_split_fixed( zipFiles, "/", 5))
colnames( zipFileDf) <- c( "dir", "model", "scenario", "var", "file")

annualFileDf <-
  expand.grid(
    model= model,
    scenario= c( "historical", scenario),
    wthVars= wthVars)

cdoLogFile <-
  function( model, scenario, var, year,
           out= TRUE) {
    sprintf(
      "nc/wth_gen_input/%s/%s/%s/%s_%s.%s",
      model, scenario, var, var, year,
      if( out) "out" else "err")
  }

makeRecipes <-
  function(
    dir, model, scenario, var, file,
    targetsOnly= FALSE) {
    plainVar <- str_extract( var, "[^_]+")
    wthVar <- wthVars[[ plainVar]]
    fileRegex <-
      sprintf(
        "^%s_bced_1960_1999_%s_%s_([0-9]{4})-?([0-9]{0,4}).zip$",
        plainVar, tolower( model),  scenario)
    years <- str_match_all( file, fileRegex)
    fromYear <- years[[ 1]][ 1, 2]
    toYear <- years[[ 1]][ 1, 3]
    ## years <- if( toYear == "") fromYear else fromYear:toYear
    ## years <- fromYear
    cdoPrefix <-
      sprintf(
        "nc/wth_gen_input/%s/%s/%s/%s_",
        model, scenario, wthVar, wthVar)
    annualTargets <-
      paste(
        cdoPrefix, fromYear, ".nc",
        sep= "", collapse= " ")
    prereq <-
      paste(
        dir, model, scenario, var,
        str_replace( file, "zip$", "nc"),
        sep= "/")
    stdOut <- cdoLogFile( model, scenario, wthVar, fromYear)
    stdErr <- cdoLogFile( model, scenario, wthVar, fromYear, out= FALSE)
    if( targetsOnly) annualTargets else {
      sprintf(
        "%s: %s | %s\n\techo cdo splityear -sellonlatbox,-180,180,-60,67 $< %s | qsub %s -d %s -o %s -e %s",
        annualTargets, prereq, dirname( cdoPrefix), cdoPrefix,
        qsubArgsCdo, getwd(), stdOut, stdErr)
    }
  }

cat(
  "annualDirs = ",
  paste(
    "nc/wth_gen_input",
    apply(
      annualFileDf,
      1,
      paste, collapse= "/"),
    sep= "/"),
  sep= " \\\n")

cat(
  "annualNcFiles = ",
  with(
    zipFileDf,
    mapply(
      makeRecipes, dir, model, scenario, var, file,
      targetsOnly= TRUE)),
  sep= " \\\n")

cat(
  "\n\n",
  paste(
    with(
      zipFileDf,
      mapply(
        makeRecipes, dir, model, scenario, var, file,
        targetsOnly= FALSE)),
    collapse= "\n\n"),
  "\n",
  sep= "")

## futureDirs <-
##   apply(
##     expand.grid(
##       "nc/wth_gen_input",
##       model, scenario, wthVars),
##     1, paste, collapse= "/")

histDf <-
  expand.grid(
    dir= "nc/wth_gen_input",
    model= model,
    scenario= scenario,
    wthVar= wthVars,
    year= 1950:2004)

histRecipes <-
  function( dir, model, scenario, wthVar, year,
           targetsOnly= FALSE) {
    ncFile <-
      sprintf( "%s_%s.nc", wthVar, year)
    target <-
      paste( dir, model, scenario, wthVar, ncFile,
            sep= "/")
    if( targetsOnly) return( target)
    prereq <-
      paste( dir, model, "historical", wthVar, ncFile,
            sep= "/")
    linkName <-
      sprintf( "../../historical/%s/%s", wthVar, ncFile)
    sprintf( "%s : %s\n\t$(shell cd %s; ln -vs %s .)",
            target, prereq, dirname( target), linkName)
  }

cat(
  "historicalLinks = ",
  with(
    histDf,
    mapply(
      histRecipes, dir, model, scenario, wthVar, year,
      targetsOnly= TRUE)),
  sep= " \\\n")

cat(
  "\n\n",
  paste(
    with(
      histDf,
      mapply(
        histRecipes, dir, model, scenario, wthVar, year,
        targetsOnly= FALSE)),
    collapse= "\n\n"),
  "\n",
  sep= "")

cat( "\n\n")

cat(
  "finalYearLinks = ",
  with(
    unique( histDf[, 1:4]),
    mapply(
      function( dir, model, scenario, wthVar) {
        sprintf( "%s/%s/%s/%s/%s_2100.nc",
                dir, model, scenario, wthVar, wthVar)
      },
      dir, model, scenario, wthVar)),
  sep= " \\\n")
