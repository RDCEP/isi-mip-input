
library( stringr)

modelDir <- unlist( str_split( Sys.getenv( "modelDir"), " "))

## zipFiles <- unlist( str_split( Sys.getenv( "zipFiles"), " "))
zipFiles <-
  list.files(
    modelDir, pattern= "zip$",
    full.names= TRUE,
    recursive= TRUE)


## modelDir <- c( "HadGEM2-ES", "IPSL-CM5A-LR")
## zipFiles <-
##   list.files(
##     modelDir, patt= "zip$",
##     full.names= TRUE,
##     recursive= TRUE)
    
wthVars <-
  c(
    pr= "precip",
    tasmin= "tmin",
    tasmax= "tmax",
    rsds= "solar")

zipFileDf <-
  data.frame(
    str_split_fixed( zipFiles, "/", 4))
colnames( zipFileDf) <- c( "model", "scenario", "var", "file")

## annualTargets <- function( model, scenario, var, file) {
##   plainVar <- str_extract( var, "[^_]+")
##   wthVar <- wthVars[[ plainVar]]
##   fileRegex <-
##     sprintf(
##       "^%s_bced_1960_1999_%s_%s_([0-9]{4})-?([0-9]{0,4}).zip$",
##       plainVar, tolower( model),  scenario)
##   years <- str_match_all( file, fileRegex)
##   fromYear <- years[[ 1]][ 1, 2]
##   toYear <- years[[ 1]][ 1, 3]
##   years <- if( toYear == "") fromYear else fromYear:toYear
##   ## browser()
##   paste(
##     sprintf(
##       "wth_gen_input/%s/%s/%s/%s_%s.nc",
##       model, scenario, wthVar, wthVar, years),
##     collapse= " ")
## }

makeRecipes <- function( model, scenario, var, file, targetsOnly= FALSE) {
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
      "wth_gen_input/%s/%s/%s/%s_",
      model, scenario, wthVar, wthVar)
  annualTargets <-
    paste(
      cdoPrefix, years, ".nc",
      sep= "", collapse= " ")
  prereq <-
    paste(
      model, scenario, var,
      str_replace( file, "zip$", "nc"),
      sep= "/")
  if( targetsOnly) annualTargets else {
    sprintf(
      "%s: %s\n\tmkdir -p %s\n\tcdo splityear -sellonlatbox,-180,180,-60,67 $< %s",
      annualTargets, prereq, dirname( cdoPrefix), cdoPrefix)
  }
}

## with( head( zipFileDf), mapply( makeRecipes, model, scenario, var, file, targetsOnly= FALSE))

## cat(
##   "annualNcFiles = ",
##   paste(
##     with(
##       zipFileDf,
##       mapply(
##         makeRecipes, model, scenario, var, file,
##         targetsOnly= TRUE)),
##     collapse= " "),
##   "\n\n",
##   paste(
##     with(
##       zipFileDf,
##       mapply(
##         makeRecipes, model, scenario, var, file,
##         targetsOnly= FALSE)),
##     collapse= "\n\n"),
##   "\n",
##   sep= "")

cat(
  "annualNcFiles = ",
  with(
    zipFileDf,
    mapply(
      makeRecipes, model, scenario, var, file,
      targetsOnly= TRUE)),
  sep= " \\\n")
cat(
  "\n\n",
  paste(
    with(
      zipFileDf,
      mapply(
        makeRecipes, model, scenario, var, file,
        targetsOnly= FALSE)),
    collapse= "\n\n"),
  "\n",
  sep= "")
