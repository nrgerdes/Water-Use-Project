# R Script: Carbon Capture and Storage (CCS) deployment

#––– Libraries
library(readxl)
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(stringr)

#––– Colors
generation_colors <- c(
  "Coal"         = "#1b9e77",
  "Natural Gas"  = "#d95f02",
  "Nuclear"      = "#7570b3",
  "Petroleum"    = "#8B0000"
)

# 1) Read in Reference‐case generation
prod_ref <- read_excel("Processed_Ref_AEOEnergyProduction_National.xlsx") %>%
  pivot_longer(-Generation_Type, names_to="Year", values_to="Generation_MWh") %>%
  mutate(Year = as.numeric(Year))

years <- sort(unique(prod_ref$Year))

# 2) Read in static fleet shares
fleet_static <- read_excel("Fleet_Share_National.xlsx") %>%
  pivot_longer(-Generation_Type, names_to="Cooling_Type", values_to="Fleet_Share") %>%
  mutate(Fleet_Share = Fleet_Share / 100)

# 3) Build time‐series of fleet shares for both scenarios

# 3a) Reference: static for all years
fleet_ref <- fleet_static %>% crossing(Year = years) %>%
  mutate(Scenario = "Reference_no_CCS")

# 3b) Reference + CCS retrofit:
#    – original CCS share per Gen type
orig_ccs <- fleet_static %>%
  filter(str_detect(Cooling_Type, "Wet Tower")) %>%
  select(Generation_Type, original_ccs = Fleet_Share)

fleet_ccs <- fleet_static %>%
  crossing(Year = years) %>%
  left_join(orig_ccs, by="Generation_Type") %>%
  group_by(Generation_Type, Cooling_Type) %>%
  mutate(
    # Linear “shift” from 0 → (1–orig_ccs) over 2030–2040 for non-nuclear
    shift = case_when(
      Year < 2030 ~ 0,
      Year > 2040 ~ 1 - original_ccs,
      TRUE        ~ (Year - 2030) / (2040 - 2030) * (1 - original_ccs)
    ),
    Fleet_Share = case_when(
      Generation_Type == "Nuclear" ~ Fleet_Share,  # No CCS for Nuclear
      str_detect(Cooling_Type, "Wet Tower") ~ original_ccs + shift,
      TRUE  ~ Fleet_Share * (1 - shift) / (1 - original_ccs)
    )
  ) %>%
  ungroup() %>%
  select(-original_ccs, -shift) %>%
  mutate(Scenario = "Reference_with_CCS")

# combined fleet
fleet_time <- bind_rows(fleet_ref, fleet_ccs)

# 4) Read water‐factors
water_cons <- read_excel("Water_Consumption_Factors.xlsx") %>%
  pivot_longer(-Generation_Type, names_to="Cooling_Type", values_to="Water_Consumption_Factor")

water_with <- read_excel("Water_Withdrawal_Factors.xlsx") %>%
  pivot_longer(-Generation_Type, names_to="Cooling_Type", values_to="Water_Withdrawal_Factor")

# 5) Compute total water use for both scenarios

# helper to do one metric
compute_metric <- function(prod_df, fleet_df, water_df, value_name) {
  prod_df %>%
    left_join(fleet_df, by=c("Generation_Type", "Year", "Scenario")) %>%
    left_join(water_df, by=c("Generation_Type", "Cooling_Type")) %>%
    mutate(Use = Generation_MWh * Fleet_Share * get(value_name)) %>%
    group_by(Scenario, Year, Generation_Type) %>%
    summarise(Total = sum(Use, na.rm=TRUE), .groups="drop") %>%
    filter(Generation_Type != "Renewables")
}

# prep prod with scenarios
prod_scen <- prod_ref %>%
  mutate(Scenario = "Reference_no_CCS") %>%
  bind_rows(prod_ref %>% mutate(Scenario = "Reference_with_CCS"))

# consumption & withdrawal
cons <- compute_metric(prod_scen, fleet_time, water_cons, "Water_Consumption_Factor") %>%
  rename(Total_Water_Consumption = Total)

withd <- compute_metric(prod_scen, fleet_time, water_with, "Water_Withdrawal_Factor") %>%
  rename(Total_Water_Withdrawal = Total)

# 6) Plotting
p_cons <- ggplot(cons, aes(Year, Total_Water_Consumption, color=Generation_Type)) +
  geom_line(size=1) +
  facet_wrap(~Scenario, nrow=1, labeller=labeller(Scenario = c("Reference_no_CCS" = "Reference w/o CCS", "Reference_with_CCS" = "Reference w/ CCS"))) +
  scale_x_continuous(limits = c(2025, 2050), breaks = seq(2025, 2050, 5)) + # Adjusted x-axis
  scale_y_continuous(labels=scientific_format()) +
  scale_color_manual(values=generation_colors) +
  labs(
    title = "National Water Consumption (gal)",
    x = "Year", y = "Water Consumption (gal)",
    color = "Generation Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust=0.5),
    strip.text  = element_text(hjust=0.5)
  )

p_withd <- ggplot(withd, aes(Year, Total_Water_Withdrawal, color=Generation_Type)) +
  geom_line(size=1) +
  facet_wrap(~Scenario, nrow=1, labeller=labeller(Scenario = c("Reference_no_CCS" = "Reference w/o CCS", "Reference_with_CCS" = "Reference w/ CCS"))) +
  scale_x_continuous(limits = c(2025, 2050), breaks = seq(2025, 2050, 5)) + # Adjusted x-axis
  scale_y_continuous(labels=scientific_format()) +
  scale_color_manual(values=generation_colors) +
  labs(
    title = "National Water Withdrawal (gal)",
    x = "Year", y = "Water Withdrawal (gal)",
    color = "Generation Type"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust=0.5),
    strip.text  = element_text(hjust=0.5)
  )

# draw
print(p_cons)
print(p_withd)

#7) (Optional) Save to PNG
ggsave("CCS_Comparison_Consumption.png", p_cons, width=10, height=4, dpi=300, bg="white")
ggsave("CCS_Comparison_Withdrawal.png", p_withd, width=10, height=4, dpi=300, bg="white")

