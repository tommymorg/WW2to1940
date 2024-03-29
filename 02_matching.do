/*

match the processed NARA files into IPUMS as best we can

*/

clear all
set max_memory 128g

*sysdir set PLUS "V:\FHSS-JoePriceResearch\data\v_ssc"
ssc install reclink
ssc install chimchar
*mata: mata mlib index // these two comments are only necessary for servers without write access to Stata's program files.


// update this global to the directory you downloaded everything into!
global route "V:\FHSS-JoePriceResearch\papers\current\wwii_black_longevity\NARA_ww2_enlistment"


*******************************************************
*split up the processed NARA files and then link em up!
*******************************************************
// done
*split up the sets!!
use "$route/output/NARA_cleaned.dta", clear
tempfile NARA
save `NARA', replace // I tempfile this to make it slightly faster

levelsof place, local(places)
foreach place of local places {
	use if place=="`place'" using `NARA', clear
	
	save "$route/match_pieces/NARA_`place'.dta", replace
}
*/


*****************************************
*prepare the IPUMS files to be matched on
*****************************************
// done
*note: in order to replicate this code, download an IPUMS dataset for the full-count 1940 census that contains the following variables:
*	- stateicp
*	- countyicp 
*	- race
*	- marst
*	- birthyr
*	- sex
*	- namefrst (restricted)
*	- namelast (restricted)


/* this block creates an IPUMS full count dataset using the above variables based on data storage structures in the Record Linking Lab at BYU.
use "V:\FHSS-JoePriceResearch\data\census_data\ipums\ipums_1940\serialpernum1940_histid1940.dta", clear

foreach var in stateicp countyicp {
	merge m:1 serial1940 using "V:\FHSS-JoePriceResearch\data\census_data\ipums\ipums_1940\serial1940_`var'.dta", keep(1 3) nogen
}

foreach var in race marst birthyr sex {
	merge m:1 serial 1940 pernum1940 using "V:\FHSS-JoePriceResearch\data\census_data\ipums\ipums_1940\serialpernum1940_`var'.dta", keep(1 3) nogen
}

foreach var in namefrst namelast {
	merge m:1 histid1940 using "V:\FHSS-JoePriceResearch\data\census_data\ipums\ipums_1940\ancestry_restricted\serialpernum1940_`var'.dta", keep(1 3) nogen
}
*/

*now clean all the IPUMS stuff
recode marst (2=1) // this is mentioned in 01 to line them up
keep if birthyr<=1930 & birthyr>1897
drop if sex!=1 // the women's matches did extremely poorly in my initial tests

gen name = namelast + " " + namefrst
chimchar name namelast namefrst, numremove // this command removes special characters and spaces from text. it's installed via the SSC


*build a unique county identifier to split the dataset on
gen str2 state2 = string(stateicp,"%02.0f")
gen str4 county4 = string(countyicp,"%04.0f")

gen place = state2 + county4
replace place = "" if state2=="." | county4=="."

drop state2 county4 sex


*split up the sets!!
save "$route/output/ipums_matchable.dta", replace
tempfile ipums
save `ipums', replace

levelsof place, local(places)
foreach place of local places {
	use if place=="`place'" using `ipums', clear
	drop place
	
	save "$route/match_pieces/ipums_`place'.dta", replace
}
*/



*****************************
*actually link the stuff up!!
*****************************
// in progress
*get the levelsof for places from the big set
use place using "$route/output/ipums_matchable.dta", clear

levelsof place, local(places)
foreach place of local places {
	di "now linking `place' records!"
	
	use "$route/match_pieces/ipums_`place'.dta", clear
	
	rename birthyr byr
	gen id = _n // we do this to avoid string issues in reclink with the histids 
	
	reclink race marst byr name namefrst namelast using "$route/match_pieces/NARA_`place'.dta" , idm(id) idu(serial) gen(match_score) wmatch(3 3 2 10 7 8) wnomatch(7 4 3 4 5 4)
	
	save "$route/match_pieces/reclinked_`place'.dta", replace
}
*/







