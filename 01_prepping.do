/*

process completely from raw the Army Serial Number Electronic
File from https://catalog.archives.gov/id/1263923

*/

clear all

ssc install chimchar

// update this global to the directory you downloaded everything into!
global route "V:\FHSS-JoePriceResearch\papers\current\wwii_black_longevity\NARA_ww2_enlistment"


**********************
*bring in the dataset!
**********************
// in progress!!
*unzip the raw data file and bring it into stata with
*codes based on example data you can find here:  
*https://aad.archives.gov/aad/record-detail.jsp?dt=893&mtch=1&cat=WR26&tf=F&q=barbara+y+misawa&bc=sl&rpp=10&pg=1&rid=5
clear
cd "$route/raw_downloads"
/* process the raw zipped file download
unzipfile ASNEF.FIN.zip, replace

quietly infix                 ///
  str     serial             1-8    ///
  str     name               9-32   ///
  str     res_state          33-34  ///
  str     res_county         35-37  ///
  str     enlist_station     38-41  ///
  str     enlist_day         42-43  ///
  str     enlist_month       44-45  ///
  str     enlist_year        46-47  ///
  str     grade_alpha        48-50  ///
  str     grade_code         51-52  ///
  str     branch_alpha       53-55  ///
  str     branch_code        56-57  ///
  str     enlistment_term    58-59  ///
  str     longevity          60-62  ///
  str     personnel_source   63     ///
  str     nativity           64-65  ///
  str     birth_year         66-67  ///
  str     race_citizenship   68     ///
  str     education          69     ///
  str     civ_occ            70-72  ///
  str     marst              73     ///
  float   height             74-75  ///
  float   weight             76-78  ///
  str     army_component     79     ///
  str     box_number         80-84  ///
  str     reel_number        85-87  ///
  using "$route/raw_downloads/ASNEF.FIN.DAT"
*/
use "$route\raw_downloads\ASNEF.FIN.dta", clear


****************************
*get rid of bad observations
****************************
// in progress
*start by dropping the observations with strong evidence of bad read-ins or duplication
drop if serial == "ONE OR M" & name == "ORE CARDS WERE UNREADABL" // obvious

duplicates tag serial, gen(tag) // any duplicated serial becomes a potential issue
drop if tag!=0
drop tag

drop if name == "" // can't match without it
drop if strpos(name, "  ")!=0
foreach letter in `c(ALPHA)' {
	di as result "removing instances of `letter'`letter'`letter'"
	drop if strpos(name, "`letter'`letter'`letter'")!=0
}
drop if strpos(name, "ZZ")==1
drop if strpos(name, "ZYY")==1
drop if strpos(name, "/")!=0
drop if strpos(name, "?")!=0
drop if strpos(name, " ")==0
drop if strpos(serial, "0000")!=0 // all of these cases are suspicious based on early inspection
*/


*************************************
*do some name cleaning for the future
*************************************
// done
foreach letter in `c(ALPHA)' {
	// a name like K QUINCY JOHN should have its K removed for best results
	di as result "getting stray `letter's clear from the start of name"
	qui replace name = subinstr(name, "`letter' ", "", 1) if strpos(name, "`letter' ")==1
	qui replace name = subinstr(name, "`letter' ", "", 1) if strpos(name, "`letter' ")==1
	qui replace name = subinstr(name, "`letter' ", "", 1) if strpos(name, "`letter' ")==1
	qui replace name = subinstr(name, "`letter' ", "", 1) if strpos(name, "`letter' ")==1 // we do it four times for cards like A A A A QUINCY JOHN
}
replace name = subinstr(name, "LE ", "LE", 1)
replace name = subinstr(name, "MC ", "MC", 1)
replace name = subinstr(name, "DI ", "DI", 1)
replace name = subinstr(name, "DE ", "DE", 1)
replace name = subinstr(name, "ST ", "ST", 1)
replace name = subinstr(name, "LA ", "LA", 1)
replace name = subinstr(name, "VAN ", "VAN", 1)
replace name = subinstr(name, "MAC ", "MAC", 1)
replace name = subinstr(name, " JR", "", .)
replace name = subinstr(name, " SR", "", .) // this block will help match into the census, which almost never has spaces, and will allow the following split:

*get the two names split out from middle initials (which aren't always in the census)
split name, parse(" ")

rename name1 namelast
gen namefrst = name2 + " " + name3

drop name2 name3 name4 name5 name6 name7 name8

chimchar name namefrst namelast, numremove
*/


*************************************************
*clean race_citizenship into a nice race variable
*************************************************
// this is according to codes from NARA located at https://aad.archives.gov/aad/popup-codelist.jsp?cl_id=2059&dt=893&c_id=24984
gen race_str = ""
gen citizen = .

replace race_str = "White" if race_citizenship=="1"
replace citizen = 1 if race_citizenship=="1"
replace race_str = "Black" if race_citizenship=="2"
replace citizen = 1 if race_citizenship=="2"
replace race_str = "Chinese" if race_citizenship=="3"
replace citizen = 1 if race_citizenship=="3"
replace race_str = "Japanese" if race_citizenship=="4"
replace citizen = 1 if race_citizenship=="4"
replace race_str = "Hawaiian" if race_citizenship=="5"
replace citizen = 1 if race_citizenship=="5"
replace race_str = "American Indian" if race_citizenship=="6"
replace citizen = 1 if race_citizenship=="6"
replace race_str = "Filipino" if race_citizenship=="7"
replace citizen = 1 if race_citizenship=="7"
replace race_str = "Puerto Rican" if race_citizenship=="8"
replace citizen = 1 if race_citizenship=="8"
replace race_str = "Other" if race_citizenship=="9"
replace citizen = 1 if race_citizenship=="9"

replace race_str = "White" if race_citizenship=="J"
replace citizen = 0 if race_citizenship=="J"
replace race_str = "Black" if race_citizenship=="K"
replace citizen = 0 if race_citizenship=="K"
replace race_str = "Chinese" if race_citizenship=="L"
replace citizen = 0 if race_citizenship=="L"
replace race_str = "Japanese" if race_citizenship=="M"
replace citizen = 0 if race_citizenship=="M"
replace race_str = "Hawaiian" if race_citizenship=="N"
replace citizen = 0 if race_citizenship=="N"
replace race_str = "American Indian" if race_citizenship=="O"
replace citizen = 0 if race_citizenship=="O"
replace race_str = "Filipino" if race_citizenship=="P"
replace citizen = 0 if race_citizenship=="P"
replace race_str = "Puerto Rican" if race_citizenship=="Q"
replace citizen = 0 if race_citizenship=="Q"
replace race_str = "Other" if race_citizenship=="R"
replace citizen = 0 if race_citizenship=="R"


*code up an IPUMS-paralleled race code variable
gen race = .
replace race = 1 if race_str == "White"
replace race = 2 if race_str == "Black"
replace race = 3 if race_str == "American Indian"
replace race = 4 if race_str == "Chinese"
replace race = 5 if race_str == "Japanese"
replace race = 6 if race == .
*/


****************************
*clean up the marital status
****************************
// this is according to codes from NARA located at https://aad.archives.gov/aad/popup-codelist.jsp?cl_id=2081&dt=893&c_id=25001
rename marst marst_enlistment
gen marst = .
replace marst = 1 if marst_enlistment=="2"
replace marst = 3 if marst_enlistment=="3" | marst_enlistment=="7"
replace marst = 4 if marst_enlistment=="4" | marst_enlistment=="8"
replace marst = 5 if marst_enlistment=="5" | marst_enlistment=="9"
replace marst = 6 if marst_enlistment=="1" | marst_enlistment=="6"

// remember to recode marst in the ipums data (2=1) to line these up
*/


************************************
*clean up enlistment and birth dates
************************************
// in progress
*enlistment only happened from 1938-47
gen enlistment_year = .
foreach num of numlist 38/47 {
	replace enlistment_year = 19`num' if enlist_year=="`num'"
}


*the latest birthyear legally possible is 1930 enlisting in 1947 (unlikely), but we know some kids faked ages, so 1930 is a good enough cutoff generally
destring birth_year, gen(byr)
foreach num of numlist 0/9 {
	replace byr = 190`num' if byr==`num'
}
foreach num of numlist 10/30 {
	replace byr = 19`num' if byr==`num'
}


*now the earliest legal birthyear would be a 44 year old in 1941, or 1897.
foreach num of numlist 97/99 {
	replace byr = 18`num' if byr==`num'
}


*now we have the 1800s and 1900s covered, so everyone else should technically be missing/miscoded
replace byr = . if byr<1800
*/


****************************************
*clean the state and county of residence
****************************************
// in progress using 100.1CL_SD.pdf
*start with the states found on reference copy #76 (which doesn't include counties)
gen stateicp = .
gen countyicp = .
replace stateicp = 99 if res_state=="01"
replace stateicp = 81 if res_state=="02"
replace stateicp = 82 if res_state=="03"
replace stateicp = 83 if res_state=="08"


*get the state codes from reference copies #77-#139 (Recoded to ICPSR codes)
replace stateicp = 41 if res_state=="41" | res_state=="D1" | res_state=="M1" // Alabama
replace stateicp = 81 if res_state=="02" | res_state=="R0" // Alaska
replace stateicp = 61 if res_state=="98" | res_state=="I8" | res_state=="R8" // Arizona
replace stateicp = 42 if res_state=="87" | res_state=="H7" | res_state=="Q7" // Arkansas
replace stateicp = 71 if res_state=="91" | res_state=="I1" | res_state=="R1" // California
replace stateicp = 62 if res_state=="70" | res_state=="G0" | res_state=="P0" // Colorado
replace stateicp = 1 if res_state=="11" | res_state=="A1" | res_state=="J1" // Connecticut
replace stateicp = 11 if res_state=="21" | res_state=="B1" | res_state=="K1" // Delaware 
replace stateicp = 98 if res_state=="34" | res_state=="C4" | res_state=="L4" // District of Columbia
replace stateicp = 43 if res_state=="42" | res_state=="D2" | res_state=="M2" // Florida
replace stateicp = 44 if res_state=="43" | res_state=="D3" | res_state=="M3" // Georgia
replace stateicp = 82 if res_state=="03" // Hawaii
replace stateicp = 63 if res_state=="92" | res_state=="I2" | res_state=="R2" // Idaho
replace stateicp = 21 if res_state=="61" | res_state=="F1" | res_state=="O1" // Illinois
replace stateicp = 22 if res_state=="51" | res_state=="E1" | res_state=="N1" // Indiana
replace stateicp = 31 if res_state=="72" | res_state=="G2" | res_state=="P2" // Iowa
replace stateicp = 32 if res_state=="73" | res_state=="G3" | res_state=="P3" // Kansas
replace stateicp = 51 if res_state=="52" | res_state=="E2" | res_state=="N2" // Kentucky
replace stateicp = 45 if res_state=="88" | res_state=="H8" | res_state=="Q8" // Louisiana
replace stateicp = 2 if res_state=="12" | res_state=="A2" | res_state=="J2" // Maine
replace stateicp = 52 if res_state=="31" | res_state=="C1" | res_state=="L1" // Maryland
replace stateicp = 3 if res_state=="13" | res_state=="A3" | res_state=="J3" // Massachusetts
replace stateicp = 23 if res_state=="62" | res_state=="F2" | res_state=="O2" // Michigan
replace stateicp = 33 if res_state=="74" | res_state=="G4" | res_state=="P4" // Minnesota
replace stateicp = 46 if res_state=="45" | res_state=="D5" | res_state=="M5" // Mississippi
replace stateicp = 34 if res_state=="75" | res_state=="G5" | res_state=="P5" // Missouri
replace stateicp = 64 if res_state=="93" | res_state=="I3" | res_state=="R3" // Montana
replace stateicp = 35 if res_state=="76" | res_state=="G6" | res_state=="P6" // Nebraska
replace stateicp = 65 if res_state=="94" | res_state=="I4" | res_state=="R4" // Nevada
replace stateicp = 4 if res_state=="14" | res_state=="A4" | res_state=="J4" // New Hampshire
replace stateicp = 12 if res_state=="22" | res_state=="B2" | res_state=="K2" // New Jersey
replace stateicp = 66 if res_state=="83" | res_state=="H3" | res_state=="Q3" // New Mexico
replace stateicp = 13 if res_state=="23" | res_state=="B3" | res_state=="K3" // New York
replace stateicp = 47 if res_state=="46" | res_state=="D6" | res_state=="M6" // North Carolina
replace stateicp = 36 if res_state=="77" | res_state=="G7" | res_state=="P7" // North Dakota
replace stateicp = 24 if res_state=="53" | res_state=="E3" | res_state=="N3" // Ohio
replace stateicp = 53 if res_state=="84" | res_state=="H4" | res_state=="Q4" // Oklahoma
replace stateicp = 72 if res_state=="95" | res_state=="I5" | res_state=="R5" // Oregon
replace stateicp = 14 if res_state=="32" | res_state=="C2" | res_state=="L2" // Pennsylvania
replace stateicp = 5 if res_state=="15" | res_state=="A5" | res_state=="J5" // Rhode Island
replace stateicp = 48 if res_state=="47" | res_state=="D7" | res_state=="M7" // South Carolina
replace stateicp = 37 if res_state=="78" | res_state=="G8" | res_state=="P8" // South Dakota
replace stateicp = 54 if res_state=="48" | res_state=="D8" | res_state=="M8" // Tennessee
replace stateicp = 49 if res_state=="85" | res_state=="H5" | res_state=="Q5" // Texas
replace stateicp = 67 if res_state=="96" | res_state=="I6" | res_state=="R6" // Utah
replace stateicp = 6 if res_state=="16" | res_state=="A6" | res_state=="J6" // Vermont
replace stateicp = 40 if res_state=="33" | res_state=="C3" | res_state=="L3" // Virginia
replace stateicp = 73 if res_state=="97" | res_state=="I7" | res_state=="R7" // Washington
replace stateicp = 56 if res_state=="54" | res_state=="E4" | res_state=="N4" // West Virginia
replace stateicp = 25 if res_state=="63" | res_state=="F3" | res_state=="O3" // Wisconsin
replace stateicp = 68 if res_state=="79" | res_state=="G9" | res_state=="P9" // Wyoming

gen cons_objector = res_state=="A1" | res_state=="A2" | res_state=="A3" | res_state=="A4" | res_state=="A5" | res_state=="A6" | res_state=="B1" | res_state=="B2" | res_state=="B3" | res_state=="C1" | res_state=="C2" | res_state=="C3" | res_state=="C4" | res_state=="D1" | res_state=="D2" | res_state=="D3" | res_state=="D5" | res_state=="D6" | res_state=="D7" | res_state=="D8" | res_state=="E1" | res_state=="E2" | res_state=="E3" | res_state=="E4" | res_state=="F1" | res_state=="F2" | res_state=="F3" | res_state=="G0" | res_state=="G2" | res_state=="G3" | res_state=="G4" | res_state=="G5" | res_state=="G6" | res_state=="G7" | res_state=="G8" | res_state=="G9" | res_state=="H3" | res_state=="H4" | res_state=="H5" | res_state=="H7" | res_state=="H8" | res_state=="I1" | res_state=="I2" | res_state=="I3" | res_state=="I4" | res_state=="I5" | res_state=="I6" | res_state=="I7" | res_state=="I8"


*get the county codes from reference copies #77-#139 (Texas has the most and ends at 507)
foreach value of numlist 10(20)90 {
	local num = `value' / 10
	
	replace countyicp = `value' if res_county=="00`num'"
}

foreach value of numlist 110(20)990 {
	local num = `value' / 10
	
	replace countyicp = `value' if res_county=="0`num'"
}

foreach value of numlist 1010(20)5070 {
	local num = `value' / 10
	
	replace countyicp = `value' if res_county=="`num'"
}


*recode some Virginia counties by hand, because of course we have to do that
replace countyicp = 360 if stateicp==40 & res_county=="036" // Charles City
foreach value of numlist 390(20)990 { // Chesterfield to King William
	local num = `value' / 10
	
	replace countyicp = `value'+20 if stateicp==40 & res_county=="0`num'"
}

foreach value of numlist 1010(20)1970 { // Lancaster to York
	local num = `value' / 10
	
	replace countyicp = `value'+20 if stateicp==40 & res_county=="`num'"
}


*and the rest of the weird ones I could find
replace countyicp = 250 if stateicp==65 & res_county=="027" // Pershing, NV
replace countyicp = 510 if stateicp==65 & res_county=="025" // Carson City, NV
replace countyicp = 455 if stateicp==68 & res_county=="047" // Yellowstone, WY


*we're still missing a lot of stateicp (about 1mil) so we'll use the state of their enlistment station as a proxy fill-in
destring enlist_station, gen(station) force

replace stateicp = 41 if stateicp==. & station>=4100 & station<=4190 // Alabama
replace stateicp = 61 if stateicp==. & station>=9800 & station<=9898 // Arizona
replace stateicp = 42 if stateicp==. & station>=8700 & station<=8798 // Arkansas
replace stateicp = 71 if stateicp==. & ((station>=9000 & station<=9199) | (station>=9381 & station<=9498) | (station>=9900 & station<=9996)) // California
replace stateicp = 62 if stateicp==. & station>=7000 & station<=7094 // Colorado
replace stateicp = 1 if stateicp==. & station>=1100 & station<=1199 // Connecticut
replace stateicp = 11 if stateicp==. & station>=2100 & station<=2190 // Delaware
replace stateicp = 98 if stateicp==. & station>=3400 & station<=3490 // District of Columbia
replace stateicp = 43 if stateicp==. & ((station>=4200 & station<=4299) | (station>=4400 & station<=4447)) // Florida
replace stateicp = 44 if stateicp==. & station>=4300 & station<=4399 // Georgia
replace stateicp = 63 if stateicp==. & station>=9200 & station<=9292 // Idaho
replace stateicp = 21 if stateicp==. & station>=6100 & station<=6199 // Illinois
replace stateicp = 22 if stateicp==. & station>=5100 & station<=5192 // Indiana
replace stateicp = 31 if stateicp==. & station>=7200 & station<=7294 // Iowa
replace stateicp = 32 if stateicp==. & station>=7300 & station<=7396 // Kansas
replace stateicp = 51 if stateicp==. & station>=5200 & station<=5296 // Kentucky
replace stateicp = 45 if stateicp==. & station>=8800 & station<=8893 // Louisiana
replace stateicp = 2 if stateicp==. & station>=1200 & station<=1296 // Maine
replace stateicp = 52 if stateicp==. & station>=3100 & station<=3187 // Maryland
replace stateicp = 3 if stateicp==. & station>=1300 & station<=1399 // Massachusetts
replace stateicp = 23 if stateicp==. & station>=6200 & station<=6296 // Michigan
replace stateicp = 33 if stateicp==. & station>=7400 & station<=7497 // Minnesota
replace stateicp = 46 if stateicp==. & station>=4500 & station<=4598 // Mississippi
replace stateicp = 34 if stateicp==. & station>=7500 & station<=7594 // Missouri
replace stateicp = 64 if stateicp==. & station>=9300 & station<=9380 // Montana
replace stateicp = 35 if stateicp==. & station>=7600 & station<=7698 // Nebraska
replace stateicp = 65 if stateicp==. & station>=9400 & station<=9448 // Nevada
replace stateicp = 4 if stateicp==. & station>=1400 & station<=1495 // New Hampshire
replace stateicp = 12 if stateicp==. & station>=2200 & station<=2291 // New Jersey
replace stateicp = 66 if stateicp==. & station>=8300 & station<=8397 // New Mexico
replace stateicp = 13 if stateicp==. & ((station>=2300 & station<=2452) | (station>=1901 & station<=1903)) // New York
replace stateicp = 47 if stateicp==. & station>=4600 & station<=4693 // North Carolina
replace stateicp = 36 if stateicp==. & station>=7700 & station<=7795 // North Dakota
replace stateicp = 24 if stateicp==. & ((station>=5300 & station<=5399)| (station>=5500 & station<=5517)) // Ohio
replace stateicp = 53 if stateicp==. & station>=8400 & station<=8491 // Oklahoma
replace stateicp = 72 if stateicp==. & station>=9500 & station<=9596 // Oregon
replace stateicp = 14 if stateicp==. & ((station>=3200 & station<=3299) | (station>=3900 & station<=3938)) // Pennsylvania
replace stateicp = 5 if stateicp==. & station>=1500 & station<=1590 // Rhode Island
replace stateicp = 48 if stateicp==. & station>=4700 & station<=4797 // South Carolina
replace stateicp = 37 if stateicp==. & station>=7800 & station<=7895 // South Dakota
replace stateicp = 54 if stateicp==. & station>=4800 & station<=4892 // Tennessee
replace stateicp = 49 if stateicp==. & ((station>=8500 & station<=8699) | (station>=8900 & station<=8921)) // Texas
replace stateicp = 67 if stateicp==. & station>=9600 & station<=9699 // Utah
replace stateicp = 6 if stateicp==. & station>=1600 & station<=1690 // Vermont
replace stateicp = 40 if stateicp==. & station>=3300 & station<=3399 // Virginia
replace stateicp = 73 if stateicp==. & station>=9700 & station<=9797 // Washington
replace stateicp = 56 if stateicp==. & station>=5400 & station<=5496 // West Virginia
replace stateicp = 25 if stateicp==. & station>=6300 & station<=6399 // Wisconsin
replace stateicp = 68 if stateicp==. & station>=7900 & station<=7998 // Wyoming


*build a unique county identifier to split the dataset on
gen str2 state2 = string(stateicp,"%02.0f")
gen str4 county4 = string(countyicp,"%04.0f")

gen place = state2 + county4
replace place = "" if state2=="." | county4=="."

drop state2 county4
*/


*********
*save it!
*********
compress
save "$route\output\NARA_cleaned.dta", replace






  
  