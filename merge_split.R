# R Script: Merge and Split

# Install and load required packages (if not already installed)
if (!require("readxl")) install.packages("readxl")
if (!require("dplyr")) install.packages("dplyr")
if (!require("openxlsx")) install.packages("openxlsx")
if (!require("sf")) install.packages("sf")  # Optional: for advanced spatial operations

library(readxl)    # For reading Excel files
library(dplyr)     # For data manipulation
library(openxlsx)  # For writing Excel files
library(sf)        # For spatial operations (optional)

# 1. Read in the Excel files
# Update the file paths if your files are in a different location.
setwd("/Users/nrg/Desktop/University/Spring 2025/CE 4470 - Water for Energy/Term Project/Data")
cooling_data <- read_excel("Cooling_Boiler_Generator_Data_Detail_2023.xlsx")
power_plants <- read_excel("Power_Plants.xlsx")

# 2. Subset the Power Plants data
# We keep columns F through AH (i.e. columns 6 to 34).
power_plants_subset <- power_plants[, 6:34]

# 3. Extract the Cooling Technology and Utility_ID from cooling_data
# Here we extract column Utility_ID and column cooling technology.
# Adjust the column indexes if your file structure differs.
cooling_tech <- cooling_data[, c(1, 38)]
# Rename the columns to "Utility ID" and "Cooling_Technology"
names(cooling_tech)[1] <- "Utility_ID"
names(cooling_tech)[2] <- "Cooling_Technology"

# 3.1 Remove duplicate rows so that only the first instance of each Utility_ID is kept.
cooling_tech <- cooling_tech %>% distinct(Utility_ID, .keep_all = TRUE)

# 4. Merge the two datasets
# This step assumes that the power_plants data also contains a "Utility_ID" column.
combined_data <- left_join(power_plants_subset, cooling_tech, by = "Utility_ID")

# 4.1 Remove rows with missing Cooling_Tech values (delete rows where Cooling_Tech is NA)
combined_data <- combined_data %>% filter(!is.na(Cooling_Technology))

# 5. Define a function to assign regions based on plant coordinates
# The following boundaries are set using a vertical line at -97 longitude and a horizontal line at 37.5 latitude.
# These choices approximate a division of the contiguous US:
#   - Region 1 (Northwest):   lon < -97 and lat >= 37.5
#   - Region 2 (Southwest):   lon < -97 and lat < 37.5
#   - Region 3 (Northeast):   lon >= -97 and lat >= 37.5
#   - Region 4 (Southeast):   lon >= -97 and lat < 37.5
#
# NOTE: Adjust these boundaries as needed to better reflect the actual NERC regional definitions
# provided in the "nerc_map_proposed" document.
assign_region <- function(lon, lat) {
  if (lon < -97 & lat >= 37.5) {
    return("Region 1")  # Northwest
  } else if (lon < -97 & lat < 37.5) {
    return("Region 2")  # Southwest
  } else if (lon >= -97 & lat >= 37.5) {
    return("Region 3")  # Northeast
  } else if (lon >= -97 & lat < 37.5) {
    return("Region 4")  # Southeast
  } else {
    return(NA)  # For coordinates outside defined regions
  }
}

# 6. Apply the region assignment function to each row
# Replace 'Longitude' and 'Latitude' with the actual names of the coordinate columns in your data.
# For example, if your columns are named "Lon" and "Lat", update accordingly.
combined_data$Region <- mapply(assign_region, combined_data$Longitude, combined_data$Latitude)

# 7. Split the combined data by region
region_data <- split(combined_data, combined_data$Region)

# 8. Write each region’s data to a separate Excel file
# The output files will be named "Power_Plants_Region1.xlsx", "Power_Plants_Region2.xlsx", etc.
for (region in names(region_data)) {
  if (!is.na(region) && region != "NA") {
    file_name <- paste0("Power_Plants_", gsub(" ", "", region), ".xlsx")
    write.xlsx(region_data[[region]], file = file_name)
    cat("File saved:", file_name, "\n")
  }
}

# 9. Optional: Write the combined data (all regions together) to an Excel file
write.xlsx(combined_data, file = "Combined_Power_Plants.xlsx")
cat("Combined data file saved: Combined_Power_Plants.xlsx\n")

# ------------------------------------------------------------- #
# Instructions:
# 1. Ensure that the Excel files "Cooling_Boiler_Generator_Data_Detail_2023.xlsx"
#    and "Power_Plants.xlsx" are in your working directory or update the file paths accordingly.
#
# 2. The script subsets the "Power_Plants" file to keep only columns F through AH.
#
# 3. It then extracts column AL (cooling technology) from the cooling data and merges it
#    with the power plants data using a common identifier ("Utility_ID"). Update this column name as needed.
#
# 4. The assign_region() function uses a vertical split at -97° longitude and a horizontal split at 37.5° latitude
#    to classify each plant into one of four regions. Adjust these boundaries to match the actual NERC regional definitions.
#
# 5. Running the script creates:
#    - A combined Excel file ("Combined_Power_Plants.xlsx") with the merged data and assigned regions.
#    - Four separate Excel files (one per region) named "Power_Plants_Region1.xlsx", etc.
#
# 6. Make sure you have installed the required R packages. Use install.packages() if any are missing.
