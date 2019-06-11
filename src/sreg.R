# sreg.R

## load libraries
require(tidyverse)
require(rgdal); require(foreign); require(magrittr); require(rgeos); require(geosphere)
require(maps); require(maptools); require(mapproj); require(RColorBrewer) # spatial
require(rstan) # MCMC

## load fitted models
load("rdata/sreg.Rdata")

## pars to view
burger_pars <- c('beta', 'tau', 'gamma')

## traceplot
bmk_trace <- traceplot(bmk_fit, pars = burger_pars, inc_warmup = TRUE)
l_trace <- traceplot(l_fit, pars = burger_pars, inc_warmup = TRUE)
ggsave(filename = "figs/mcmc/bmk_trace.pdf", bmk_trace, width = 13, height = 6)
ggsave(filename = "figs/mcmc/l_trace.pdf", l_trace, width = 13, height = 6)

## density
bmk_dens <- stan_plot(bmk_fit, pars = burger_pars, show_density = TRUE)
l_dens <- stan_plot(l_fit, pars = burger_pars, show_density = TRUE)
ggsave(filename = "figs/mcmc/bmk_dens.pdf", bmk_dens, width = 7, height = 6)
ggsave(filename = "figs/mcmc/l_dens.pdf", l_dens, width = 7, height = 6)

## hist of the mean of log_thetas
bmk_ltheta_hist <- summary(bmk_fit, pars = "log_theta")$summary[,1] %>%
  data.frame(x = .) %>%
  ggplot(aes(x = x)) +
  geom_histogram(bins = 30) +
  labs(x = "log_theta", title = "Histogram of the sample mean of log_theta of BMK") 
l_ltheta_hist <- summary(l_fit, pars = "log_theta")$summary[,1] %>%
  data.frame(x = .) %>%
  ggplot(aes(x = x)) +
  geom_histogram(bins = 30) +
  labs(x = "log_theta", title = "Histogram of the sample mean of log_theta of L") 
ggsave(filename = "figs/mcmc/bmk_ltheta_hist.pdf", bmk_ltheta_hist, width = 7, height = 6)
ggsave(filename = "figs/mcmc/l_ltheta_hist.pdf", l_ltheta_hist, width = 7, height = 6)

## summary
print(bmk_fit, pars = burger_pars)
print(l_fit, pars = burger_pars)

## prediction

### load data
load("rdata/shp_sig.Rdata")
shp_df <- shp_sig@data %>%
  tbl_df()

### predicted vs true
npred = 30
burger_pred <- paste0("y_rep[", 1:npred, "]")
bmk_pred <- stan_plot(bmk_fit, pars = burger_pred) +
  geom_point(data = shp_df[1:npred,], aes(x = B+M+K, y = npred:1, col = "TRUE"), size = 3) +
  scale_color_manual(values = c("TRUE" = "blue")) +
  labs(title = "predicted BMK vs true BMK") 
l_pred <- stan_plot(l_fit, pars = burger_pred) +
  geom_point(data = shp_df[1:npred,], aes(x = L, y = npred:1, col = "TRUE"), size = 3) +
  scale_color_manual(values = c("TRUE" = "blue")) +
  labs(title = "predicted L vs true L") 
ggsave(filename = "figs/mcmc/bmk_pred.pdf", bmk_pred, width = 7, height = 6)
ggsave(filename = "figs/mcmc/l_pred.pdf", l_pred, width = 7, height = 6)

### draw maps
#### full predicted values
bmk_p <- summary(bmk_fit, pars = "y_rep")$summary[,1]
l_p <- summary(l_fit, pars = "y_rep")$summary[,1]
samp_sig <- shp_sig
samp_sig@data %<>%
  mutate(BMK = B+M+K, BMK_p = bmk_p, L_p = l_p, BI_p = (BMK_p+1/2)/(L_p+1/2)) %>%
  select(BMK, BMK_p, L, L_p, BI, BI_p, id, area, SIG_KOR_NM)
#### convert data
samp_sig_fort <- fortify(samp_sig) %>% left_join(samp_sig@data, by = "id")
#### draw map
pburgers <- c("BMK", "L")
npburgers <- length(pburgers)
for (i in 1:npburgers) {
  sig_name = paste0("p", pburgers[i], "_sig")
  assign(sig_name, 
         ggplot(data = samp_sig_fort) +
           geom_polygon(aes(x = long, y = lat, group = group, 
              fill = (get(pburgers[i]) - get(paste0(pburgers[i], "_p")))/area), colour = NA) +
           labs(fill = paste0("err_", pburgers[i], "/km^2")) +
           coord_map(projection = "lambert",
                     parameters = c(samp_sig@bbox[2,1]-0.005,samp_sig@bbox[2,2] +0.005))
  )
  ggsave(filename = paste0("figs/",sig_name,".pdf"), plot = get(sig_name), width = 8, height = 7)
}
#### BI
pbi_sig <- ggplot(data = samp_sig_fort) +
  geom_polygon(aes(x = long, y = lat, group = group, fill = BI_p), colour = NA) +
  # theme(legend.position="none") +
  labs(fill = "predicted burger_index") +
  coord_map(projection = "lambert",
            parameters = c(shp_sig@bbox[2,1]-0.005,shp_sig@bbox[2,2] +0.005))
ggsave(filename = "figs/pbi_sig.pdf", pbi_sig, width = 8, height = 7)
#### relative error
rebi_sig <- ggplot(data = samp_sig_fort) +
  geom_polygon(aes(x = long, y = lat, group = group, fill = abs(BI_p - BI)/BI), colour = NA) +
  # theme(legend.position="none") +
  labs(fill = "relative errors of burger_index") +
  coord_map(projection = "lambert",
            parameters = c(shp_sig@bbox[2,1]-0.005,shp_sig@bbox[2,2] +0.005))
ggsave(filename = "figs/rebi_sig.pdf", rebi_sig, width = 8, height = 7)

#### sort
samp_sig@data %>%
  mutate(re_err = abs(BI_p - BI)/BI) %>%
  arrange(desc(re_err)) %>%
  select(SIG_KOR_NM, BI, BI_p, re_err) %>%
  top_n(10) %>% # weired place 
  xtable::xtable()
