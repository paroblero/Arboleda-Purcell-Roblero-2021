**********************************************************
*** Results replication code
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

// Fix your directory:
cd "C:\Users\pablo\Desktop\repository"

*** THE ORDER IN WHICH THIS CODE CONSTRUCTS THE GRAPHICS IS NOT NECESSARILY THE ORDER IN WHICH THEY ARE EXPOSED ON THE ARTICLE***

*------------------------------------------------------------------
* FIGURE 1: Characterization of food-emissions between world_regions
*------------------------------------------------------------------

*** Graph 1B: Emissions by world region and subsector

// Import dataset
use data_world_regions, clear

// Generate subsector variables
gen distribution=transport+ packaging+ retail + processing
gen cons_waste= consumption + end_of_life
// Label subsector variables
label var distribution Distribution
label var cons_waste "Consumption & Waste"

// Export data to excel; there, replicate the graph
collapse (sum) luluc (sum) production (sum) distribution (sum) cons_waste, by(area)

export excel using "Figure 1b", firstrow(variables) replace // Design bar graph in excel 

*** Graph 1A: Emissions share by world_region
gen food_emissions= luluc + production + distribution + cons_waste
keep area food_emissions
egen total=total(food_emissions)
gen share=food_emissions*100/total

export excel using "Figure 1a", firstrow(variables) replace // Design pie graph in excel 


*---------------------------------------------------------------------------
* FIGURE 3: Trends in food-related emissions in South America, by subsector 
*---------------------------------------------------------------------------
// Figure 2c: Trends by country and sector
// Import dataset
use data_sample, clear

// Generate and label subsector variables
gen distribution=transport+ packaging+ retail + processing
gen cons_waste= consumption + end_of_life
gen food_emissions=luluc+ production+ distribution+ cons_waste
gen non_luluc= food_emissions-luluc

label var food_emissions Overall
label var non_luluc "Non-LULUC"
label var distribution Distribution
label var cons_waste "Consumption & Waste"

// Create the graph
preserve
recode country 2=1 7=2 6=4 1=7 3=5 5=6 8=3 4=8 9=9
label drop country
label define country 1 "Bolivia" 2 "Paraguay" 3 "Peru" 4 "Ecuador" 5 "Brazil" 6 "Colombia" 7 "Argentina" 8 "Chile" 9 "Uruguay" 
label values country country

// KtCO2eq to MtCO2eq
foreach var in luluc production distribution cons_waste {
	replace `var' = `var' / 1000
}

twoway (line luluc year, lwidth(medthick)) ///
		(line production year, lwidth(medthick) lpattern(longdash)) ///
		(line distribution year, ///
			lwidth(medthick) lpattern(dash) yaxis(2)) ///
		(line cons_waste year, ///
			lwidth(medthick) lpattern(shortdash) yaxis(2)), ///
		by(country, yrescale note("", size(cero)) ///
			legend(position(6))) ///
			subtitle(, size(medlarge) nobox) ///
	ylabel(, labsize(small) angle(forty_five) format(%15.0g)) ///
	ylabel(, labsize(small) angle(forty_five) format(%15.0g) axis(2)) ///
	xlabel(1990(6)2015, labsize(small) angle(horizontal)) ///
	xtitle(, size(zero)) ///
	legend(rows(1) region(lcolor(none)) rowgap(minuscule) size(small)) ///
	scheme(s1color)
	
graph export "Figure 3.jpg", as(jpg) name("Graph") replace
restore

*---------------------------------------------------------------------------
* FIGURE 2: Trends in food-related emissions in South America (aggregate) 
*---------------------------------------------------------------------------

// Figure 2a: Trends by sector
preserve 
collapse (sum) food_emissions (sum) non_luluc (sum) luluc (sum) production (sum) distribution (sum) cons_waste, by(year)

label var food_emissions Overall
label var luluc "LULUC"
label var non_luluc "Non-LULUC"

twoway (line food_emissions year, lcolor(red) lwidth(medthick)) ///
		(line luluc year, lcolor(green) lwidth(medthick) lpattern(dash)) ///
		(line non_luluc year, lcolor(orange) lwidth(medthick) lpattern(dash_dot_dot)), ///
		legend(position(12) rows(1) region(lcolor(none))) ///
		ylabel(, angle(horizontal) format(%15.0g)) ///
		xtitle(, size(zero)) ///
		scheme(s1color)
		
graph export "Figure 2a.jpg", as(jpg) name("Graph") quality(100) replace
restore 

// Figure 2b: Changes by subsector

// Export data to excel; there, replicate the graph:
preserve
collapse (sum) luluc (sum) production (sum) distribution (sum) cons_waste, by(year)
keep if year==1990 | year==2015

xpose, var clear
order _varname v1 v2
rename v1 emissions_1990
rename v2 emissions_2015
rename _varname subsector
drop in 1

gen percentual_change=(emissions_2015-emissions_1990)*100/emissions_1990

export excel using "Figure 2b", firstrow(varlabels) replace
restore

*--------------------------------------------------------------------
* FIGURE 4: Country-year correlations between FDI and FCH variables 
*--------------------------------------------------------------------
*** Generate Real FDI
// It is necessary to change the base year of the GDP deflator to 2015; 1990 brings trouble:
rename gdp_deflator gdp_deflator_1990

sort country year
egen base_year=mean(gdp_deflator_1990) if year==2015
forval i=1/9 {
		replace base_year=gdp_deflator_1990[26*`i'] if country==`i'
}
sort country year
list country year gdp_deflator_1990 base_year

gen gdp_deflator=gdp_deflator_1990/base_year

sort country year
list country year gdp_deflator_1990 gdp_deflator

// Generate fdi_real with base year 2015
gen fdi_real= fdi_nominal/gdp_deflator

label var fdi_real "FDI"

// Scale to billion (thousand millions) dollars
replace fdi_nominal=fdi_real/1000000000
replace fdi_real=fdi_real/1000000000

*** Generate Real GDP
gen gdp_real=(gdp_nominal/gdp_deflator)/1000000000 // in billion dollars
label var gdp_real "Real GDP"

*** Generate FDI as a percentage of GDP
gen fdi_gdp= fdi_real/gdp_real*100
label var fdi_gdp "FDI/GDP"

*** Generate Real Minimum Wages

// Convert nominal wages to US$ with exchange rates
sort country year
list country year exchange_rate minw_natcurr
*The value of exchange_rate indicates how many local currency units you can buy with 1 dollar, so:
gen minwages_nominal=minw_natcurr/exchange_rate

// Deflate: 
// It is necessary to change CPI index base year to 2015; 1990 brings trouble:

rename cpi cpi_1990

sort country year
drop base_year
egen base_year=mean(cpi_1990) if year==2015
forval i=1/9 {
		replace base_year=cpi_1990[26*`i'] if country==`i'
}
sort country year
list country year cpi_1990 base_year

gen cpi=cpi_1990/base_year

sort country year
list country year cpi_1990 cpi

// Generate and label minwages_real:
gen minwages_real= minwages_nominal/cpi
label var minwages_real "Real Minimum Wages"

list country year cpi minwages_real

*** Label other variables
label var economic_freedom "Economic Freedom"
label var energy_per_capita "Energy per capita"
label var lpi "Logistics Performance"

// Generate Figure 4
foreach var in minwages_real economic_freedom energy_per_capita lpi {
	corr fdi_gdp `var'
	local corr: di %5.2f r(rho)
	
	twoway (scatter fdi_gdp `var', mcolor(black)) ///
	(lfit fdi_gdp `var', lcolor(red) lwidth(thick)), /// 
	title("Correlation = `corr'", position(6) ///
		size(large)  margin(medsmall) color(black)) ///
	ytitle("FDI/GDP", size(medlarge) margin(medsmall)) ///
	ylabel(none) ylabel(, labsize(small)) ///
	xtitle(,  size(large)  margin(medsmall)) ///
	xscale(alt) ///
	xlabel(, labsize(medium)) ///
	legend(off) scheme(s1mono) name(graph_`var', replace)
}

graph combine graph_minwages_real graph_economic_freedom graph_energy_per_capita graph_lpi, scheme(s1color)

graph export "Figure 4.jpg", as(jpg) name("Graph") quality(100) replace


*--------------------------------------------------------------------
* FIGURE 5: Relation between FDI and Main Emissions
*--------------------------------------------------------------------
// Generate and label Main Emissions
gen main_emissions= non_luluc

replace main_emissions = food_emissions if country_name== "Bolivia" | country_name=="Paraguay"

label var main_emissions "Main Emissions"

// Generate Figure 5

preserve
foreach lname in Brazil Colombia Paraguay Bolivia Peru Ecuador Uruguay Chile Argentina {
	
corr main_emissions fdi_gdp if country_name == "`lname'"
local corr: di %5.3g r(rho)
	
twoway (line fdi_gdp year) ///
	(line main_emissions year, lpattern(dash) yaxis(2)) /// 
	if country_name == "`lname'", ///
	title("`lname'") ///
	subtitle("Correlation = `corr'", size(medlarge) color(black)) ///
	ytitle("FDI/GDP", margin(medsmall)) ///
	ylabel(none) ylabel(, labsize(vsmall)) ///
	xtitle(, size(zero)) /// 
	xlabel(, labsize(small)) ///
	legend(region(lcolor(none)) size(small)) ///
	ytitle("Main Emissions", margin(medsmall) axis(2)) ///
	ylabel(none, labsize(small) axis(2)) ///
		scheme(s1color) name(`lname', replace)
}

grc1leg Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia , legendfrom(Chile) scheme(s1color)
graph export "Figure 5.jpg", as(jpg) name("Graph") quality(100) replace
restore


//Changes in correlations when analyzing isolated periods: 
corr main_emissions fdi_gdp if country_name == "Paraguay" & year >= 2003
corr main_emissions fdi_gdp if (country_name == "Argentina") & (year >= 2000 | year <= 1998)
//corr main_emissions fdi_gdp if country_name == "Argentina" & year >= 2001
corr main_emissions fdi_gdp if country_name == "Ecuador" & year <= 2005
corr main_emissions fdi_gdp if country_name == "Bolivia" & year >= 2005


*---------------------------------------------------------------------------
* TABLE 1: Group patterns in the relation between FDI, Emissions, Minimum
*		   Wages, Economic Freedom, Logistics Performance and Fuel Exports
*---------------------------------------------------------------------------

***The table will be exported to excel and there you must edit it


*** Column 1: FDI-Emissions correlation

// Sort countrys by FDI-Emissions correlation
recode country (1=7 "Argentina") (2=9 "Bolivia") (3=4 "Brazil") (4=1 "Chile") (5=3 "Colombia") (6=8 "Ecuador") (7=6 "Paraguay") (8=5 "Peru") (9=2 "Uruguay"), gen(country_table1)

// Generate matrix
matrix FDI_EMISSIONS_CORR = J(9, 1, .)

matrix rownames FDI_EMISSIONS_CORR= Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia
matrix colnames FDI_EMISSIONS_CORR=  "FDI-Emissions Correlation"

matrix list FDI_EMISSIONS_CORR

// Obtain data and fill matrix:
forval i=1/9 {
	corr main_emissions fdi_gdp if country_table1 == `i'
	local corr: di %5.2g r(rho)
	matrix FDI_EMISSIONS_CORR[`i', 1]=`corr'
}
// Export column
putexcel set "Table 1", replace
putexcel A1=matrix(FDI_EMISSIONS_CORR), names


*** Column 2: FDI as proportion of GDP (%)

// Obtain data:
tabstat fdi_gdp, by(country_table1) stat(mean) format (%9.1g) nototal save

// Generate matrix
matrix stats= r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat8) \ r(Stat9)
matrix rownames stats= Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia
matrix colnames stats= "FDI/GDP (average)"

matrix list stats

// Export column
putexcel set "Table 1", modify
putexcel C1=matrix(stats), names


*** Column 3: Fuel exports

// Obtain data:
sort country year
list country year fuel_exports if country_name=="Paraguay"
// Data on Fuel Exports in Paraguay must be considered carefully. They do not strictly reflect "fuel" exports. Before 2000, the share of fuel exports was 0.15% or less. The increases after that period are explained by the incorporation of electric current to the measurement methodology. Paraguay is currently the largest exporter of electrical energy (hydroelectric production): it consumes 15 billion kWh annually, out of a total annual production of 63 billion kWh. The rest is exported to Argentina, Brazil, and Uruguay.

tabstat fuel_exports, by(country_table1) stat(mean) format (%9.3g) nototal save

// Generate matrix
matrix stats= r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat8) \ r(Stat9)
matrix rownames stats= Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia
matrix colnames stats= "Fuel Exports (average)"

matrix list stats

// Export column
putexcel set "Table 1", modify
putexcel E1=matrix(stats), names



*** Column 4: Real Minimum Wages

// Obtain data:
tabstat minwages_real if year>=2001 & year<=2013, by(country_table1) stat(mean) format (%9.1g) nototal save

// Fill matrix:
matrix stats= r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat8) \ r(Stat9)
matrix rownames stats= Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia
matrix colnames stats= "Minimum Wage (average)"

matrix list stats

// Export column:
putexcel set "Table 1", modify
putexcel G1=matrix(stats), names


*** Column 5: Economic Freedom

// Obtain data:
tabstat economic_freedom if year>=2001 & year<=2013, by(country_table1) stat(mean) format (%9.1g) nototal save

// Fill matrix:
matrix stats= r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat8) \ r(Stat9)
matrix rownames stats= Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia
matrix colnames stats= "Economic Freedom (average)"

matrix list stats

// Export column:
putexcel set "Table 1", modify
putexcel I1=matrix(stats), names


*** Column 6: Logistics Performance

// Obtain data:
tabstat lpi if year>=2001 & year<=2013, by(country_table1) stat(mean) format (%9.1g) nototal save

// Fill matrix:
matrix stats= r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat8) \ r(Stat9)
matrix rownames stats= Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia
matrix colnames stats= "Logistics Performance (average)"

matrix list stats

// Export column
putexcel set "Table 1", modify
putexcel K1=matrix(stats), names


*** Column 7:  Changes in distribution-emissions

// Obtain data
preserve
keep if year==1990 | year==2015
keep country_table1 year distribution
sort country_table1 year

reshape wide distribution, i(country_table1) j(year)

bysort country: gen distribution_changes=(distribution2015-distribution1990)*100/distribution1990

tabstat distribution_changes, by(country_table1) stat(mean) format (%9.1g) nototal save

// Fill Matrix
matrix stats= r(Stat1) \ r(Stat2) \ r(Stat3) \ r(Stat4) \ r(Stat5) \ r(Stat6) \ r(Stat7) \ r(Stat8) \ r(Stat9)
matrix rownames stats= Chile Uruguay Colombia Brazil Peru Paraguay Argentina Ecuador  Bolivia
matrix colnames stats= "Changes in Distribution"

matrix list stats

// Export Column
putexcel set "Table 1", modify
putexcel M1=matrix(stats), names
restore