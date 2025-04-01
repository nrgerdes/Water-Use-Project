# R Script: Adds coordinates to annual EIA data and separates into four regions
#   Uses Cooling_Boiler_Generator_Data_Summary_2022_Annual and Power_Plants
#   spreadsheets.

# Load required packages
library(readxl)
library(dplyr)
library(openxlsx)

# Set working directory (adjust as needed)
setwd("/Users/nrg/Desktop/University/Spring 2025/CE 4470 - Water for Energy/Term Project/Data")

# 1. Read in the national annual data
annual_data <- read.xlsx("Cooling_Boiler_Generator_Data_Summary_2022_Annual.xlsx")

# 2. Read the Power Plants data to get coordinates
power_plants <- read_excel("Power_Plants.xlsx")

# 3. Remove duplicate Utility_IDs from power_plants to avoid duplicate joins
power_plants_unique <- power_plants %>% distinct(Utility_ID, .keep_all = TRUE)

# 4. Join the annual data with the power plants coordinates using Utility_ID
annual_data_with_coords <- annual_data %>%
  left_join(power_plants_unique %>% select(Utility_ID, Longitude, Latitude),
            by = "Utility_ID")

# 5. Adjust (clamp) coordinates so that plants outside our national bounds are assigned the nearest limit.
#    For Longitude, we clamp to [-105, -75]; for Latitude, we clamp to [25, 49].
annual_data_with_coords <- annual_data_with_coords %>%
  mutate(lon_adj = pmax(pmin(Longitude, -65), -125),
         lat_adj = pmax(pmin(Latitude, 50), 25))

# 6. Assign regions using the adjusted coordinates and the specified boundaries:
#    - Region 1: lon_adj between -125 and -107, lat_adj between 25 and 50
#    - Region 2: lon_adj between -107 and -93, lat_adj between 25 and 50
#    - Region 3: lon_adj between -93 and -80, lat_adj between 25 and 50
#    - Region 4: lon_adj between -80 and -65, lat_adj between 25 and 50
annual_data_with_coords <- annual_data_with_coords %>%
  mutate(Region = case_when(
    lon_adj >= -125 & lon_adj < -107 & lat_adj >= 25 & lat_adj < 50 ~ "Region 1",
    lon_adj >= -107  & lon_adj < -93 & lat_adj >= 25 & lat_adj < 50 ~ "Region 2",
    lon_adj >= -93 & lon_adj < -80 & lat_adj >= 25 & lat_adj < 50 ~ "Region 3",
    lon_adj >= -80  & lon_adj < -65 & lat_adj >= 25 & lat_adj < 50 ~ "Region 4",
    TRUE ~ NA_character_
  ))

# Optionally remove the auxiliary adjusted coordinate columns
annual_data_with_coords <- annual_data_with_coords %>% select(-lon_adj, -lat_adj)

# 7. Split the data into separate data frames for each region (if needed)
region1 <- annual_data_with_coords %>% filter(Region == "Region 1")
region2 <- annual_data_with_coords %>% filter(Region == "Region 2")
region3 <- annual_data_with_coords %>% filter(Region == "Region 3")
region4 <- annual_data_with_coords %>% filter(Region == "Region 4")

# 8. Write each region's data to separate Excel files (optional)
write.xlsx(region1, "Annual_Data_Region1.xlsx")
write.xlsx(region2, "Annual_Data_Region2.xlsx")
write.xlsx(region3, "Annual_Data_Region3.xlsx")
write.xlsx(region4, "Annual_Data_Region4.xlsx")

# 9. Write the combined data (all regions with a Region column) to a single-sheet Excel file
write.xlsx(annual_data_with_coords, "Annual_Data_National.xlsx")
