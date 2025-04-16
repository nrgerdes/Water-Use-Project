# R Script: Estimated Electricity Generation, Water Withdrawal, and Water Consumption

# Load required libraries
library(readxl)
library(tidyr)
library(dplyr)
library(ggplot2)
library(scales)  # Added for label_scientific()

# Define custom color mapping for Generation Types
generation_colors <- c(
  "Coal"         = "#1b9e77",
  "Natural Gas"  = "#d95f02",
  "Nuclear"      = "#7570b3",
  "Renewables"   = "#e7298a",
  "Petroleum"    = "#8B0000"
)

# Copy the file path to the folder where your data is
setwd("/Users/nrg/Desktop/University/Spring 2025/CE 4470 - Water for Energy/Term Project/Data")

### FIGURE 1: Electricity Generation by Generation Type (2022-2050)

# Read the processed electricity generation data
# Change the file name if needed; ie, Region1, National, etc.
prod <- read_excel("Processed_Ref_AEOEnergyProduction_Region4.xlsx")

# Reshape from wide to long format
prod_long <- prod %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Year", values_to = "Generation_MWh") %>%
  mutate(Year = as.numeric(Year))

# Create the plot for generation (units in MWh)
p1 <- ggplot(prod_long, aes(x = Year, y = Generation_MWh, color = Generation_Type)) +
  geom_line(size = 1) +
  scale_color_manual(values = generation_colors) +  # Added custom colors for Generation_Type
  scale_x_continuous(
    limits = c(min(prod_long$Year), 2050),
    breaks = seq(2025, 2050, by = 5)
  ) +
  scale_y_continuous(labels = label_scientific()) +  # Added scientific notation for y-axis
  labs(
    title = "Electricity Generation by Generation Type (2022-2050)",
    subtitle = "Region 4",      # Adjust region as needed
    x = "Year",
    y = "Generation (MWh)",
    color = "Generation Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),      
    plot.subtitle = element_text(hjust = 0.5)
  )

print(p1)

### FIGURE 2: Water Consumption by Generation Type (2022-2050)

# Read Fleet Share and Water Consumption Factor data
# Change the file name if needed; ie, Region1, National, etc.
fleet <- read_excel("Fleet_Share_Region4.xlsx")
water_cons <- read_excel("Water_Consumption_Factors.xlsx")

# Reshape fleet data: assumes first column is "Generation_Type" and remaining columns are cooling technology shares
fleet_long <- fleet %>%
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Fleet_Share")
# Uncomment the next line if your fleet shares are in percentages (e.g., 25 for 25%)
fleet_long <- fleet_long %>% mutate(Fleet_Share = Fleet_Share / 100)

# Reshape water consumption factors data
water_cons_long <- water_cons %>%
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Water_Consumption_Factor")

# Merge fleet share with water consumption factors
fleet_water_cons <- inner_join(fleet_long, water_cons_long, by = c("Generation_Type", "Cooling_Type"))

# Join with production data by Generation_Type
prod_fleet <- inner_join(prod_long, fleet_water_cons, by = "Generation_Type")

# Adjust fleet shares for years >= 2040 (phase out once-through cooling)
prod_fleet <- prod_fleet %>% 
  group_by(Generation_Type, Year) %>%
  mutate(
    OnceShare = if (any(Cooling_Type == "Once-through")) {
      Fleet_Share[Cooling_Type == "Once-through"][1]
    } else { 0 },
    Adjusted_Fleet_Share = case_when(
      Year >= 2040 & Cooling_Type == "Once-through" ~ 0,
      Year >= 2040 & Cooling_Type == "Wet Tower"    ~ Fleet_Share + OnceShare,
      TRUE ~ Fleet_Share
    )
  ) %>%
  ungroup()

# Calculate water consumption (in gal)
prod_fleet <- prod_fleet %>%
  mutate(Water_Consumption = Generation_MWh * Adjusted_Fleet_Share * Water_Consumption_Factor)

# Sum over cooling types for each Generation_Type and Year
water_consumption_total <- prod_fleet %>%
  group_by(Generation_Type, Year) %>%
  summarise(Total_Water_Consumption = sum(Water_Consumption, na.rm = TRUE)) %>%
  ungroup()

# Omit renewables from the consumption figure
water_consumption_total_no_renew <- water_consumption_total %>%
  filter(Generation_Type != "Renewables")

# Create the water consumption plot (units in gal)
p2 <- ggplot(water_consumption_total_no_renew, 
             aes(x = Year, y = Total_Water_Consumption, color = Generation_Type)) +
  geom_line(size = 1) +
  scale_color_manual(values = generation_colors) +  # Added custom colors for Generation_Type
  scale_x_continuous(
    limits = c(min(water_consumption_total_no_renew$Year), 2050),
    breaks = seq(2025, 2050, by = 5)
  ) +
  scale_y_continuous(labels = label_scientific()) +  # Added scientific notation for y-axis
  labs(
    title = "Water Consumption by Generation Type (2022-2050)",
    subtitle = "Region 4",      # Adjust region as needed
    x = "Year",
    y = "Water Consumption (gal)",
    color = "Generation Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

print(p2)

### FIGURE 3: Water Withdrawal by Generation Type (2022-2050)

# Read Water Withdrawal Factors
water_withdraw <- read_excel("Water_Withdrawal_Factors.xlsx")

# Reshape water withdrawal factors data
water_withdraw_long <- water_withdraw %>%
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Water_Withdrawal_Factor")

# Merge fleet share with water withdrawal factors
fleet_water_withdraw <- inner_join(fleet_long, water_withdraw_long, by = c("Generation_Type", "Cooling_Type"))

# Join with production data by Generation_Type
prod_fleet_withdraw <- inner_join(prod_long, fleet_water_withdraw, by = "Generation_Type")

# Adjust fleet shares for years >= 2040
prod_fleet_withdraw <- prod_fleet_withdraw %>% 
  group_by(Generation_Type, Year) %>%
  mutate(
    OnceShare = if (any(Cooling_Type == "Once-through")) {
      Fleet_Share[Cooling_Type == "Once-through"][1]
    } else { 0 },
    Adjusted_Fleet_Share = case_when(
      Year >= 2040 & Cooling_Type == "Once-through" ~ 0,
      Year >= 2040 & Cooling_Type == "Wet Tower"    ~ Fleet_Share + OnceShare,
      TRUE ~ Fleet_Share
    )
  ) %>%
  ungroup()

# Calculate water withdrawal (in gal)
prod_fleet_withdraw <- prod_fleet_withdraw %>%
  mutate(Water_Withdrawal = Generation_MWh * Adjusted_Fleet_Share * Water_Withdrawal_Factor)

# Sum over cooling types for each Generation_Type and Year
water_withdrawal_total <- prod_fleet_withdraw %>%
  group_by(Generation_Type, Year) %>%
  summarise(Total_Water_Withdrawal = sum(Water_Withdrawal, na.rm = TRUE)) %>%
  ungroup()

# Omit renewables from the withdrawal figure
water_withdrawal_total_no_renew <- water_withdrawal_total %>%
  filter(Generation_Type != "Renewables")

# Create the water withdrawal plot (units in gal)
p3 <- ggplot(water_withdrawal_total_no_renew, 
             aes(x = Year, y = Total_Water_Withdrawal, color = Generation_Type)) +
  geom_line(size = 1) +
  scale_color_manual(values = generation_colors) +  # Added custom colors for Generation_Type
  scale_x_continuous(
    limits = c(min(water_withdrawal_total_no_renew$Year), 2050),
    breaks = seq(2025, 2050, by = 5)
  ) +
  scale_y_continuous(labels = label_scientific()) +  # Added scientific notation for y-axis
  labs(
    title = "Water Withdrawal by Generation Type (2022-2050)",
    subtitle = "Region 4",      # Adjust region as needed
    x = "Year",
    y = "Water Withdrawal (gal)",
    color = "Generation Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5)
  )

print(p3)

### Exporting Figures as PNGs
###   Update name based on region
ggsave("Ref_Electricity_Generation_Region4.png", p1, dpi = 300, width = 8, height = 6, bg = "white")
ggsave("Ref_Water_Consumption_Region4.png", p2, dpi = 300, width = 8, height = 6, bg = "white")
ggsave("Ref_Water_Withdrawal_Region4.png", p3, dpi = 300, width = 8, height = 6, bg = "white")
