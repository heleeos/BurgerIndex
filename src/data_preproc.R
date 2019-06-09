# data_preproc.R
# preporcess for the spatial datasets.

require(tidyverse)
require(rgdal); require(foreign); require(magrittr); require(rgeos); require(geosphere)
require(maps); require(maptools); require(mapproj); require(RColorBrewer) # spatial

# load burger
B <- readxl::read_xlsx("data/burger/res_burgerking.xlsx", col_names = c("loc", "num"), skip = 1)
M <- readxl::read_xlsx("data/burger/res_mcdonalds.xlsx", col_names = c("loc", "num"), skip = 1)
K <- readxl::read_xlsx("data/burger/res_kfc.xlsx", col_names = c("loc", "num"), skip = 1)
L <- readxl::read_xlsx("data/burger/res_lotteria.xlsx", col_names = c("loc", "num"), skip = 1)
MS <- readxl::read_xlsx("data/burger/res_momstouch.xlsx", col_names = c("loc", "num"), skip = 1)

merge(B, M, by = "loc")

ndata = c("B", "M", "K", "L", "MS")
burger <- B
for (n in ndata[-1]) {
  burger <- merge(burger, get(n), by = "loc", all = TRUE)
}
colnames(burger) <- c("loc", ndata)

# load map data
shp_sig <- rgdal::readOGR(dsn = "data/map/TL_SCCO_SIG.shp", layer = "TL_SCCO_SIG",  encoding = "EUC-KR") # map data
tobecor <- grep("시(\\S.+?)구", shp_sig@data$SIG_KOR_NM)
tobecorw <- shp_sig@data$SIG_KOR_NM[tobecor]
shp_sig@data$SIG_KOR_NM <- as.character(shp_sig@data$SIG_KOR_NM)
shp_sig@data$SIG_KOR_NM[tobecor] <- paste(substr(tobecorw, 1, 3), substr(tobecorw, 4, 12))
shp_sig@data$SIG_KOR_NM <- factor(shp_sig@data$SIG_KOR_NM)
# dbf_sig <- foreign::read.dbf(file = "data/map/TL_SCCO_SIG.dbf", as.is = TRUE)
# shp_sig@data = dbf_sig
proj4string(shp_sig) = CRS("+proj=tmerc +lat_0=38 +lon_0=127.5 +k=0.9996 +x_ 0=1000000 +y_0=2000000 +ellps=GRS80 +units=m +no_defs") 
shp_sig %<>% spTransform(CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_de fs"))

# add sig tag to burger data
citycode <- c(
  "서울특별시" = 11,
  "서울시" = 11,
  "강원도"= 42,
  "경기도" = 41,
  "경상남도" = 48,
  "경상북도" = 47,
  "전라남도" = 46,
  "전라북도" = 45,
  "충청남도" = 44,
  "충청북도" = 43,
  "부산광역시" = 26,
  "인천광역시" = 28,
  "대전광역시" = 30,
  "대구광역시" = 27,
  "광주광역시" = 29,
  "울산광역시" = 31,
  "제주특별자치도" = 50,
  "세종특별자치시" = 36
)


# population
## download from http://kosis.kr/index/index.do
## 201903
pops <- readxl::read_xlsx("data/pop/201903.xlsx")
pops_sig <- pops %>% 
  transmute(pop, citycode = citycode[city], sig = sig) %>%
  mutate(full_sig_tag = paste0(citycode, sig))

burger_sig <- burger %>% 
  mutate(citycode = citycode[word(loc, 1)], sig = word(loc, 2)) %>%
  filter(!is.na(citycode)) %>%
  select(-loc) %>%
  mutate(sig_tag = paste0(citycode, sig))

sejong <- burger_sig[burger_sig$citycode == 36,] %>%
  summarise(B = sum(B, na.rm = T), M = sum(M, na.rm = T), 
            K = sum(K, na.rm = T), L = sum(L, na.rm = T), 
            MS = sum(MS, na.rm = T)) %>%
  as.numeric()

burger_sig <- burger_sig %>%
  filter(citycode != 36)

burger_sig[nrow(burger_sig)+1,1:6] <- c(sejong, 36)
burger_sig[nrow(burger_sig),7:8] <- c("세종특별자치시", "36세종특별자치시")

# remove error codes... and use average value
burger_sig <- burger_sig %>% 
  group_by(sig_tag) %>%
  summarise(B = mean(B, na.rm = T), M = mean(M, na.rm = T), 
            K = mean(K, na.rm = T), L = mean(L, na.rm = T), 
            MS = mean(MS, na.rm = T))

# burger dataset에는 광역시, 특별시의 구만 존재.
nrow(burger_sig) # 237

sig_tag <- data.frame(
  id = shp_sig@data$SIG_CD,
  sig_tag = paste0(citycode = substr(shp_sig@data$SIG_CD %>% as.character, 1, 2),
    sig = word(shp_sig@data$SIG_KOR_NM, 1, sep = " ")),
  full_sig_tag = paste0(citycode = substr(shp_sig@data$SIG_CD %>% as.character, 1, 2),
    sig = shp_sig@data$SIG_KOR_NM)
)

# merge pops to shp_sig
shp_sig@data %<>% left_join(left_join(sig_tag, pops_sig, by = "full_sig_tag") %>%
  select(id, pop), by = c("SIG_CD" = "id")
)

# merge burgers to shp_sig
burger_sig <- left_join(sig_tag, burger_sig, by = "sig_tag") %>%
  select(id, B, M, K, L, MS, sig_tag)
burger_sig[is.na(burger_sig)] <- 0

# merge burgers to shp_sig
shp_sig@data %<>%
  left_join(burger_sig, by = c("SIG_CD" = "id"))

# merge area to shp_sig
area_sig <- areaPolygon(shp_sig) %>%
  divide_by(1e+06)
shp_sig@data %<>% 
  mutate(area = area_sig, pop_density = pop/area)

shp_sig@data %<>%
  mutate(id = 0:(length(shp_sig)-1) %>% as.character)

# 
# breaks = shp_sig@data$L %>% quantile(probs = c(0, .25, 0.5, .75, 1 )) 
# 
# shp_sig@data %<>% 
#   mutate(QTL = cut(L, breaks = breaks, include.lowest = T))

# making neighbor list
require(spdep)
nb_sig <- poly2nb(shp_sig)
nb_sig_mat <- nb2mat(nb_sig, style = "B", zero.policy = TRUE)
write.csv(nb_sig_mat, file = "data/nb_sig_mat.csv")

save(list = c("shp_sig"), file = "data/shp_sig.Rdata")