# R Script: Fleet Share by MW

# Install and load required packages if not already installed
if (!require("readxl")) install.packages("readxl")
if (!require("dplyr")) install.packages("dplyr")
if (!require("stringr")) install.packages("stringr")
if (!require("tidyr")) install.packages("tidyr")
if (!require("ggplot2")) install.packages("ggplot2")

library(readxl)   # For reading Excel files
library(dplyr)    # For data manipulation
library(stringr)  # For splitting and trimming strings
library(tidyr)    # For completing missing combos
library(ggplot2)  # For creating the figure

# 1. Read the Region spreadsheet
# Update the file paths if your files are in a different location
setwd("/Users/nrg/Desktop/University/Spring 2025/CE 4470 - Water for Energy/Term Project/Data")
region_data <- read_excel("Power_Plants_Region4.xlsx")

# 2. Extract only the FIRST plant type from "tech_desc" if multiple are listed
region_data <- region_data %>%
  mutate(Generation_Type_Original = sapply(
    str_split(.data$tech_desc, ";"),
    function(x) str_trim(x[1])
  ))

# 3. Group the generation types into specified categories
region_data <- region_data %>%
  mutate(Generation_Type = case_when(
    str_detect(Generation_Type_Original, "Natural Gas") ~ "Natural Gas",
    Generation_Type_Original %in% c(
      "Solar Thermal with Energy Storage",
      "Solar Photovoltaic",
      "Onshore Wind Turbine",
      "Hydroelectric Pumped Storage",
      "Geothermal",
      "Conventional Hydroelectric"
    ) ~ "Renewables",
    Generation_Type_Original == "Petroleum Liquids"       ~ "Petroleum",
    Generation_Type_Original == "Conventional Steam Coal" ~ "Coal",
    Generation_Type_Original == "Nuclear"                ~ "Nuclear",
    TRUE                                                 ~ "Other"
  ))

# 4. Combine and rename cooling technologies
region_data <- region_data %>%
  mutate(Cooling_Technology = case_when(
    Cooling_Technology == "(DC) Dry Cooling"                    ~ "Dry Cooling",
    Cooling_Technology == "(HRI) Hybrid: Dry / Induced Draft"   ~ "Hybrid Cooling",
    Cooling_Technology %in% c("(OC) Once Through with Cool Pond",
                        "(ON) Once through No Cool Pond") ~ "Once-Through",
    Cooling_Technology == "(RC) Recirculate: Cooling Pond"      ~ "Cooling Pond",
    Cooling_Technology == "(RI) Recirculate: Induced Draft"     ~ "Wet Tower",
    TRUE                                                  ~ Cooling_Technology
  ))

# 5. Define valid categories for generation and cooling
gen_levels <- c("Coal", "Natural Gas", "Nuclear", "Petroleum", "Renewables", "Other")
cool_levels <- c("Cooling Pond", "Dry Cooling", "Hybrid Cooling", "Once-Through", "Wet Tower")

# 6. Filter out any row where Cooling_Technology is not one of the 5 valid categories
region_data <- region_data %>%
  mutate(Cooling_Technology = str_trim(Cooling_Technology)) %>%
  filter(Cooling_Technology %in% cool_levels)

# 7. Sum the total MW by (Generation_Type, Cooling_Technology)
fleet_share_long <- region_data %>%
  group_by(Generation_Type, Cooling_Technology) %>%
  summarize(mw_sum = sum(Total_MW, na.rm = TRUE), .groups = "drop")

# 8. Complete the dataset so that any missing combos have 0 MW
fleet_share_long <- fleet_share_long %>%
  mutate(
    Generation_Type = factor(Generation_Type, levels = gen_levels),
    Cooling_Technology    = factor(Cooling_Technology,    levels = cool_levels)
  ) %>%
  complete(
    Generation_Type = gen_levels,
    Cooling_Technology    = cool_levels,
    fill = list(mw_sum = 0)
  )

# 9. Calculate each cell's share out of the grand total MW
fleet_share_long <- fleet_share_long %>%
  mutate(
    grand_total_mw = sum(mw_sum),
    share_percent  = round((mw_sum / grand_total_mw) * 100, 1)
  ) %>%
  select(-grand_total_mw)

# 10. Create a figure (change title based on region)
p <- ggplot(fleet_share_long, aes(x = Cooling_Technology, y = Generation_Type)) +
  geom_tile(aes(fill = share_percent), color = "white") +
  geom_text(aes(label = share_percent), size = 5) +
  scale_fill_gradient(low = "white", high = "blue") +
  labs(
    title = "Fleet Share by Generation Type and Cooling Technology (Region 4)",
    subtitle = "Share (%) Based on Total Produced MW",
    x = "Cooling Technology",
    y = "Generation Type",
    fill = "Share (%)"
  ) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(hjust = 0.5),      # Center the title
    plot.subtitle = element_text(hjust = 0.5),   # Center the subtitle
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  )

# 11. Show the plot in your R viewer
print(p)

# 12. (Optional) Save the figure to an image or PDF file
ggsave("Fleet_Share_Region4.png", p, width = 8, height = 6, dpi = 300, bg = "white")
# ggsave("Fleet_Share_Region1_MW.pdf", p, width = 8, height = 6)
