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
This script uses the dataset developed in Step 4, the fleet share, Water_Consumption_Factors.xlxs, and Water_Withdrawal_Factors.xlxs by relating the electricity generation <br />
type to the fleet share precentage based on generation type and cooling technology, then applys water consumption and water withdrawal factors. <br />
<br />
The water withdrawal and consumption factors were taken from two literature papers: http://dx.doi.org/10.1021/acs.est.6b00008 and <br />
http://dx.doi.org/10.1088/1748-9326/7/4/045802 <br />
<br />
This script also assumes all once-through cooling systems will be phased out by 2040 and replaced with wet cooling towers. <br />
