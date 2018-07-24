#Script to do the bulk of data imputation

library(dplyr)
library(randomForest)
library(readr)

#read in the raw data (download first for now) from PumpCAS

pdata3 <- read_csv('/Users/jglasskatz/Desktop/pumpcas.csv')
#Try to interpolate between the missing seasonal depths
#This works when all twelve months are present and on 4 and 9
pdata3$Month <- as.numeric(substr(pdata$Year_Month,6,7))
#remove duplicate rows
pdata3 <- pdata3[!duplicated(pdata3[1:2]),]

#seasonal depths
for(wellid in unique(pdata3$Well_Id)){
  df = pdata3[pdata3$Well_Id==wellid,]
  for(i in 1:nrow(df)){
    if((df$Month[i]==4 & all(!is.na(df$Depth_ft[i+c(0,5)])))& all(is.na(df$Depth_ft[i+c(1:4)]))&df$Month[i+5]==9){
      dhigh = df$Depth_ft[i+5]
      dlow = df$Depth_ft[i]
      inc = (dhigh-dlow)/6
      df$Depth_ft[i + c(1:4)] = dlow + c(1:4)*inc
    }
    if(i>12){
      if(df$Month[i]==4 & all(!is.na(df$Depth_ft[i+c(0,-7)])) &(all(is.na(df$Depth_ft[i+c(-1:-6)])))&df$Month[i-7]==9){
        dhigh = df$Depth_ft[i-7]
        dlow = df$Depth_ft[i]
        inc = (dhigh-dlow)/8
        df$Depth_ft[i + c(-7:-1)] = dhigh - c(1:7)*inc    
      }
    }
    
  }
  pdata3[pdata3$Well_Id==wellid,] = df
}

#Do it again for 5 and 9
for(wellid in unique(pdata3$Well_Id)){
  df = pdata3[pdata3$Well_Id==wellid,]
  for(i in 1:nrow(df)){
    if((df$Month[i]==5 & all(!is.na(df$Depth_ft[i+c(0,4)])))& all(is.na(df$Depth_ft[i+c(1:3)]))&df$Month[i+4]==9){
      dhigh = df$Depth_ft[i+4]
      dlow = df$Depth_ft[i]
      inc = (dhigh-dlow)/5
      df$Depth_ft[i + c(1:3)] = dlow + c(1:3)*inc
    }
    if(i>12){
      if(df$Month[i]==5 & all(!is.na(df$Depth_ft[i+c(0,-8)])) &(all(is.na(df$Depth_ft[i+c(-1:-7)])))&df$Month[i-8]==9){
        dhigh = df$Depth_ft[i-8]
        dlow = df$Depth_ft[i]
        inc = (dhigh-dlow)/9
        df$Depth_ft[i + c(-7:-1)] = dhigh - c(1:7)*inc    
      }
    }
    
  }
  pdata3[pdata3$Well_Id==wellid,] = df
}

# 5 and 10
for(wellid in unique(pdata3$Well_Id)){
  df = pdata3[pdata3$Well_Id==wellid,]
  for(i in 1:nrow(df)){
    if((df$Month[i]==5 & all(!is.na(df$Depth_ft[i+c(0,5)])))& all(is.na(df$Depth_ft[i+c(1:4)]))&df$Month[i+5]==10){
      dhigh = df$Depth_ft[i+5]
      dlow = df$Depth_ft[i]
      inc = (dhigh-dlow)/6
      df$Depth_ft[i + c(1:4)] = dlow + c(1:4)*inc
    }
    if(i>12){
      if(df$Month[i]==5 & all(!is.na(df$Depth_ft[i+c(0,-7)])) &(all(is.na(df$Depth_ft[i+c(-1:-6)])))&df$Month[i-7]==10){
        dhigh = df$Depth_ft[i-7]
        dlow = df$Depth_ft[i]
        inc = (dhigh-dlow)/8
        df$Depth_ft[i + c(-6:-1)] = dhigh - c(1:6)*inc    
      }
    }
    
  }
  pdata3[pdata3$Well_Id==wellid,] = df
}

#4 and 10
for(wellid in unique(pdata3$Well_Id)){
  df = pdata3[pdata3$Well_Id==wellid,]
  for(i in 1:nrow(df)){
    if((df$Month[i]==4 & all(!is.na(df$Depth_ft[i+c(0,6)])))& all(is.na(df$Depth_ft[i+c(1:5)]))&df$Month[i+6]==10){
      dhigh = df$Depth_ft[i+6]
      dlow = df$Depth_ft[i]
      inc = (dhigh-dlow)/7
      df$Depth_ft[i + c(1:5)] = dlow + c(1:5)*inc
    }
    if(i>12){
      if(df$Month[i]==4 & all(!is.na(df$Depth_ft[i+c(0,-6)])) &(all(is.na(df$Depth_ft[i+c(-1:-5)])))&df$Month[i-6]==10){
        dhigh = df$Depth_ft[i-6]
        dlow = df$Depth_ft[i]
        inc = (dhigh-dlow)/7
        df$Depth_ft[i + c(-5:-1)] = dhigh - c(1:5)*inc    
      }
    }
    
  }
  pdata3[pdata3$Well_Id==wellid,] = df
}


#Properly scale OPPE
for(i in 1:nrow(pdata3)){
  if(!is.na(as.numeric(pdata3$OPPE[i]))& pdata3$OPPE[i] <1){
    pdata3$OPPE[i] = as.numeric(pdata3$OPPE[i])*100
  }
}
#Take as numeric
pdata3$OPPE <- as.numeric(pdata3$OPPE)
#now it is scaled we can begin to impute.


ope = NA
opei = 1
for(i in 1:nrow(pdata3)){
  if(pdata3$Well_Id[i]==pdata3$Well_Id[i+1]){
    if(!is.na(as.numeric(pdata3$OPPE[i]))){
      ope = as.numeric(pdata3$OPPE[i])
      opei = i
    }else{
      if(!is.na(pdata3$Depth_ft[i])&!is.na(pdata3$Depth_ft[opei]) & abs(pdata3$Depth_ft[opei]-pdata3$Depth_ft[i])<10 & pdata3$Depth_ft[opei] >50){
        pdata3$OPPE[i] = ope*(1 - abs(pdata3$Depth_ft[opei]-pdata3$Depth_ft[i])/ pdata3$Depth_ft[opei])
      }else{
        pdata3$OPPE[i] = ope  
      }  
    }
  }else{
    if(pdata3$Well_Id[i]==pdata3$Well_Id[i-1] & is.na(as.numeric(pdata3$OPPE[i]))){
      if(!is.na(pdata3$Depth_ft[i])&!is.na(pdata3$Depth_ft[opei]) & abs(pdata3$Depth_ft[opei]-pdata3$Depth_ft[i])<10 & pdata3$Depth_ft[opei] >50){
        pdata3$OPPE[i] = ope*(1 - abs(pdata3$Depth_ft[opei]-pdata3$Depth_ft[i])/ pdata3$Depth_ft[opei])
      }else{
        pdata3$OPPE[i] = ope  
      }
    }
    ope = NA
  }
}
#That was involved... The reasoning is as follows: 
#The vast majority of pumps in the central valley are centrifugal. 
#Thus with fixed rpms they are optimal for a certain range of depths.
#When the depths shift the efficiency of the pumps changes. 
#To account for these shifts we will adjust by the ratio of depth change. 
#We will assume that as the water level changes beyond its callibrated norm 
#the efficiency of the pump decreases. 
#We also assume no change in efficiency for small depth changes (+- 10 ft).


#Make everything finite
pdata3 <- do.call(data.frame,lapply(pdata3, function(x) replace(x, is.infinite(x),NA)))

#track where there are values being imputed
pdata3$e <- 0
pdata3[!is.na(pdata3$Electricity_kWh),]$e <- 1

#Use a random forest to impute the missing electricity data

rf <- filter(pdata3, !is.na(Volume_ac_ft) & !is.na(Depth_ft) & ! Volume_ac_ft==0)

#break it down into usable chunks
samp <- runif(nrow(rf))
sampS =data.frame(x=rep(0,nrow(rf)))
for(i in 1:10){
  sampS[i] =(samp<.1*i & samp >.1*(i-1))
}

#impute
rfEnergy <- rfImpute(Volume_ac_ft~  Electricity_kWh 
                     + Depth_ft + factor(Month) + factor(Agency), 
                     data = rf, iter=5, ntree=300, 
                     subset = sampS[,1])

#impute the rest of the data set using a loop 
for(i in 2:10){
  rfEnergy1 <- rfImpute(Volume_ac_ft~  Electricity_kWh + 
                        Depth_ft + factor(Month) + factor(Agency), 
                        data = rf, iter=5, ntree=300, subset = sampS[,i])
  rfEnergy =rbind(rfEnergy,rfEnergy1) 
}

#Match the values 
rfEnergy$index <- as.numeric(row.names(rfEnergy))
rfEnergy <- rfEnergy[order(rfEnergy$index),]
#insert them into data set
rf$Electricity_kWh <- rfEnergy$Electricity_kWh

#save the file
con <- file("/Users/jglasskatz/Desktop/rfEnergy.csv",encoding="UTF-8")
write.csv(rf, con, row.names = FALSE)

#Combine the files
rf <- rf[!duplicated(rf[1:2]),]
rf$rf <- 1
pdata4<- left_join(pdata3,rf, by = c('Well_Id','Year_Month'))

#make names easier
colnames(pdata4)[c(4,10)]<- c("Electricity_kWh" ,"OPPE")
#proceed to change electricity
pdata4[is.na(pdata4$Electricity_kWh),]$Electricity_kWh <- pdata4[is.na(pdata4$Electricity_kWh),]$Electricity_kWh.y

#clean it all up
pdata5 <- pdata4[c(1:5,10,19,20,23:26,33:35,71)]
colnames(pdata5)[c(3,5,7:13)]<-c('Volume_local_unit','Depth_ft','Lat','Long','County','Agency','CasID','Volume_ac_ft','Month')

pdata5[is.na(pdata5$Depth_ft) | pdata5$Depth_ft<0,]$Depth_ft <- NA
pdata5[is.na(pdata5$Depth_ft) |is.infinite(pdata5$Depth_ft),]$Depth_ft <- NA
pdata5[is.na(pdata5$Volume_ac_ft) |pdata5$Volume_ac_ft<0,]$Volume_ac_ft <- NA
pdata5[is.na(pdata5$Electricity_kWh) |pdata5$Electricity_kWh<0,]$Electricity_kWh <- NA

#save
con2 <- file("/Users/jglasskatz/Desktop/Pumpclean.csv",encoding="UTF-8")  
write.csv(pdata5, file =con2, row.names = FALSE) 








                     