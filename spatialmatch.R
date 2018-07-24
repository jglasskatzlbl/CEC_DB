#Script to do the spatial analysis
#Need to download Well from DB (for now and put into Sp_analysis)

library(dplyr)
library(rgeos)
library(readr)


#Load CASGEM data
casWI <- read.csv('C:/Users/jglasskatz/Desktop/Sp_analysis/casgemWI.csv')
cassp <- SpatialPoints(casWI[,4:5])

#Load Well data
well <- read_csv("C:/Users/jglasskatz/Desktop/Sp_analysis/well.csv")
#need to clear out NA's for the data to be processed as a spatial frame
#use weLat because the ones with StateID's have already been matched in SQL
welat <- filter(well, !is.na(Lat) & StateID =='')
wellsp <- SpatialPoints(welat[,7:8])

#it would be good to know these distances along with the indices
dis <- gDistance(cassp,wellsp, byid = TRUE)
welat$nearest_casgem <- apply(dis,1,which.min)
welat$casgem_dist<- diag(dis[,welat$nearest_casgem])
#Now let's check out the relative sizes after dropping the large outliers.
welat1 <- filter(welat, casgem_dist<1)
plot(density(welat1$casgem_dist))
#this is a great sign, which probably means all the points we have left are workable. Now to recombine the data sets...
#all we really want from casgem is the depth but we need to merge it by time as well...
#that can wait. Start small
#first get merged welat1 and casgemWI
welat1$CASGEMID <- casWI[welat1$nearest_casgem,2] 
wecasj <- left_join(welat1,casWI,by = 'CASGEMID')
wecasj <- wecasj[,-c(12,13)]
wecasj <- wecasj[,c(1:11,13,12,14:16)]
write.csv(wecasj, file = '/Users/jglasskatz/Desktop/Sp_analysis/wecaslat.csv', row.names = FALSE)