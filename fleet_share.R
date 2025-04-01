# R Script: Fleet Share by MW using Annual National Data

# Install and load required packages if not already installed
if (!require("readxl")) install.packages("readxl")
if (!require("dplyr")) install.packages("dplyr")
if (!require("stringr")) install.packages("stringr")
if (!require("tidyr")) install.packages("tidyr")
if (!require("ggplot2")) install.packages("ggplot2")

library(readxl)    # For reading Excel files
library(dplyr)     # For data manipulation
library(stringr)   # For string operations
library(tidyr)     # For completing missing combinations
library(ggplot2)   # For plotting

# 1. Read the dataset (Annual_Data_National.xlsx)
setwd("/Users/nrg/Desktop/University/Spring 2025/CE 4470 - Water for Energy/Term Project/Data")
new_data <- read_excel("Annual_Data_National.xlsx")

# 2. Rename columns by position:
#    Column G (7th column) -> Generation_Type,
#    Column H (8th column) -> Cooling_Tech,
#    Column I (9th column) -> Total_MW.
names(new_data)[7:9] <- c("Generation_Type", "Cooling_Tech", "Total_MW")

# 3. Fix any missing or "NA" strings in Generation_Type by mapping them to "Other"
new_data <- new_data %>%
  mutate(Generation_Type = ifelse(is.na(Generation_Type) | Generation_Type == "NA" | Generation_Type == "",
                                  "Other", Generation_Type))

# 4. Map Generation_Type into categories.
new_data <- new_data %>%
  mutate(Generation_Type = case_when(
    Generation_Type %in% c("Natural Gas Fired Combined Cycle",
                           "Natural Gas Steam Turbine",
                           "Multiple",
                           "Other Gases") ~ "Natural Gas",
    Generation_Type %in% c("Other Waste Biomass",
                           "Solar Thermal with Energy Storage",
                           "Solar Thermal without Energy Storage",
                           "Municipal Solid Waste",
                           "Wood/Wood Waste Biomass") ~ "Renewables",
    Generation_Type %in% c("Coal Integrated Gasification Combined Cycle",
                           "Conventional Steam Coal") ~ "Coal",
    Generation_Type %in% c("Petroleum Coke",
                           "Petroleum Liquids") ~ "Petroleum",
    Generation_Type == "Nuclear" ~ "Nuclear",
    TRUE ~ "Other"
  ))

# 5. Fix any missing or "NA" strings in Cooling_Tech; assign "Unmapped_Cooling" if needed.
new_data <- new_data %>%
  mutate(Cooling_Tech = ifelse(is.na(Cooling_Tech) | Cooling_Tech == "NA" | Cooling_Tech == "",
                               "Unmapped_Cooling", Cooling_Tech))

# 6. Map Cooling_Tech into your five valid categories.
new_data <- new_data %>%
  mutate(Cooling_Tech = case_when(
    Cooling_Tech == "(DC) Dry Cooling" ~ "Dry Cooling",
    Cooling_Tech %in% c("(HRI) Hybrid: Dry / Induced Draft", "Mixture of Cooling Types") ~ "Hybrid Cooling",
    Cooling_Tech %in% c("(OC) Once Through with Cool Pond", "(RC) Recirculate: Cooling Pond") ~ "Cooling Pond",
    Cooling_Tech == "(ON) Once through No Cool Pond" ~ "Once-Through",
    Cooling_Tech %in% c("(RI) Recirculate: Induced Draft",
                        "(RF) Recirculate: Forced Draft",
                        "(RN) Recirculate: Natural Draft") ~ "Wet Tower",
    TRUE ~ Cooling_Tech
  ))

# 7. Define valid factor levels for Generation and Cooling.
gen_levels <- c("Coal", "Natural Gas", "Nuclear", "Petroleum", "Renewables", "Other")
cool_levels <- c("Cooling Pond", "Dry Cooling", "Hybrid Cooling", "Once-Through", "Wet Tower")

# 8. Filter out any row with Cooling_Tech not in cool_levels.
new_data <- new_data %>%
  mutate(Cooling_Tech = str_trim(Cooling_Tech)) %>%
  filter(Cooling_Tech %in% cool_levels)

# 9. Aggregate total MW by (Generation_Type, Cooling_Tech)
fleet_share_long <- new_data %>%
  group_by(Generation_Type, Cooling_Tech) %>%
  summarize(mw_sum = sum(Total_MW, na.rm = TRUE), .groups = "drop")

# 10. Complete the dataset so that every combination appears (fill missing combos with 0 MW).
fleet_share_long <- fleet_share_long %>%
  mutate(
    Generation_Type = factor(Generation_Type, levels = gen_levels),
    Cooling_Tech    = factor(Cooling_Tech, levels = cool_levels)
  ) %>%
  complete(
    Generation_Type = gen_levels,
    Cooling_Tech = cool_levels,
    fill = list(mw_sum = 0)
  )

# 11. Compute the grand total MW (including all categories)
grand_total_mw <- sum(fleet_share_long$mw_sum) + 888450000
  # Add total renewable generation for 2022 above
    # National = 888450000
    # Region 1 = 
    # Region 2 =
    # Region 3 =
    # Region 4 = 140170000

# 12. Calculate each cell's share as a percentage of the grand total.
fleet_share_long <- fleet_share_long %>%
  mutate(share_percent = round((mw_sum / grand_total_mw) * 100, 1))

# 13. Create the heatmap with a centered title and subtitle.
p <- ggplot(fleet_share_long, aes(x = Cooling_Tech, y = Generation_Type)) +
  geom_tile(aes(fill = share_percent), color = "white") +
  geom_text(aes(label = share_percent), size = 5, na.rm = TRUE) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(
    title = "Fleet Share by Generation Type and Cooling Technology (National)",
    subtitle = "Share (%) Based on Total MWh",
    x = "Cooling Technology",
    y = "Generation Type",
    fill = "Share (%)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

# 14. Display the plot.
print(p)

# 15. (Optional) Save the figure.
# ggsave("Fleet_Share_Region4.png", p, width = 8, height = 6, dpi = 300, bg = "white")
# ggsave("Fleet_Share_Region4.pdf", p, width = 8, height = 6)
