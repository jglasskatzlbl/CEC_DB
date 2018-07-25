#Script to do the spatial analysis
#Download Well and CASWI from DB to put into Sp_analysis

library(dplyr)
library(rgeos)
library(sp)
library(readr)
library(RSQLite)
library(rgdal)
library(raster)

#set wd
setwd("C:/Users/jglasskatz/Desktop")

#initialize the db
con = dbConnect(drv=SQLite(), dbname="DBWorkbook5_16.sqlite")
#Load CASGEM data
casWI <- dbGetQuery( con,'select * from CASGEMWI' )
cassp <- SpatialPoints(casWI[,c(6,5)])
#Standardize to feet
crs(cassp)<- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs "
casDis <- spTransform(cassp, CRSobj =CRS("+proj=lcc +lat_1=38.43333333333333 +lat_2=37.06666666666667 +lat_0=36.5 +lon_0=-120.5 +x_0=2000000.0001016 +y_0=500000.0001016001 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs"))

#Load Well data
well <- dbGetQuery( con,'select * from Well' )
#need to clear out NA's for the data to be processed as a spatial frame
#use weLat because the ones with StateID's have already been matched in SQL
welat <- filter(well, !is.na(Latitude) & is.na(State_Well_Number ))
welat[1,8] <- welat[1,8]
welat[welat$Longitude>0,8] <- welat[welat$Longitude>0,8]*-1
wellsp <- SpatialPoints(welat[,c(8,7)])
#change units to feet
crs(wellsp)<- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs "
wellDis <- spTransform(wellsp, "+proj=lcc +lat_1=38.43333333333333 +lat_2=37.06666666666667 +lat_0=36.5 +lon_0=-120.5 +x_0=2000000.0001016 +y_0=500000.0001016001 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs")


#it would be good to know these distances along with the indices
dis <- gDistance(casDis,wellDis, byid = TRUE)

welat$nearest_casgem <- apply(dis,1,which.min)
welat$casgem_dist<- diag(dis[,welat$nearest_casgem])
#Now let's check out the relative sizes after dropping the large outliers.
welat1 <- filter(welat, casgem_dist<100000)
plot(density(welat1$casgem_dist))
#this is a great sign, which probably means all the points we have left are workable. Now to recombine the data sets...
#This is a rough estimate, but saying that it must be within 3 miles seems reasonable
welat1<- filter(welat, casgem_dist<15840)
#first get merged welat1 and casgemWI
welat1$CASGEMID <- casWI[welat1$nearest_casgem,2] 
wecasj <- left_join(welat1,casWI,by = 'CASGEMID')
wecasj <- wecasj[,-c(12,13)]
wecasj <- wecasj[,c(1:11,13,12,14:16)]
write.csv(wecasj, file = '/Users/jglasskatz/Desktop/Sp_analysis/wecaslat.csv', row.names = FALSE)

#disconnect
dbDisconnect(con)
