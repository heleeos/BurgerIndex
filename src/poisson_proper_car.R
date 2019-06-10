# poisson proper_car.R

## load libraries
require(tidyverse)
require(rgdal); require(foreign); require(magrittr); require(rgeos)
require(maps); require(maptools); require(mapproj); require(RColorBrewer) # spatial
require(rstan)

## load data
load("rdata/shp_sig.Rdata")
sig_df <- shp_sig@data
W <- read.csv("rdata/nb_sig_mat.csv") %>%
  as.matrix()

## correct W
rsumW <- rowSums(W)
W[rsumW == 0, rsumW == 0] <- 1

## stan settings
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

## MCMC parameters
niter <- 1e+3
nchains <- 4

## data
scaled_X <- sig_df %>% # covariate
  select(cen_long, cen_lat, pop_density) %>%
  scale() %>%
  cbind(1, .) 
scale_factor <- sig_df %>%
  select(cen_long, cen_lat, pop_density) %>%
  apply(2, function(t) c(mean(t), sd(t)))
Y <- sig_df %>% # BMK
  select(B, M, K) %>%
  apply(1, sum)
Z <- sig_df$L # L
expected <- sig_df$area/10^2 # area/100 (10km^2)

## MCMC inputs
bmk_dat <- list(n = nrow(scaled_X), # number of obs.
                 p = ncol(scaled_X), # dim,
                 X = scaled_X, # design matrix
                 y = Y,
                 log_expected = log(expected), # log(E_i)
                 W = W) # adjacency matrix
l_dat <- list(n = nrow(scaled_X), # number of obs.
                       p = ncol(scaled_X), # dim,
                       X = scaled_X, # design matrix
                       y = Z,
                       log_expected = log(expected), # log(E_i)
                       W = W) # adjacency matrix

## run MCMC; see https://mc-stan.org/users/documentation/case-studies/mbjoseph-CARStan.html
## need 1k secs per chain.... do not run!
bmk_fit <- stan("src/poisson_proper_car.stan", data = bmk_dat, 
                 iter = niter, chains = nchains, verbose = FALSE)

l_fit <- stan("src/poisson_proper_car.stan", data = l_dat, 
              iter = niter, chains = nchains, verbose = FALSE)

## save fitted model
save(list = c("bmk_fit", "l_fit"), file = "rdata/sreg.Rdata")
