# R Script: Comparison of Estimated Electricity Generation, Water Withdrawal, and Water Consumption
# between Reference & Alternative Cases

# Load required libraries
library(readxl)
library(tidyr)
library(dplyr)
library(ggplot2)
library(scales)  # for scientific_format()

# Set working directory to your data folder
setwd("/Users/nrg/Desktop/University/Spring 2025/CE 4470 - Water for Energy/Term Project/Data")

# Define a custom color scale for Generation Types
generation_colors <- c(
  "Coal"         = "#1b9e77",
  "Natural Gas"  = "#d95f02",
  "Nuclear"      = "#7570b3",
  "Renewables"   = "#e7298a",
  "Petroleum"    = "#8B0000"
)

# PART 1: PROCESS PRODUCTION DATA (Electricity Generation)
# Read in the three production datasets
prod_ref  <- read_excel("Processed_Ref_AEOEnergyProduction_National.xlsx")
prod_high <- read_excel("Processed_HighZCT_AEOEnergyProduction_National.xlsx")
prod_low  <- read_excel("Processed_LowZCT_AEOEnergyProduction_National.xlsx")

# Convert to long format and attach a Scenario indicator
prod_ref_long <- prod_ref %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Year", values_to = "Generation_MWh") %>%
  mutate(Year = as.numeric(Year), Scenario = "Reference")

prod_high_long <- prod_high %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Year", values_to = "Generation_MWh") %>%
  mutate(Year = as.numeric(Year), Scenario = "High ZCT")

prod_low_long <- prod_low %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Year", values_to = "Generation_MWh") %>%
  mutate(Year = as.numeric(Year), Scenario = "Low ZCT")

# Combine into one data frame
prod_long <- bind_rows(prod_ref_long, prod_high_long, prod_low_long)

# Create custom facet labels
scenario_labels <- c("Reference" = "Reference Case", 
                     "High ZCT" = "High-ZCT Case", 
                     "Low ZCT" = "Low-ZCT Case")

# Create Figure 1: Electricity Generation with facet panels for each scenario
p_gen <- ggplot(prod_long, aes(x = Year, y = Generation_MWh, color = Generation_Type)) +
  geom_line(size = 1) +
  facet_wrap(~ Scenario, nrow = 1, labeller = labeller(Scenario = scenario_labels)) +
  scale_x_continuous(limits = c(min(prod_long$Year), 2050), breaks = seq(2025, 2050, 5)) +
  # Use scientific notation for y-axis
  scale_y_continuous(labels = scientific_format()) +
  # Apply the same custom color scale
  scale_color_manual(values = generation_colors) +
  labs(title = "National Electricity Generation (MWh)",
       x = "Year",
       y = "Generation (MWh)",
       color = "Generation Type") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        strip.text  = element_text(hjust = 0.5, size = 12))
print(p_gen)

# PART 2: PROCESS DATA FOR WATER WITHDRAWAL
# Read fleet share and water withdrawal factors
fleet <- read_excel("Fleet_Share_National.xlsx")
water_withdraw <- read_excel("Water_Withdrawal_Factors.xlsx")

# Reshape fleet data (assumes first column is Generation_Type)
fleet_long <- fleet %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Fleet_Share") %>%
  mutate(Fleet_Share = Fleet_Share / 100)  # Convert percentages to fractions if needed

# Reshape water withdrawal factors data
water_withdraw_long <- water_withdraw %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Water_Withdrawal_Factor")

# Merge fleet share with water withdrawal factors
fleet_withdraw <- inner_join(fleet_long, water_withdraw_long, by = c("Generation_Type", "Cooling_Type"))

# Merge with production data to include Scenario information
prod_withdraw <- inner_join(prod_long, fleet_withdraw, by = "Generation_Type")

# Adjust fleet shares for years >= 2040 (phase out once-through cooling)
prod_withdraw <- prod_withdraw %>% 
  group_by(Generation_Type, Year, Scenario) %>%
  mutate(OnceShare = if(any(Cooling_Type == "Once-through")) {
    Fleet_Share[Cooling_Type == "Once-through"][1]
  } else {0},
  Adjusted_Fleet_Share = case_when(
    Year >= 2040 & Cooling_Type == "Once-through" ~ 0,
    Year >= 2040 & Cooling_Type == "Wet Tower"    ~ Fleet_Share + OnceShare,
    TRUE ~ Fleet_Share
  )) %>% ungroup()

# Calculate water withdrawal (in gallons)
prod_withdraw <- prod_withdraw %>% 
  mutate(Water_Withdrawal = Generation_MWh * Adjusted_Fleet_Share * Water_Withdrawal_Factor)

# Sum over cooling types to get totals per Generation_Type, Year, and Scenario
withdraw_total <- prod_withdraw %>% 
  group_by(Generation_Type, Year, Scenario) %>% 
  summarise(Total_Water_Withdrawal = sum(Water_Withdrawal, na.rm = TRUE)) %>% 
  ungroup()

# Optionally, omit renewables if not needed
withdraw_total <- withdraw_total %>% filter(Generation_Type != "Renewables")

# Create Figure 2: Water Withdrawal with facet panels for each scenario
p_withdraw <- ggplot(withdraw_total, aes(x = Year, y = Total_Water_Withdrawal, color = Generation_Type)) +
  geom_line(size = 1) +
  facet_wrap(~ Scenario, nrow = 1, labeller = labeller(Scenario = scenario_labels)) +
  scale_x_continuous(limits = c(min(withdraw_total$Year), 2050), breaks = seq(2025, 2050, 5)) +
  # Y-axis in scientific notation
  scale_y_continuous(labels = scientific_format()) +
  # Apply the consistent color scale
  scale_color_manual(values = generation_colors) +
  labs(title = "National Water Withdrawal (gal)",
       x = "Year",
       y = "Water Withdrawal (gal)",
       color = "Generation Type") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        strip.text = element_text(hjust = 0.5, size = 12))
print(p_withdraw)

# PART 3: PROCESS DATA FOR WATER CONSUMPTION
# Read water consumption factors
water_cons <- read_excel("Water_Consumption_Factors.xlsx")

# Reshape water consumption factor data
water_cons_long <- water_cons %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Water_Consumption_Factor")

# Merge fleet share with water consumption factors (using fleet_long from before)
fleet_cons <- inner_join(fleet_long, water_cons_long, by = c("Generation_Type", "Cooling_Type"))

# Merge with production data
prod_cons <- inner_join(prod_long, fleet_cons, by = "Generation_Type")

# Adjust fleet shares for years >= 2040
prod_cons <- prod_cons %>% 
  group_by(Generation_Type, Year, Scenario) %>%
  mutate(OnceShare = if(any(Cooling_Type == "Once-through")) {
    Fleet_Share[Cooling_Type == "Once-through"][1]
  } else {0},
  Adjusted_Fleet_Share = case_when(
    Year >= 2040 & Cooling_Type == "Once-through" ~ 0,
    Year >= 2040 & Cooling_Type == "Wet Tower"    ~ Fleet_Share + OnceShare,
    TRUE ~ Fleet_Share
  )) %>% ungroup()

# Calculate water consumption (in gallons)
prod_cons <- prod_cons %>% 
  mutate(Water_Consumption = Generation_MWh * Adjusted_Fleet_Share * Water_Consumption_Factor)

# Sum over cooling types to get totals per Generation_Type, Year, and Scenario
cons_total <- prod_cons %>% 
  group_by(Generation_Type, Year, Scenario) %>% 
  summarise(Total_Water_Consumption = sum(Water_Consumption, na.rm = TRUE)) %>% 
  ungroup()

# Optionally, remove renewables if not needed
cons_total <- cons_total %>% filter(Generation_Type != "Renewables")

# Create Figure 3: Water Consumption with facet panels for each scenario
p_cons <- ggplot(cons_total, aes(x = Year, y = Total_Water_Consumption, color = Generation_Type)) +
  geom_line(size = 1) +
  facet_wrap(~ Scenario, nrow = 1, labeller = labeller(Scenario = scenario_labels)) +
  scale_x_continuous(limits = c(min(cons_total$Year), 2050), breaks = seq(2025, 2050, 5)) +
  # Y-axis in scientific notation
  scale_y_continuous(labels = scientific_format()) +
  # Apply the consistent color scale
  scale_color_manual(values = generation_colors) +
  labs(title = "National Water Consumption (gal)",
       x = "Year",
       y = "Water Consumption (gal)",
       color = "Generation Type") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        strip.text = element_text(hjust = 0.5, size = 12))
print(p_cons)

# Optionally, save the figures as PNG files
ggsave("Ref_Alt_Electricity_Generation_National.png", p_gen, dpi = 300, width = 10, height = 4, bg = "white")
ggsave("Ref_Alt_Water_Withdrawal_National.png", p_withdraw, dpi = 300, width = 10, height = 4, bg = "white")
ggsave("Ref_Alt_Water_Consumption_National.png", p_cons, dpi = 300, width = 10, height = 4, bg = "white")
