**********************************************************
*** Database construction
*** Martin Arboleda, Thomas F. Purcell and Pablo Roblero
*** December, 2021
*** Comments to: paroblero@uc.cl
**********************************************************


************************
* General adjustments
************************
clear all
version 16	// STATA version used
set more off // allow console to flow freely

// Fix your directory (you must do the same
// in lines 91, 93, 133, 150, 403 and 479):
cd "C:\Users\pablo\Desktop\repository\Data Sources" 

// Also, for the code to run, you will have to install
// the webscraping package 'readhtml'. If you already have the package 
// installed, prepend an asterisk at the beginning of line 23
*net install readhtml, from(https://ssc.wisc.edu/sscc/stata/) 
	
**************************************************************************
* (1) Data on food-related emissions by world_region: 'data_world_regions'
**************************************************************************
// Import raw database
import excel "EDGAR-FOOD_data.xlsx", sheet("Table S7-FOOD emi by sector ") cellrange(A3:AF4956) firstrow clear

// Modify NULL to . for STATA to recognize missing values
forval i=1990/2015 {
	replace Y_`i'="." if Y_`i'=="NULL"
	destring Y_`i', replace
}

// Group EDGAR-FOOD regions into world_regions
rename C_group_IM24_sh region
tab region
drop if region == "27:_Int. Shipping"
drop if region == "28:_Int. Aviation"

gen area = "Europe" if region=="12:_Central Europe"
replace area = "Europe" if region=="11:_OECD_Europe"
replace area = "Europe" if region=="14:_Ukraine +"

replace area= "Asia" if region=="15:_Asia-Stan"
replace area= "Asia" if region=="20:_China +"
replace area= "Asia" if region=="18:_India +"
replace area= "Asia" if region=="23:_Japan"
replace area= "Asia" if region=="19:_Korea"
replace area= "Asia" if region=="22:_Indonesia +"
replace area= "Asia" if region=="17:_Middle_East"
replace area= "Asia" if region=="16:_Russia +"
replace area= "Asia" if region=="21:_Southeastern Asia"
replace area= "Asia" if region=="13:_Turkey"

replace area= "North America" if region=="01:_Canada"
replace area= "North America" if region=="02:_USA"

replace area= "Central & South America" if region=="05:_Brazil"
replace area= "Central & South America" if region=="06:_Rest South America"
replace area= "Central & South America" if region=="03:_Mexico"
replace area= "Central & South America" if region=="04:_Rest Central America"

replace area= "Africa" if region=="09:_Eastern_Africa"
replace area= "Africa" if region=="07:_Northern_Africa"
replace area= "Africa" if region=="10:_Southern_Africa"
replace area= "Africa" if region=="08:_Western_Africa"

replace area= "Oceania" if region=="24:_Oceania"

// Generate numeric code
gen area_code = 1 if area == "Europe"
replace area_code = 2 if area == "North America"
replace area_code = 3 if area == "Asia"
replace area_code = 4 if area == "Central & South America"
replace area_code = 5 if area == "Africa"
replace area_code = 6 if area == "Oceania"


label define area_code 1 "Europe" 2 "North America" 3 "Asia" 4 "Central & South America" 5 "Africa"  6 "Oceania"
label values area_code area_code

// Keep variables for our purpose
keep area_code Name FOOD_system_stage Substance Y_*
rename (area_code Name) (area country)
order area country FOOD_system_stage Substance Y_*
sort area country FOOD_system_stage Substance Y_*

cd "C:\Users\pablo\Desktop\repository"
save data_sample, replace // save data at this point to finish 'data_sample' later; now, we continue with what remains to finish 'data_world_regions'
cd "C:\Users\pablo\Desktop\repository\Data Sources"

// Aggregate the data at the level of area-food_system_stage to reshape it to long format (each unit will count the amount of emissions corresponding to a stage of the food industry in a given year)
collapse (sum) Y_*, by(area FOOD_system_stage)

egen area_stage = concat(area FOOD_system_stage)

reshape long Y_, i(area_stage) j(year)
drop area_stage

// Reshape to wide format: emissions from each system stage will be a variable apart 
egen area_year = concat(area year)
destring area_year, replace
drop area year

replace FOOD_system_stage= "LULUC" if FOOD_system_stage=="LULUC (Production)"

reshape wide Y_, i(area_year) j(FOOD_system_stage) string
tostring area_year, replace
gen year= real(substr(area_year,2,4))
gen area= real(substr(area_year,1,1))

label define area 1 "Europe" 2 "North America" 3 "Asia" 4 "Central & South America" 5 "Africa"  6 "Oceania"
label values area area


rename (Y_LULUC Y_Production Y_Processing Y_Packaging Y_Transport Y_Retail Y_Consumption Y_End_of_Life) (luluc production processing packaging transport retail consumption end_of_life)

label var luluc LULUC
label var production Production
label var processing Processing
label var packaging Packaging
label var transport Transport
label var retail Retail
label var consumption Consumption
label var end_of_life End_of_Life

keep area year luluc production processing packaging transport retail consumption end_of_life
order area year luluc production processing packaging transport retail consumption end_of_life

cd "C:\Users\pablo\Desktop\repository"
save data_world_regions, replace
export excel using "data_world_regions", firstrow(variables) replace


*****************************************************************
* (2) Data on 9 selected South American countries: 'data_sample'
*****************************************************************

*-------------------------------------
* FOOD-EMISSION BY COUNTRY AND STAGE
*-------------------------------------

*** EDGAR-FOOD DATA: food-emissions in differents stages of the food industry, by country and year
// Bring the data that we had saved in line 87
use data_sample, clear
// Fix directory to the folder containing raw datasets
cd "C:\Users\pablo\Desktop\repository\Data Sources"

// Aggregate emissions-year at te country-food-system stage level
collapse (sum) Y_*, by(country FOOD_system_stage)

// Unify the different names of the countries
replace country="Bolivia" if country=="Bolivia (Plurinational State of)"

// Keep countries of our sample
keep if country== "Argentina" | country== "Bolivia" | country== "Brazil" | country== "Chile" | country== "Colombia" | country== "Ecuador" | country== "Paraguay" | country== "Peru" | country== "Uruguay"

// Reshape to long format
egen country_stage = concat(country FOOD_system_stage)
reshape long Y_, i(country_stage) j(year)
drop country_stage

// Generate numeric code for countries
rename country country_name
gen country=1 if country_name=="Argentina"
replace country=2 if country_name=="Bolivia"
replace country=3 if country_name=="Brazil"
replace country=4 if country_name=="Chile"
replace country=5 if country_name=="Colombia"
replace country=6 if country_name=="Ecuador"
replace country=7 if country_name=="Paraguay"
replace country=8 if country_name=="Peru"
replace country=9 if country_name=="Uruguay"

// Reshape to wide format: emissions from each system stage will be a variable apart 
egen country_year = concat(country year)
destring country_year, replace
drop country year

replace FOOD_system_stage= "LULUC" if FOOD_system_stage=="LULUC (Production)"

reshape wide Y_, i(country_year) j(FOOD_system_stage) string

tostring country_year, replace
gen year= real(substr(country_year,2,4))
gen country= real(substr(country_year,1,1))

label define country 1 "Argentina" 2 "Bolivia" 3 "Brazil" 4 "Chile" 5 "Colombia" 6 "Ecuador" 7 "Paraguay" 8 "Peru" 9 "Uruguay"
label values country country

rename (Y_LULUC Y_Production Y_Processing Y_Packaging Y_Transport Y_Retail Y_Consumption Y_End_of_Life) (luluc production processing packaging transport retail consumption end_of_life)

drop country_year
egen country_year = concat(country_name year)

// Label food-emission variables
label var luluc LULUC
label var production Production
label var processing Processing
label var packaging Packaging
label var transport Transport
label var retail Retail
label var consumption Consumption
label var end_of_life End_of_Life

order country country_name year country_year luluc production processing packaging transport retail consumption end_of_life

*-----------------
* ECONOMIC DATA
*-----------------

*** fdi_nominal exchange_rate gdp_nominal gdp_deflator_changes cpi_changes
preserve
// This loop calls and processes the raw data of the different variables one by one from the Data Source folder. It prepares them to be incorporated into our main database
foreach dataset in fdi_nominal exchange_rate gdp_nominal gdp_deflator_changes cpi_changes {
import delimited "`dataset'.csv", varnames(4) encoding(UTF-8) clear

keep countryname v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60

rename countryname country

keep if country== "Argentina" | country== "Bolivia" | country== "Brazil" | country== "Chile" | country== "Colombia" | country== "Ecuador" | country== "Paraguay" | country== "Peru" | country== "Uruguay"

rename (v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60) (`dataset'1990 `dataset'1991 `dataset'1992 `dataset'1993 `dataset'1994 `dataset'1995 `dataset'1996 `dataset'1997 `dataset'1998 `dataset'1999 `dataset'2000 `dataset'2001 `dataset'2002 `dataset'2003 `dataset'2004 `dataset'2005 `dataset'2006 `dataset'2007 `dataset'2008 `dataset'2009 `dataset'2010 `dataset'2011 `dataset'2012 `dataset'2013 `dataset'2014 `dataset'2015)

reshape long `dataset', i(country) j(year)
egen country_year=concat(country year)
keep country_year `dataset'
save `dataset', replace
}
restore

// This loop incorporates one by one the data of the different variables to our main database.
foreach dataset in fdi_nominal exchange_rate gdp_nominal gdp_deflator_changes cpi_changes {
	merge 1:1 country_year using `dataset'
	drop _merge
}

// We use gdp_deflator_changes and cpi_changes to create indices of gdp_deflator and cpi (this will be necessary to transform the economic data from nominal to real)

/// Generate gdp_deflator
replace gdp_deflator_changes=0 if year== 1990
gen gdp_deflator=1 if year== 1990
gen gdp_deflator_lagged = gdp_deflator[_n-1] 

forval i=1991/2015 {
	
replace gdp_deflator = gdp_deflator_lagged + (gdp_deflator_changes*gdp_deflator_lagged/100) if year==`i'

drop gdp_deflator_lagged
gen gdp_deflator_lagged = gdp_deflator[_n-1]
}

drop gdp_deflator_lagged

/// Generate cpi
replace cpi_changes=0 if year== 1990
gen cpi=1 if year== 1990
gen cpi_lagged = cpi[_n-1] 


forval i=1991/2015 {
	
replace cpi = cpi_lagged + (cpi_changes*cpi_lagged/100) if year==`i'

drop cpi_lagged
gen cpi_lagged = cpi[_n-1]
}
drop cpi_lagged

// CPI Argentina and Nominal minimum wages: there is no Argentine CPI data in the World Bank database, we use data from FRED

*** CPI Argentina
preserve
import excel "cpi_arg.xls", sheet("FRED Graph") cellrange(A11:B37) firstrow clear

rename DDOE02ARA086NWDB cpi_index
gen year= year(observation_date)

replace cpi_index=cpi_index/100
gen cpi_base=.158358
gen cpi_arg=cpi_index/cpi_base

gen country="Argentina"
egen country_year=concat(country year)

keep country_year cpi_arg
order country_year cpi_arg
save cpi_arg, replace

restore

merge 1:1 country_year using "cpi_arg.dta"
drop  _merge

replace cpi=cpi_arg if country_name=="Argentina"
drop cpi_arg

*** Nominal minimum wages
// The nominal minimum wages data is not stored in a database, but in tables of the page countryeconomy.com; we use webscraping to extract them

*** argentina:
preserve
readhtmltable https://countryeconomy.com/national-minimum-wage/argentina, varnames
keep Date Nat__Curr___NMW

replace Nat__Curr___NMW = subinstr(Nat__Curr___NMW, ",", "",.) 
destring Nat__Curr___NMW, replace

split Date, parse(" ")

rename (Nat__Curr___NMW Date2) (minw_natcurr year)

collapse (mean) minw_natcurr, by(year)

destring year, replace
keep if year >= 1995 & year <= 2015

gen country="Argentina"
egen country_year=concat(country year)
keep country_year minw_natcurr

save minw_natcurr_argentina, replace

*** other countries:
foreach country in Bolivia Brazil Chile Colombia Ecuador Paraguay Peru Uruguay {
	readhtmltable https://countryeconomy.com/national-minimum-wage/`country', varnames
	keep Date Nat__Curr___NMW
	replace Nat__Curr___NMW = subinstr(Nat__Curr___NMW, ",", "",.) 
	destring Nat__Curr___NMW, replace
	
	rename (Nat__Curr___NMW Date) (minw_natcurr year)
	
	destring year, replace
	keep if year >= 1995 & year <= 2015
	gen country="`country'"
	egen country_year=concat(country year)
	keep country_year minw_natcurr
	
	save minw_natcurr_`country', replace
}

foreach country in Argentina Bolivia Brazil Chile Colombia Ecuador Paraguay Peru {
	append using minw_natcurr_`country'
}

sort country_year
save minw_natcurr_all, replace
restore

merge 1:1 country_year using minw_natcurr_all
drop _merge

*---------------------------------------------
* ECONOMIC FREEDOM INDEX (HERITAGE FUNDATION)
*---------------------------------------------
preserve
import delimited "economic_freedom.csv", varnames(1) encoding(UTF-8) clear

rename (name indexyear overallscore) (country year economic_freedom)

keep if year <= 2015

foreach var in judicialeffectiveness fiscalhealth laborfreedom {
	replace `var'="." if `var'== "N/A"
	destring `var', replace
}

sort country year
egen country_year= concat(country year)
drop country year
save economic_freedom, replace

restore

merge 1:1 country_year using "economic_freedom.dta"
drop _merge


*----------------
* INFRASTRUCTURE 
*----------------

*** Energy per capita
preserve
import excel "owid-energy-data.xlsx", firstrow clear
keep country year energy_per_capita
keep if year >= 1990 & year <= 2015
keep if country== "Argentina" | country== "Bolivia" | country== "Brazil" | country== "Chile" | country== "Colombia" | country== "Ecuador" | country== "Paraguay" | country== "Peru" | country== "Uruguay"
egen country_year=concat (country year)
keep country_year energy_per_capita

save energy_per_capita, replace
restore

merge 1:1 country_year using "energy_per_capita.dta"
drop _merge

*** Fuel Exports
cd "C:\Users\pablo\Desktop\repository\Data Sources"
preserve
import delimited "fuel_exports.csv", varnames(4) encoding(UTF-8) clear

keep countryname v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60

rename countryname country

keep if country== "Argentina" | country== "Bolivia" | country== "Brazil" | country== "Chile" | country== "Colombia" | country== "Ecuador" | country== "Paraguay" | country== "Peru" | country== "Uruguay"

rename (v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60) (fuel_exports1990 fuel_exports1991 fuel_exports1992 fuel_exports1993 fuel_exports1994 fuel_exports1995 fuel_exports1996 fuel_exports1997 fuel_exports1998 fuel_exports1999 fuel_exports2000 fuel_exports2001 fuel_exports2002 fuel_exports2003 fuel_exports2004 fuel_exports2005 fuel_exports2006 fuel_exports2007 fuel_exports2008 fuel_exports2009 fuel_exports2010 fuel_exports2011 fuel_exports2012 fuel_exports2013 fuel_exports2014 fuel_exports2015)

reshape long fuel_exports, i(country) j(year)

keep if year <= 2015

egen country_year=concat(country year)
keep country_year fuel_exports
save fuel_exports, replace
restore 

merge 1:1 country_year using "fuel_exports.dta"
drop _merge


*** Logistics Performance Index
preserve
import delimited "logistics_performance_index.csv", varnames(4) encoding(UTF-8) clear

keep countryname v52 v53 v54 v55 v56 v57 v58 v59 v60 v61 v62 v63

keep if country== "Argentina" | country== "Bolivia" | country== "Brazil" | country== "Chile" | country== "Colombia" | country== "Ecuador" | country== "Paraguay" | country== "Peru" | country== "Uruguay"

rename (countryname v52 v53 v54 v55 v56 v57 v58 v59 v60 v61 v62 v63) (country lpi2007 lpi2008 lpi2009 lpi2010 lpi2011 lpi2012 lpi2013 lpi2014 lpi2015 lpi2016 lpi2017 lpi2018)

reshape long lpi, i(country) j(year)

*twoway (connected lpi year), xlabel(#12, angle(vertical) grid) by(country) scheme(s1mono)

keep if year <= 2015

egen country_year=concat(country year)
keep country_year lpi
save logistics_performance_index, replace
restore 

merge 1:1 country_year using "logistics_performance_index.dta"
drop _merge

*Telecommunications (World Bank Data)
preserve
foreach dataset in fixed_telephone mobile_cellular internet_users internet_servers fixed_broadband {

import delimited "`dataset'.csv", varnames(4) encoding(UTF-8) clear

keep countryname v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60

rename countryname country

keep if country== "Argentina" | country== "Bolivia" | country== "Brazil" | country== "Chile" | country== "Colombia" | country== "Ecuador" | country== "Paraguay" | country== "Peru" | country== "Uruguay"

rename (v35 v36 v37 v38 v39 v40 v41 v42 v43 v44 v45 v46 v47 v48 v49 v50 v51 v52 v53 v54 v55 v56 v57 v58 v59 v60) (`dataset'1990 `dataset'1991 `dataset'1992 `dataset'1993 `dataset'1994 `dataset'1995 `dataset'1996 `dataset'1997 `dataset'1998 `dataset'1999 `dataset'2000 `dataset'2001 `dataset'2002 `dataset'2003 `dataset'2004 `dataset'2005 `dataset'2006 `dataset'2007 `dataset'2008 `dataset'2009 `dataset'2010 `dataset'2011 `dataset'2012 `dataset'2013 `dataset'2014 `dataset'2015)

reshape long `dataset', i(country) j(year)
egen country_year=concat(country year)
keep country_year `dataset'
save `dataset', replace
}
restore

foreach dataset in fixed_telephone mobile_cellular internet_users internet_servers fixed_broadband {
	merge 1:1 country_year using `dataset'
	drop _merge
}

// All data incorporated, we save the main database in stata and excel format
cd "C:\Users\pablo\Desktop\repository"
save data_sample, replace
export excel using "data_sample", firstrow(variables) replace