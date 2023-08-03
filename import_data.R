library(tidyverse)
library(janitor)
library(lubridate)
library(RSQLite)
library(ggplot2)
#install.packages('leaflet')
library(leaflet)
#install.packages("htmlwidgets")
library(htmlwidgets)
#install.packages("htmltools")
library(htmltools)
##
##importing data
##
df1<-read.csv("./2020apr.csv")
df2<-read.csv("./2020may.csv")
df3<-read.csv("./2020jun.csv")
df4<-read.csv("./2020jul.csv")
df5<-read.csv("./2020aug.csv")
df6<-read.csv("./2020sep.csv")
df7<-read.csv("./2020oct.csv")
df8<-read.csv("./2020nov.csv")
df9<-read.csv("./2020dec.csv")
df10<-read.csv("./2021jan.csv")
df11<-read.csv("./2021feb.csv")
df12<-read.csv("./2021mar.csv")

##
##Combine 12 data into one dataframe
##

bike_rides <- rbind(df1,df2,df3,df4,df5,df6,df7,df8,df9,df10,df11,df12)

##
## CHecking types of our dataframe 
##
str(bike_rides)
colnames(bike_rides)
glimpse(bike_rides)




##
##checking duplicated values
##
nrow(bike_rides)
bike_rides_nd<- bike_rides[!duplicated(bike_rides$ride_id),]
print(paste("Removed ",nrow(bike_rides)-nrow(bike_rides_nd),'rows'))

##
###parsing date-time columns
##

bike_rides_nd$started_at<- strptime(bike_rides_nd$started_at,format="%Y-%m-%d %H:%M:%S", tz="America/Chicago")
bike_rides_nd$ended_at<- strptime(bike_rides_nd$ended_at, format="%Y-%m-%d %H:%M:%S", tz="America/Chicago")

##checking if we could change it
str(bike_rides_nd)

##
## Creating new columns as day month year
##

bike_rides_nd$date<- as.Date(bike_rides_nd$started_at)
bike_rides_nd$month<- format(as.Date(bike_rides_nd$started_at),"%m")
bike_rides_nd$day<- format(as.Date(bike_rides_nd$started_at),"%d")
bike_rides_nd$year<- format(as.Date(bike_rides_nd$started_at),"%Y")
bike_rides_nd$day_of_week<- format(as.Date(bike_rides_nd$started_at),"%A")


##
## Creating a ride_length col to calculate trip in seconds
##

bike_rides_nd$ride_length<- difftime(bike_rides_nd$ended_at,bike_rides_nd$started_at)
bike_rides_nd$ride_length<- as.numeric(as.character(bike_rides_nd$ride_length))
str(bike_rides_nd)

##converting ride length into minutes
bike_rides_nd$ride_length_m<-bike_rides_nd$ride_length/60
summary(bike_rides_nd$ride_length_m)

#this summary gives us the result of outliers existence


##
##Outliers
##

boxplot(bike_rides_nd$ride_length_m, ylab = "riding times")
attach(bike_rides_nd)
bike_rides_nd[order(ride_length_m),]

boxplot.stats(bike_rides_nd$ride_length_m)$out

max(bike_rides_nd$ride_length_m)

##removing minus values in riding time which is not logical
bike_rides_nd<-bike_rides_nd %>% 
  filter(ride_length_m >= 1)


##
##Removing outliers with 1.5IQR method
##



quartiles<-quantile(bike_rides_nd$ride_length_m,probs=c(.25,.75),na.rm=FALSE)
IQR<-IQR(bike_rides_nd$ride_length_m) ## q3-q1 = IQR
lower<-quartiles[1]-IQR*1.5
upper<-quartiles[2]+IQR*1.5


df<- subset(bike_rides_nd,bike_rides_nd$ride_length_m > lower & bike_rides_nd$ride_length_m < upper)

boxplot(df$ride_length_m)
summary(df$ride_length_m)



##
##Checking NA values
##

sum(is.na(df))
df<-clean_names(df)
df<-remove_empty(df)
df <- df %>% drop_na()
summary(df)


## Now We can start analyzing 

##

## Member vs Casual Riding times

aggregate(df$ride_length~df$member_casual,FUN=mean)
aggregate(df$ride_length~df$member_casual,FUN=median)
aggregate(df$ride_length~df$member_casual,FUN=max)
aggregate(df$ride_length~df$member_casual,FUN=min)


## User Percentage (member vs casual)

df %>% 
  group_by(member_casual) %>% 
  summarise(count=length(ride_id),"percentage"=(length(ride_id)/nrow(df))*100)

ggplot(df,aes(member_casual,fill=member_casual))+
  geom_bar()+
  labs(x="Casuals vs Members",title = "User Distribution")

## average ride time(minutes) by day for members vs casual
df$day_of_week<-ordered(df$day_of_week, levels=c("Monday","Tuesday", "Wednesday", "Thursday", "Friday", "Saturday","Sunday"))
aggregate(df$ride_length_m~df$member_casual+df$day_of_week,FUN=mean)


## Number of rides by Day member vs casual

df %>% 
  mutate(weekday=wday(started_at,label=TRUE)) %>% 
  group_by(member_casual,weekday) %>% 
  summarise(number_of_rides=n(),average_duration=mean(ride_length_m)) %>%
  arrange(member_casual,weekday) %>% 
  ggplot(aes(x=weekday,y=number_of_rides,fill=member_casual))+
  geom_col(position='dodge')

## Usage by Month

df %>% 
  group_by(member_casual,month) %>% 
  summarise(number_of_rides=n(),average_duration=mean(ride_length_m)) %>% 
  arrange(member_casual,month) %>% 
  ggplot(aes(x=month,y=number_of_rides,fill=member_casual))+
  geom_col(position='dodge')+labs(title='Total usage by month member vs casual',x=" th Month",y="Number of rides")


## bike type usage members vs casual
df %>% 
  group_by(rideable_type,member_casual) %>% 
  summarize(mean_min=mean(ride_length_m))

dftype<- df %>% 
  group_by(rideable_type,member_casual) %>% 
  summarize(mean_min=mean(ride_length_m))

dftype %>% 
  ggplot(aes(x=rideable_type,y=mean_min,fill=member_casual))+
  geom_col(position = position_dodge(),width = 0.6)+
  labs(x='Type',y="mean",fill='Membership')+
  ggtitle("Mean Trip Duration by Type of Bike")


## Total usage in Specific hours member vs casual
df$hour <- format(df$started_at, "%H")
table(df$hour,df$member_casual)
dftod<- df %>% 
  group_by(hour,member_casual) %>% 
  summarize(n=n()) %>% 
  mutate_if(is.numeric,round,2) %>% 
  print(n=nrow(24))

dftod %>% 
  ggplot()+
  geom_line(aes(x=hour,y=n,color=member_casual,group=member_casual),size=3)+
  labs(x = "Time of Day", y = "Number of Trips", fill = "Membership Type") +
  ggtitle("Number of Trips per Time of Day")


## Stations Map view

dfmap<-df %>% 
  group_by(start_station_name) %>%
  summarize(n=n())
  dfmap[order(dfmap$n,decreasing = TRUE),]
  
  


## created Dataframe with coordinates
dfcoor<- df %>% 
  select(start_station_name,start_lat,start_lng) %>% 
  group_by(start_station_name) %>% 
  mutate(num_trips=n()) %>% 
  distinct(start_station_name,.keep_all = TRUE)

dfcoor<- dfcoor[order(-dfcoor$num_trips),]

map_bins <- seq(0, 50000, by = 5000)

my_palette <- colorBin(palette ="viridis", domain = dfcoor$num_trips, na.color = "transparent", bins = map_bins, reverse = TRUE)


# set text for interactive
map_text <- paste("Station name: ", dfcoor$start_station_name, "<br/>","Number of trips: ", dfcoor$num_trips, sep = "") %>%
  lapply(htmltools::HTML)


# widget 
trips_per<-leaflet(dfcoor) %>% 
  addTiles() %>%
#set Chicago coordinates
setView(lng=-87.6298,lat=41.8781,zoom=10.5) %>% 

#set map style
addProviderTiles("Esri.WorldGrayCanvas") %>% 

  
#add Circles for each station
  addCircleMarkers(~start_lng,~start_lat,fillColor = ~my_palette(num_trips),fillOpacity = 0.6,color='white',radius=6,stroke=FALSE,label = map_text,labelOptions = labelOptions(style = list("font-weight"="normal",padding="3px 8px"),textsize = "13px",direction = "auto")) %>% 
  
#add legend.
  addLegend( 
    pal = my_palette, 
    values = ~ num_trips, 
    opacity = 0.8,
    title = "Number of Trips", 
    position = "bottomright")  

#view map.
trips_per
