**Step 1:** <br />
Use power_plant_processing.R to turn data from Cooling_Boiler_Generator_Data_Summary_2022.xlsx monthly data to annual data. <br />
<br />
Note this data is for thermal power generation only (does not include wind, solar, hydro, or anything without a cooling system). <br />
<br />
**Step 2:** <br />
Use merge_split.R to add longitude and latitude data from Power_Plants.xlsx to the excel file created in Step 1. <br />
<br />
This script will break the annual power generation data into five spreadsheets—National, Region 1, Region 2, Region 3, and Region 4. <br />
<br />
**Step 3:** <br />
Use fleet_share.R to process excel files created in Step 2. <br />
<br />
This script will generate a fleet share figure for each excel file. You must manually update the code to read in the file you want, then update the title and export .png name
to reflect the file you are processing. <br />
<br />
Note the script adds generation (MWh) from renewables to the total generation. You must manually change this number; the number for national generation and regional generations
is included below that line of code for ease. <br />
<br />
Use this figure to create an excel table—an example for Region 4 is included as Fleet_Share_Region4.xlxs <br />
<br />
**Step 4:** <br />
Use the Electricity and renewable fuel tables (Table 54) provided by the EIA (https://www.eia.gov/outlooks/aeo/tables_ref.php) <br />
to create a processed dataset of regional electricity generation. <br />
<br />
An example for the Region 4 reference case can be found as Processed_Ref_AEOEnergyProduction_Region4.xlsx. <br />
<br />
**Step 5:** <br />
Use generation_water.R to estimate regional or national electricity generation, water consumption, and water withdrawal for generation types from 2022 to 2050. <br />
<br />
This script uses the dataset developed in Step 4, the fleet share, Water_Consumption_Factors.xlxs, and Water_Withdrawal_Factors.xlxs by relating the electricity generation
type to the fleet share precentage based on generation type and cooling technology, then applys water consumption and water withdrawal factors. <br />
<br />
The water withdrawal and consumption factors were taken from two literature papers: http://dx.doi.org/10.1021/acs.est.6b00008 and
http://dx.doi.org/10.1088/1748-9326/7/4/045802 <br />
<br />
This script also assumes all once-through cooling systems will be phased out by 2040 and replaced with wet cooling towers. <br />
<br />
**Step 5a:** <br />
Use generation_water_ref_alt_comparison_V2.R to estimate national electricity generation, water consumption, and withdrawal for generation types and totals from 2024 to 2050
for alternative Low- and High-ZCT cases compared against the reference case. <br />
<br />
This script uses Table 8 from https://www.eia.gov/outlooks/aeo/tables_side_xls.php. Similar to Step 4, this data needs to be processed. The processed datasets can be found
as HighZCT_AEOEnergyProduction_National.xlsx and LowZCT_AEOEnergyProduction_National.xlsx. <br />
<br />
This script is essentially the same as generation_water.R, but processes the datasets for the reference case and alternative cases at the same time to produce
comparison figures.<br />
<br />
**Step 5b:** <br />
Use water_dry_cooling_comparison.R to estimate national water consumption and withdrawal for generation types from 2022 to 2050 for the reference case if dry cooling
technology is deployed. <br />
<br />
This script assumes every year, starting in 2030, 10% of power plants are retrofitted with dry cooling technology, such that by 2040 all thermoelectric power plants
use dry cooling technology. I did this by incrementally adjusting the fleet shares over a 10 year period. <br />
<br />
**Step 5c:** <br />
Use water_CCS_comparison.R to estimate national water consumption and withdrawal for generation types from 2022 to 2050 for the reference case if CCS technology
is deployed. <br />
<br />
This script is much more nuanced and complex. It assumes every year, starting in 2030, 10% of petroleum, coal, and natural gas power plants are fitted with CCS
technology. This script references two new water factor datasets: Water_CCS_Withdrawal_Factors.xlsx and Water_CCS_Consumption_Factors.xlsx. It takes a weighted
average of the original water factors and these CCS factors to calculate water use. For example, in 2030 10% of power plants use the CCS factors and 90% use the
original factors, and so on until 100% of power plants use CCS factors. This script also adjust fleet shares such that 10% of fleet share for once-through cooling is
transfered to wet tower cooling every year for 10 years. This is because we assume if CCS technology is deployed, then policy dictates one-through cooling will be
completely phased out. Nuclear generation is a caveat for apply the CCS factors and adjusting the fleet shares—it remains the same as the reference case.
