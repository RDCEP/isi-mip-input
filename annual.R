library( stringr)

isiMipNcFiles <- list.files( c( "HadGEM2-ES", "IPSL-CM5A-LR"), patt= "nc$", recursive= TRUE, full.names= TRUE)

lastAnnualNc <- str_match( basename( isiMipNcFiles), "^(.*?[-_])([0-9]{4})\\.nc$")

cat( sprintf( "annual/%s%s_%s.nc", lastAnnualNc[ ,2], lastAnnualNc[ ,3], lastAnnualNc[ ,3]), sep= "\n")
