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

# Create custom facet labels for scenarios
scenario_labels <- c(
  "Reference" = "Reference Case", 
  "High ZCT"  = "High-ZCT Case", 
  "Low ZCT"   = "Low-ZCT Case"
)

# Create Figure 1: Electricity Generation with facet panels for each scenario
p_gen <- ggplot(prod_long, aes(x = Year, y = Generation_MWh, color = Generation_Type)) +
  geom_line(size = 1) +
  facet_wrap(~ Scenario, nrow = 1, labeller = labeller(Scenario = scenario_labels)) +
  scale_x_continuous(limits = c(min(prod_long$Year), 2050), breaks = seq(2025, 2050, 5)) +
  scale_y_continuous(labels = scientific_format()) +
  scale_color_manual(values = generation_colors) +
  labs(title = "National Electricity Generation (MWh)",
       x = "Year",
       y = "Generation (MWh)",
       color = "Generation Type") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        strip.text  = element_text(hjust = 0.5, size = 12))
print(p_gen)

ggsave("Ref_Alt_Electricity_Generation_National.png", p_gen, dpi = 300, width = 10, height = 4, bg = "white")

# PART 2: PROCESS DATA FOR WATER WITHDRAWAL
fleet <- read_excel("Fleet_Share_National.xlsx")
water_withdraw <- read_excel("Water_Withdrawal_Factors.xlsx")

fleet_long <- fleet %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Fleet_Share") %>%
  mutate(Fleet_Share = Fleet_Share / 100)

water_withdraw_long <- water_withdraw %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Water_Withdrawal_Factor")

fleet_withdraw <- inner_join(fleet_long, water_withdraw_long, by = c("Generation_Type", "Cooling_Type"))
prod_withdraw <- inner_join(prod_long, fleet_withdraw, by = "Generation_Type")

prod_withdraw <- prod_withdraw %>% 
  group_by(Generation_Type, Year, Scenario) %>%
  mutate(OnceShare = if(any(Cooling_Type == "Once-through")) {
    Fleet_Share[Cooling_Type == "Once-through"][1]
  } else {0},
  Adjusted_Fleet_Share = case_when(
    Year >= 2040 & Cooling_Type == "Once-through" ~ 0,
    Year >= 2040 & Cooling_Type == "Wet Tower"    ~ Fleet_Share + OnceShare,
    TRUE ~ Fleet_Share
  )) %>%
  ungroup()

prod_withdraw <- prod_withdraw %>% 
  mutate(Water_Withdrawal = Generation_MWh * Adjusted_Fleet_Share * Water_Withdrawal_Factor)

withdraw_total <- prod_withdraw %>% 
  group_by(Generation_Type, Year, Scenario) %>% 
  summarise(Total_Water_Withdrawal = sum(Water_Withdrawal, na.rm = TRUE)) %>% 
  ungroup() %>% 
  filter(Generation_Type != "Renewables")

p_withdraw <- ggplot(withdraw_total, aes(x = Year, y = Total_Water_Withdrawal, color = Generation_Type)) +
  geom_line(size = 1) +
  facet_wrap(~ Scenario, nrow = 1, labeller = labeller(Scenario = scenario_labels)) +
  scale_x_continuous(limits = c(min(withdraw_total$Year), 2050), breaks = seq(2025, 2050, 5)) +
  scale_y_continuous(labels = scientific_format()) +
  scale_color_manual(values = generation_colors) +
  labs(title = "National Water Withdrawal (gal)",
       x = "Year",
       y = "Water Withdrawal (gal)",
       color = "Generation Type") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        strip.text = element_text(hjust = 0.5, size = 12))
print(p_withdraw)

ggsave("Ref_Alt_Water_Withdrawal_National.png", p_withdraw, dpi = 300, width = 10, height = 4, bg = "white")

# PART 3: PROCESS DATA FOR WATER CONSUMPTION
water_cons <- read_excel("Water_Consumption_Factors.xlsx")

water_cons_long <- water_cons %>% 
  pivot_longer(cols = -Generation_Type, names_to = "Cooling_Type", values_to = "Water_Consumption_Factor")

fleet_cons <- inner_join(fleet_long, water_cons_long, by = c("Generation_Type", "Cooling_Type"))
prod_cons <- inner_join(prod_long, fleet_cons, by = "Generation_Type")

prod_cons <- prod_cons %>% 
  group_by(Generation_Type, Year, Scenario) %>%
  mutate(OnceShare = if(any(Cooling_Type == "Once-through")) {
    Fleet_Share[Cooling_Type == "Once-through"][1]
  } else {0},
  Adjusted_Fleet_Share = case_when(
    Year >= 2040 & Cooling_Type == "Once-through" ~ 0,
    Year >= 2040 & Cooling_Type == "Wet Tower"    ~ Fleet_Share + OnceShare,
    TRUE ~ Fleet_Share
  )) %>%
  ungroup()

prod_cons <- prod_cons %>% 
  mutate(Water_Consumption = Generation_MWh * Adjusted_Fleet_Share * Water_Consumption_Factor)

cons_total <- prod_cons %>% 
  group_by(Generation_Type, Year, Scenario) %>% 
  summarise(Total_Water_Consumption = sum(Water_Consumption, na.rm = TRUE)) %>% 
  ungroup() %>% 
  filter(Generation_Type != "Renewables")

p_cons <- ggplot(cons_total, aes(x = Year, y = Total_Water_Consumption, color = Generation_Type)) +
  geom_line(size = 1) +
  facet_wrap(~ Scenario, nrow = 1, labeller = labeller(Scenario = scenario_labels)) +
  scale_x_continuous(limits = c(min(cons_total$Year), 2050), breaks = seq(2025, 2050, 5)) +
  scale_y_continuous(labels = scientific_format()) +
  scale_color_manual(values = generation_colors) +
  labs(title = "National Water Consumption (gal)",
       x = "Year",
       y = "Water Consumption (gal)",
       color = "Generation Type") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16),
        strip.text = element_text(hjust = 0.5, size = 12))
print(p_cons)

ggsave("Ref_Alt_Water_Consumption_National.png", p_cons, dpi = 300, width = 10, height = 4, bg = "white")

# PART 4: TOTAL CASE COMPARISONS

# Compute total electricity generation by Year and Scenario
gen_total <- prod_long %>% 
  group_by(Year, Scenario) %>% 
  summarise(Total_Generation_MWh = sum(Generation_MWh, na.rm = TRUE)) %>% 
  ungroup()

# Plot Figure 4: Total Electricity Generation comparison
p_gen_total <- ggplot(gen_total, aes(x = Year, y = Total_Generation_MWh, linetype = Scenario)) +
  geom_line(size = 1, color = "black") +
  scale_linetype_manual(values = c("Reference" = "solid", "High ZCT" = "dashed", "Low ZCT" = "dotted"),
                        labels = scenario_labels) +
  scale_x_continuous(limits = c(min(gen_total$Year), 2050), breaks = seq(2025, 2050, 5)) +
  scale_y_continuous(labels = scientific_format()) +
  labs(title = "Total National Electricity Generation (MWh)",
       x = "Year",
       y = "Generation (MWh)",
       linetype = "Scenario") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16))
print(p_gen_total)

ggsave("Total_Electricity_Generation_Comparison.png", p_gen_total, dpi = 300, width = 8, height = 4, bg = "white")

# Compute total water withdrawal by Year and Scenario
withdraw_all_total <- prod_withdraw %>% 
  group_by(Year, Scenario) %>% 
  summarise(Total_Water_Withdrawal = sum(Water_Withdrawal, na.rm = TRUE)) %>% 
  ungroup()

# Plot Figure 5: Total Water Withdrawal comparison
p_withdraw_total <- ggplot(withdraw_all_total, aes(x = Year, y = Total_Water_Withdrawal, linetype = Scenario)) +
  geom_line(size = 1, color = "black") +
  scale_linetype_manual(values = c("Reference" = "solid", "High ZCT" = "dashed", "Low ZCT" = "dotted"),
                        labels = scenario_labels) +
  scale_x_continuous(limits = c(min(withdraw_all_total$Year), 2050), breaks = seq(2025, 2050, 5)) +
  scale_y_continuous(labels = scientific_format()) +
  labs(title = "Total National Water Withdrawal (gal)",
       x = "Year",
       y = "Water Withdrawal (gal)",
       linetype = "Scenario") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16))
print(p_withdraw_total)

ggsave("Total_Water_Withdrawal_Comparison.png", p_withdraw_total, dpi = 300, width = 8, height = 4, bg = "white")

# Compute total water consumption by Year and Scenario
cons_all_total <- prod_cons %>% 
  group_by(Year, Scenario) %>% 
  summarise(Total_Water_Consumption = sum(Water_Consumption, na.rm = TRUE)) %>% 
  ungroup()

# Plot Figure 6: Total Water Consumption comparison
p_cons_total <- ggplot(cons_all_total, aes(x = Year, y = Total_Water_Consumption, linetype = Scenario)) +
  geom_line(size = 1, color = "black") +
  scale_linetype_manual(values = c("Reference" = "solid", "High ZCT" = "dashed", "Low ZCT" = "dotted"),
                        labels = scenario_labels) +
  scale_x_continuous(limits = c(min(cons_all_total$Year), 2050), breaks = seq(2025, 2050, 5)) +
  scale_y_continuous(labels = scientific_format()) +
  labs(title = "Total National Water Consumption (gal)",
       x = "Year",
       y = "Water Consumption (gal)",
       linetype = "Scenario") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16))
print(p_cons_total)

ggsave("Total_Water_Consumption_Comparison.png", p_cons_total, dpi = 300, width = 8, height = 4, bg = "white")
