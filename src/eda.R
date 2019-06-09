require(tidyverse)
require(rgdal); require(foreign); require(magrittr); require(rgeos)
require(maps); require(maptools); require(mapproj); require(RColorBrewer) # spatial

load("data/shp_sig.Rdata")

sig_df <- shp_sig@data