renv::restore()

library("ggmap")
library("readxl") 

dat <- read_excel("data/raw/GB_CoV_VRL_noSeqs.xls", sheet = "GB_CoV_VRL_noSeqs")

#reformat locality string for GEO-locate
dat$gbCountry_split <- dat$gbCountry
dat$gbCountry_split <- gsub(": ", "_", dat$gbCountry_split)
dat$gbCountry_split <- gsub(":", "_", dat$gbCountry_split)
dat$gbCountry_split <- gsub(", ", "_", dat$gbCountry_split)
dat$gbCountry_split <- gsub(",", "_", dat$gbCountry_split)
dat$gbCountry_split <- gsub("Co.", "", dat$gbCountry_split)
unique(dat$gbCountry_split)

#split locality string into columns
loc_sep <- separate(dat, gbCountry_split, c("loc1", "loc2", "loc3", "loc4"), sep = "_")
names(loc_sep)

loc_sep_distinct <- distinct(loc_sep, gbCountry, .keep_all = TRUE)

#remove locations limited to country
unique(loc_sep_distinct$loc1) #all countries
loc_sep_distinct <- loc_sep_distinct[is.na(loc_sep_distinct$loc2)==FALSE, ]

#lat/long from Google maps
register_google(key = "API")
unique(loc_sep_distinct$gbCountry)

loc_sep_distinct$google <- geocode(as.character(loc_sep_distinct$gbCountry))
google_cord <- cbind(loc_sep_distinct$gbCountry, as.data.frame(loc_sep_distinct$google))
colnames(google_cord) <- c("gbCountry", "google_long", "google_lat")

#add Google coordinates to full database
dat <- merge(dat, google_cord, by = "gbCountry", all.x = TRUE)
names(dat)
dat <- dat[ ,-20]

write.csv(dat, "data/geolocations/coordinate.csv")

missing_loc <- dat[is.na(dat$google_lat)==TRUE, ]
unique(missing_loc$gbCountry)
