
library( stringr)

## modelDir <- c( "HadGEM2-ES", "IPSL-CM5A-LR")

model <-
  paste(
    "nc",
    unlist( str_split( Sys.getenv( "model"), " ")),
    sep= "/")

## zipFiles <- unlist( str_split( Sys.getenv( "zipFiles"), " "))

zipFiles <-
  list.files(
    model, pattern= "zip$",
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
    years <- fromYear
    cdoPrefix <-
      sprintf(
        "nc/wth_gen_input/%s/%s/%s/%s_",
        model, scenario, wthVar, wthVar)
    annualTargets <-
      paste(
        cdoPrefix, years, ".nc",
        sep= "", collapse= " ")
    prereq <-
      paste(
        dir, model, scenario, var,
        str_replace( file, "zip$", "nc"),
        sep= "/")
    if( targetsOnly) annualTargets else {
      sprintf(
        "%s: %s\n\tmkdir -p %s\n\tcdo splityear -sellonlatbox,-180,180,-60,67 $< %s",
        annualTargets, prereq, dirname( cdoPrefix), cdoPrefix)
    }
  }

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
