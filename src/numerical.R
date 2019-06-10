# numerical.R
## we do not use 

require(tidyverse)
require(rgdal); require(foreign); require(magrittr); require(rgeos)
require(maps); require(maptools); require(mapproj); require(RColorBrewer) # spatial
require(GGally) # distributions

# load data
load("rdata/shp_sig.Rdata")
sig_df <- shp_sig@data

# dataframe to tbl
sig_df %<>%
  tbl_df()

# distribution
dist_sig <- sig_df %>%
  select(B, M, K, L, BI, pop_density) %>%
  ggpairs()
ggsave(filename = "figs/dist_sig.pdf", dist_sig, width = 8, height = 7)

# numerical
summari_sig <- sig_df %>%
  select(B, M, K, L, BI, pop_density) %>%
  apply(2, function(t) {
    c(mean = mean(t), sd = sd(t), summary(t))
    })

# insert to latex
summari_sig %>%
  xtable::xtable()
