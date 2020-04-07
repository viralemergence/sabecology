library("ggmap")
library("readxl") 
library("tidyr")
library("plyr")
library("dplyr")
library("Matrix")
library("lattice")
library("mgcv")


dat <- read_excel("data/raw/GB_CoV_VRL_noSeqs.xls", sheet = "GB_CoV_VRL_noSeqs")

loc_distinct <- distinct(dat, gbCountry)
loc_distinct <- loc_distinct[is.na(loc_distinct)==FALSE, ]
loc_distinct <- as.data.frame(loc_distinct)

#geocode with Google maps
register_google(key = Sys.getenv("GEOLOCATION_API_KEY"))
loc_distinct$google <- geocode(as.character(loc_distinct$loc_distinct), output = "more")
google_cord <- cbind(loc_distinct$loc_distinct, as.data.frame(loc_distinct$google))
colnames(google_cord)[1] <- c("gbCountry")

#add Google coordinates to full database
dat <- merge(dat, google_cord, by = "gbCountry", all.x = TRUE)

dir.create(file.path("data", "geolocation"), showWarnings = FALSE)
write.csv(dat, "data/geolocation/coordinate.csv")
