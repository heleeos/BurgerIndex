# plot.R
# plotting maps
# note we no not use momstouch

require(tidyverse)
require(rgdal); require(foreign); require(magrittr); require(rgeos); require(geosphere)
require(maps); require(maptools); require(mapproj); require(RColorBrewer) # spatial

load(file = "data/shp_sig.Rdata")

# plotting maps
# g_sig <- ggplot(data = shp_sig) +
#   geom_polygon(aes(x=long, y=lat, group=group, fill=group), colour= NA) +
#   theme(legend.position="none") +
#   coord_map(projection = "lambert",
#     parameters = c(shp_sig@bbox[2,1]-0.005,shp_sig@bbox[2,2] +0.005))
# ggsave(filename = "figs/g_sig.pdf", plot = g_sig, width = 8, height = 7)

## convert data
shp_sig_fort <- fortify(shp_sig) %>% left_join(shp_sig@data, by = "id")

## filled by pops
popden_sig <- ggplot(data = shp_sig_fort) +
  geom_polygon(aes(x = long, y = lat, group = group, fill = pop_density), colour = NA) +
  labs(fill = "pop/km^2") +
  coord_map(projection = "lambert",
            parameters = c(shp_sig@bbox[2,1]-0.005,shp_sig@bbox[2,2] +0.005))
ggsave(filename = "figs/popden_sig.pdf", popden_sig, width = 8, height = 7)

## filled by burgers
burgers <- c("B", "M", "K", "L", "MS")
full_bg <- c("BurgerKing", "McDonalds", "KFC", "Lotteria", "MomsTouch")
nburgers <- length(burgers)
for (i in 1:nburgers) {
  sig_name = paste0(burgers[i], "_sig")
  assign(sig_name, 
         ggplot(data = shp_sig_fort) +
           geom_polygon(aes(x = long, y = lat, group = group, fill = get(burgers[i])/area), colour = NA) +
           # theme(legend.position="none") +
           labs(fill = paste0(full_bg[i], "/km^2")) +
           coord_map(projection = "lambert",
                     parameters = c(shp_sig@bbox[2,1]-0.005,shp_sig@bbox[2,2] +0.005))
  )
  ggsave(filename = paste0("figs/",sig_name,".pdf"), plot = get(sig_name), width = 8, height = 7)
}

## filled by burger_index
bi_sig <- ggplot(data = shp_sig_fort) +
  geom_polygon(aes(x = long, y = lat, group = group, fill = BI), colour = NA) +
  # theme(legend.position="none") +
  labs(fill = "burger_index") +
  coord_map(projection = "lambert",
            parameters = c(shp_sig@bbox[2,1]-0.005,shp_sig@bbox[2,2] +0.005))
ggsave(filename = "figs/bi_sig.pdf", bi_sig, width = 8, height = 7)
