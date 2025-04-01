**Step 1:** <br />
Use power_plant_processing.R to turn data from Cooling_Boiler_Generator_Data_Summary_2022.xlsx monthly data to annual data. <br />
Note this data is for thermal power generation only (does not include wind, solar, hydro, or anything without a cooling system). <br />

**Step 2:** <br />
Use merge_split.R to add longitude and latitude data from Power_Plants.xlsx to the excel file created in Step 1. <br />
This script will break the annual power generation data into five spreadsheets—National, Region 1, Region 2, Region 3, and Region 4. <br />

**Step 3:** <br />
Use fleet_share.R to process excel files created in Step 2. <br />
This script will generate a fleet share figure for each excel file. You must manually update the code to read in the file you want, then update the title and export .png name
to reflect the file you are processing. <br />
Note the script adds generation (MWh) from renewables to the total generation. You must manually change this number; the number for national generation and regional generations
is included below that line of code for ease. <br />
