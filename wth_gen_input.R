library( stringr)

varNameMap <-
  c( pr=   "precip",
     rsds=  "solar",
     tasmax= "tmax",
     tasmin= "tmin")

annualFiles <-
  str_match( list.files( "annual",
                        full.names=TRUE,
                        recursive= TRUE),
            "^annual/([^/]+)/([^_]+)_.*?_([0-9]{4}).nc$")

wthGenNames <-
  sprintf( "wth_gen_input/%s/%s/%s_%s.nc",
          annualFiles[, 2],
          varNameMap[ annualFiles[, 3]],
          varNameMap[ annualFiles[, 3]],
          annualFiles[, 4]) 

for( path in unique( dirname( wthGenNames))) { 
  dir.create( path,
             showWarnings= FALSE,
             recursive= TRUE)
  file.remove( list.files( path, full.names= TRUE))
}

## file.symlink(  paste( "../../..", annualFiles[, 1], sep= "/"), wthGenNames)

createLinks <- function( link, file) {
  oldWd <- setwd( dirname( link))
  linkTarget <- paste( "../../..", file, sep= "/")
  if( Sys.readlink( basename( link)) != "")
    file.remove( basename( link))
  file.symlink( linkTarget, basename( link))
  setwd( oldWd)
  linkTarget
}

setwd("/scratch/local/isi-mip-input/")
mapply( createLinks,
       wthGenNames,
       annualFiles[, 1])
       

  
