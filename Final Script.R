# Set working directory to where the CSV files are stored
setwd("~/R/Capstone Project/Capstone project data")

# Load necessary packages
library(tidyverse)
library(dplyr)
library(skimr)
library(lubridate)

# Importing the files to investigate our data in R
trdt_2302 <- read_csv("202302-divvy-tripdata.csv")
trdt_2301 <- read.csv("202301-divvy-tripdata.csv")
trdt_2212 <- read.csv("202212-divvy-tripdata.csv")
trdt_2211 <- read.csv("202211-divvy-tripdata.csv")
trdt_2210 <- read.csv("202210-divvy-tripdata.csv")
trdt_2209 <- read.csv("202209-divvy-tripdata.csv")
trdt_2208 <- read.csv("202208-divvy-tripdata.csv")
trdt_2207 <- read.csv("202207-divvy-tripdata.csv")
trdt_2206 <- read.csv("202206-divvy-tripdata.csv")
trdt_2205 <- read.csv("202205-divvy-tripdata.csv")
trdt_2204 <- read.csv("202204-divvy-tripdata.csv")
trdt_2203 <- read.csv("202203-divvy-tripdata.csv")

# Isnpecting files to check the structure of data.
glimpse(trdt_2302)

# Read in the CSV files and combine into one dataframe
df <- list.files(pattern = "*.csv") %>% 
  map_df(read_csv)

# Check the dimensions of the dataframe
dim(df)

# Skim our data to gain some valuable information
skim(df)

#Checking if there are any duplicate values by ride_id
dplct_ride_id <- df[duplicated(df$ride_id),]

# Checking for missing values in our dataset
missing_vals <- df %>% summarise_all(~sum(is.na(.)))

missing_vals_by_rideable_type <- df %>% 
  group_by(rideable_type) %>% 
  summarise_all(~sum(is.na(.)))

missing_vals_by_member_casual <- df %>% 
  group_by(member_casual) %>% 
  summarise_all(~sum(is.na(.)))

# Convert the date columns to POSIXct
df$ended_at <- as.POSIXct(df$ended_at)
df$started_at <- as.POSIXct(df$started_at)

# Extract date and time information
df <- df %>% 
  mutate(weekday = factor(wday(started_at, week_start = 1), 
                          levels = 1:7, 
                          labels = c("Mon", "Tue", "Wed","Thu", "Fri", "Sat", "Sun")),
                    weekend_weekday = if_else(weekday %in% c("Sat", "Sun"), "weekend", "weekday"),
                    month = factor(month(started_at, abbr = TRUE, label = TRUE)),
                    date_no_time = as.Date(started_at),
                    hour_only = hour(started_at))

# Calculating the length of each ride and rounding it.
df$ride_length <- as.numeric(difftime(df$ended_at, df$started_at, units = "mins"))
df$ride_length <- round(df$ride_length, 2)

# create a new variable called "is_round_trip"
df$round_trip <- ifelse(df$start_station_name == df$end_station_name, "yes", "no")

# Converting rideable_type, member_casual, day_of_week to factor
df$rideable_type <- as.factor(df$rideable_type)
df$member_casual <- as.factor(df$member_casual)
df$round_trip <- as.factor(df$round_trip)

# Replace suffixes in start_station_name column
df$start_station_name <- gsub("\\(.*?\\)", "", df$start_station_name) # Remove text inside parentheses
df$start_station_name <- gsub("\\*", "", df$start_station_name) # Remove asterisks

# Replace suffixes in end_station_name column
df$end_station_name <- gsub("\\(.*?\\)", "", df$end_station_name) # Remove text inside parentheses
df$end_station_name <- gsub("\\*", "", df$end_station_name) # Remove asterisks

# Filter for ride lengths > 1 minute and < 1440 minutes
df <- df %>%
  filter(ride_length > 1 & ride_length< 1440)

# Drop missing values in end_lng and end_lat variables
df <- df %>%
  drop_na(end_lng, end_lat)

# Drop missing values from the station names and station id variables.
df <- df %>% 
  drop_na(start_station_id, start_station_name, end_station_id, end_station_name)

# Count rides that are meant for repairs.
sum(grepl("warehouse", df$start_station_name, ignore.case = TRUE) | 
      grepl("warehouse", df$end_station_name, ignore.case = TRUE) |
      grepl("testing", df$start_station_name, ignore.case = TRUE) |
      grepl("testing", df$end_station_name, ignore.case = TRUE) |
      grepl("repair", df$start_station_name, ignore.case = TRUE) |
      grepl("repair", df$end_station_name, ignore.case = TRUE) |
      grepl("test", df$start_station_name, ignore.case = TRUE) |
      grepl("test", df$end_station_name, ignore.case = TRUE) | 
      grepl("check", df$start_station_name, ignore.case = TRUE) |
      grepl("check", df$end_station_name, ignore.case = TRUE))

# create a vector of strings to remove
strings_to_remove <- c("warehouse", "testing", "repair", "test", "check")

# filter out rows containing the strings to remove
df <- df %>%
  filter(!grepl(paste(strings_to_remove, collapse = "|"), start_station_name, ignore.case = TRUE),
         !grepl(paste(strings_to_remove, collapse = "|"), end_station_name, ignore.case = TRUE))

# Extracting CSV File.
write.csv(df, "clean_df.csv", row.names = FALSE)

# -------Continuing on Tableau---------


