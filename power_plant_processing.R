# R Script: Processes Cooling_Boiler_Generator_Data_Summary_2022
#   Monthly generation to annual generation

# Load required packages
library(readxl)
library(dplyr)
library(openxlsx)

# Set working directory (adjust the path if needed)
setwd("/Users/nrg/Desktop/University/Spring 2025/CE 4470 - Water for Energy/Term Project/Data")

# Read in the Excel file
data <- read_excel("Cooling_Boiler_Generator_Data_Summary_2022.xlsx")

# Group by the constant columns (columns 1,2,3,4,5,6,7, and 9)
# and sum the monthly "Gross Generation from Steam Turbines (MWh)" (column 8)
annual_data <- data %>%
  group_by(across(c(1, 2, 3, 4, 5, 6, 7, 9))) %>%
  summarise(`Gross Generation from Steam Turbines (MWh)` = sum(`Gross Generation from Steam Turbines (MWh)`, na.rm = TRUE),
            .groups = "drop") %>%
  # Remove duplicate rows (if every column's value is identical)
  distinct()

# Rename the columns according to the desired output:
# After grouping, the columns are arranged as follows:
# Column 1: originally from input column A  -> rename to "Utility_ID"
# Column 2: originally from input column B  -> kept as is
# Column 3: originally from input column C  -> rename to "Plant_Code"
# Column 4: originally from input column D  -> rename to "Plant_Name"
# Column 5: originally from input column E  -> kept as is
# Column 6: originally from input column F  -> rename to "Cooling_ID"
# Column 7: originally from input column G  -> rename to "Generating_Tech"
# Column 8: originally from input column I  -> rename to "Cooling_Tech"
# Column 9: the summarized column (from input column H) -> rename to "Annual_Generation_MWh"
colnames(annual_data)[c(1, 3, 4, 6, 7, 8, 9)] <- c("Utility_ID", "Plant_Code", "Plant_Name", "Cooling_ID", "Generating_Tech", "Cooling_Tech", "Annual_Generation_MWh")

# Write the aggregated annual data to a new Excel file
write.xlsx(annual_data, "Cooling_Boiler_Generator_Data_Summary_2022_Annual.xlsx", overwrite = TRUE)

