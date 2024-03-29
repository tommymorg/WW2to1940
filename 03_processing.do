/*

process and clean the matched black files into one big file

*/

clear all
set max_memory 128g

// update this global to the directory you downloaded everything into!
global route "V:\FHSS-JoePriceResearch\papers\current\wwii_black_longevity\NARA_ww2_enlistment"


*****************************************
*do basic cleaning and a bunch of appends
*****************************************
// in progress
*get a local with all the files we need and an empty tempfile to append
local files: dir "$route/match_pieces" files "reclinked_*"
cd "$route/match_pieces"

tempfile appender
save `appender', emptyok

*append the files with some basic cleaning based on visual inspection
foreach f of local files {
	use `"`f'"', clear
	
	*drop non-matches, worse matches, and obvious bad matches
	gsort serial -match_score
	drop if serial=="" | serial==serial[_n-1]
	
	gsort histid1940 -match_score
	drop if histid1940=="" | histid1940==histid1940[_n-1]
	
	format match_score %10.9f
	drop if match_score<.87 & (Unamefrst!="")
	drop if Unamefrst=="" & name!=Uname
	drop if namefrst==""
	drop if abs(byr-Ubyr)>5
	drop if strpos(serial,"A")==1
	
	*clean up a couple variables to save space!
	drop _merge place
	
	*append the file to the appender then resave the appender
	append using `appender'
	save `appender', replace
}


*re-clean in an alternate order: instead of keeping best match and making a cutoff, make a cutoff and then drop everyone with multiple matches above that cutoff
local files: dir "$route/match_pieces" files "reclinked_*"
cd "$route/match_pieces"

tempfile appender2
save `appender2', emptyok

foreach f of local files {
	use `"`f'"', clear
	
	*drop non-matches, worse matches, and obvious bad matches
	format match_score %10.9f
	drop if match_score<.87 & (Unamefrst!="")
	drop if Unamefrst=="" & name!=Uname
	drop if namefrst==""
	drop if abs(byr-Ubyr)>5
	drop if strpos(serial,"A")==1
		
	sum stateicp
	if "`r(N)'"!="0" {
		
		bysort histid1940: gen histmatchcount = _N
		drop if histmatchcount!=1
		
		bysort serial: gen serialmatchcount = _N
		drop if serialmatchcount!=1
		
		*clean up a couple variables to save space!
		drop _merge place histmatchcount serialmatchcount
		
		*append the file to the appender then resave the appender
		append using `appender2'
		save `appender2', replace
	}
	
	else {
		di "this one is empty now!!!"
	}
}

append using `appender'


*drop the complete dupes!!
gsort histid1940 -match_score
drop if histid1940==histid1940[_n-1] & serial==serial[_n-1]


*get rid of the female histids because they're almost never a match in this model
merge m:1 histid1940 using "V:\FHSS-JoePriceResearch\data\census_data\ipums\ipums_1940\serialpernum1940_histid1940.dta", keep(1 3) nogen
merge m:1 serial1940 pernum1940 using "V:\FHSS-JoePriceResearch\data\census_data\ipums\ipums_1940\serialpernum1940_sex.dta", keep(1 3) nogen

drop if sex==2
drop sex id

*tempfile save the kinda-clean links to get bpl on
tempfile preprunelinks
save `preprunelinks', replace


*bring the other matches on and make them unique on serial. use birthplace as the difference maker for otherwise equivalent match scores
import delimited "$route\raw_downloads\cl_2046.csv", clear varn(1) bindquote(strict)

drop comments
split meaning, p(",")
drop meaning meaning2
rename (code meaning1) (nativity bpl_nara)

tempfile bpls
save `bpls', replace


*bring the links back and get bpl in!!
use `preprunelinks', clear
merge m:1 nativity using `bpls', keep(1 3) nogen

merge m:1 serial1940 pernum1940 using "V:\FHSS-JoePriceResearch\data\census_data\ipums\ipums_1940\serialpernum1940_bpl.dta", keep(1 3) nogen


// decode everything into strings for cleaning and match checking
decode bpl, gen(bpl_ipums)
drop bpl

chimchar bpl_nara bpl_ipums, numremove

gen match = bpl_nara==bpl_ipums


// the 0.25 section

*the ones with missing values are unverifiable
replace match = 0.25 if bpl_nara==""


// the 0.5 section

*deal with these generalized codes
local statedenoters `""alaska" "alabama" "arkansas" "arizona" "california" "colorado" "connecticut" "districtofcolumbia" "delaware" "florida" "georgia" "hawaii" "iowa" "idaho" "illinois" "indiana" "kansas" "kentucky" "louisiana" "massachusetts" "maryland" "maine" "michigan" "minnesota" "missouri" "mississippi" "montana" "northcarolina" "northdakota" "nebraska" "newhampshire" "newjersey" "newmexico" "nevada" "newyork" "ohio" "oklahoma" "oregon" "pennsylvania" "rhodeisland" "southcarolina" "southdakota" "tennessee" "texas" "utah" "virginia" "vermont" "washington" "wisconsin" "westvirginia" "wyoming""'

*blanket mark these to unmark in the loop below
replace match = 0.5 if bpl_nara=="foreigncountry"
replace match = 0.5 if bpl_ipums=="europens"

foreach state of local statedenoters {
	
	*get the foreign nara folks marked and then unmarked if applicable
	replace match = 0 if bpl_nara=="foreigncountry" & bpl_ipums=="`state'"
	
	*mark the us nara folks
	replace match = 0.5 if bpl_nara=="usatlarge" & bpl_ipums=="`state'"
	
	*get the european ipums folks unmarked (they're all either states or european countries)
	replace match = 0 if bpl_ipums=="europens" & bpl_nara=="`state'"
	
}


// the 0.75 section

*the ones where the codes are really close to each other on the NARA cards and there's a weirdly large number of that specific mismatch feel likely to match
replace match = 0.75 if ///
(bpl_ipums=="austria" & (bpl_nara=="kentucky")) | ///
(bpl_ipums=="china" & (bpl_nara=="southdakota")) | ///
(bpl_ipums=="czechoslovakia" & (bpl_nara=="westvirginia")) | ///
(bpl_ipums=="denmark" & (bpl_nara=="florida")) | ///
(bpl_ipums=="england" & (bpl_nara=="delaware")) | ///
(bpl_ipums=="estonia" & (bpl_nara=="southcarolina")) | ///
(bpl_ipums=="finland" & (bpl_nara=="northcarolina")) | ///
(bpl_ipums=="france" & (bpl_nara=="pennsylvania")) | ///
(bpl_ipums=="germany" & (bpl_nara=="indiana")) | ///
(bpl_ipums=="hungary" & (bpl_nara=="ohio")) | ///
(bpl_ipums=="india" & (bpl_nara=="indiana")) | ///
(bpl_ipums=="iran" & (bpl_nara=="kansas")) | ///
(bpl_ipums=="ireland" & (bpl_nara=="newjersey")) | ///
(bpl_ipums=="latvia" & (bpl_nara=="tennessee")) | ///
(bpl_ipums=="lebanon" & (bpl_nara=="virginia")) | ///
(bpl_ipums=="mexico" & (bpl_nara=="newmexico")) | ///
(bpl_ipums=="philippines" & (bpl_nara=="montana")) | ///
(bpl_ipums=="saudiarabia" & (bpl_nara=="iowa")) | ///
(bpl_ipums=="scotland" & (bpl_nara=="delaware")) | ///
(bpl_ipums=="southamerica" & (bpl_nara=="connecticut" | bpl_nara=="maine" | bpl_nara=="massachusetts" | bpl_nara=="newhampshire" | bpl_nara=="rhodeisland" | bpl_nara=="vermont")) | /* j codes */ ///
(bpl_ipums=="spain" & (bpl_nara=="wisconsin")) | ///
(bpl_ipums=="sweden" & (bpl_nara=="mississippi")) | ///
(bpl_ipums=="switzerland" & (bpl_nara=="alaska" | bpl_nara=="michigan")) | ///
(bpl_ipums=="syria" & (bpl_nara=="virginia")) | ///
(bpl_ipums=="thailand" & (bpl_nara=="northdakota")) | ///
(bpl_ipums=="turkey" & (bpl_nara=="colorado")) | ///
(bpl_ipums=="wales" & (bpl_nara=="delaware"))


// the 1 section (just text fixes)
*the ones that are actually matches that just don't line up textually
replace match = 1 if ///
(bpl_ipums=="abroadunknownoratsea" & (bpl_nara=="atsea")) | ///
(bpl_ipums=="africa" & (bpl_nara=="angloegyptionsudanorbritishcameroonsorbritishnorthafricaorgambiaorgoldcoastornigeriaorsierraleoneortogolandortonga" | bpl_nara=="ascensionorbasutolandorbechuanalandorbritishsomalilandorbritishsouthafricaorcapeofgoodhopeorkenyaormauritiusornatalornorthrhodesiaornyassalandororangefreestateorpembaorsouthrhodesiaorsouthwestafricaorsthelenaorswazilandortanganyikaortransvaalorugandaorunionofsouthafricaorzanzibar" | bpl_nara=="belgianafricanpossessionsorbelgiancongo" | bpl_nara=="egypt" | bpl_nara=="liberia")) | ///
(bpl_ipums=="americansamoa" & (bpl_nara=="australiaorbismarkislandsorbritishaustralasiaandoceaniaorfijiislandsornewguineaornewzealandorotherpacificbritishislandsorpapuaorsolomonislandsortasmania")) | ///
(bpl_ipums=="asiaminorns" & (bpl_nara=="iraqormesopotamia" | bpl_nara=="russiaorunionofsocialistsovietrepublics")) | ///
(bpl_ipums=="atlanticislands" & (bpl_nara=="angolaorcapeverdeislandsormozambiqueorportugeseafricanpossessionsorportugeseguineaorprincipeorstthome" | bpl_nara=="bahamasorbarbadosorbermudaorbritishcentralamericaorbritishhondurasorbritishwestindiesorcaymanislandsorjamaicaorleewardislandsortobagoortrinidadorturksandcaicosislandsorwindwardislands" | bpl_nara=="ifniorriodeoroorspanishafricanpossessionsorspanishguineaorspanishmorocco")) | ///
(bpl_ipums=="australiaandnewzealand" & (bpl_nara=="australiaorbismarkislandsorbritishaustralasiaandoceaniaorfijiislandsornewguineaornewzealandorotherpacificbritishislandsorpapuaorsolomonislandsortasmania")) | ///
(bpl_ipums=="belgium" & (bpl_nara=="belgiumorluxemburg")) | ///
(bpl_ipums=="canada" & (bpl_nara=="britishnorthamericaorcanadaorlabradorornewfoundland")) | ///
(bpl_ipums=="centralamerica" & (bpl_nara=="costarica" | bpl_nara=="dominicanrepublicorsantodomingo" | bpl_nara=="guatemala" | bpl_nara=="honduras" | bpl_nara=="nicaragua" | bpl_nara=="panama" | bpl_nara=="panamacanalzone" | bpl_nara=="salvador")) | ///
(bpl_ipums=="china" & (bpl_nara=="chosenorformosaorjapaneseasiaticpossessionsorjapanesepacificislandsorkwungtungorkorea")) | ///
(bpl_ipums=="cuba" & (bpl_nara=="puertoricoincludingvirginislandsandcuba")) | ///
(bpl_ipums=="cyprus" & (bpl_nara=="britishmediterraneanpossessionsorcyprusorgibralterormaltaorpalestine")) | ///
(bpl_ipums=="gibraltar" & (bpl_nara=="britishmediterraneanpossessionsorcyprusorgibralterormaltaorpalestine")) | ///
(bpl_ipums=="indonesia" & (bpl_nara=="dutchasiaticpossessionsordutcheastindies")) | ///
(bpl_ipums=="iraq" & (bpl_nara=="iraqormesopotamia")) | ///
(bpl_ipums=="israelpalestine" & (bpl_nara=="britishmediterraneanpossessionsorcyprusorgibralterormaltaorpalestine")) | ///
(bpl_ipums=="italy" & (bpl_nara=="italyorsanmarino")) | ///
(bpl_ipums=="korea" & (bpl_nara=="chosenorformosaorjapaneseasiaticpossessionsorjapanesepacificislandsorkwungtungorkorea")) | ///
(bpl_ipums=="latvia" & (bpl_nara=="russiaorunionofsocialistsovietrepublics")) | ///
(bpl_ipums=="lebanon" & (bpl_nara=="britishmediterraneanpossessionsorcyprusorgibralterormaltaorpalestine")) | ///
(bpl_ipums=="luxembourg" & (bpl_nara=="belgiumorluxemburg")) | ///
(bpl_ipums=="malaysia" & (bpl_nara=="baluchistanorbritisheastindiesandfareastorbritishnorthborneoorbruneiorfederatedmalaystatesorhongkongorsarawakorstraitssettlements")) | ///
(bpl_ipums=="malta" & (bpl_nara=="britishmediterraneanpossessionsorcyprusorgibralterormaltaorpalestine")) | ///
(bpl_ipums=="netherlands" & (bpl_nara=="hollandornetherlands")) | ///
(bpl_ipums=="norway" & (bpl_nara=="norwayorspitzbergen")) | ///
(bpl_ipums=="otherussrrussia" & (bpl_nara=="russiaorunionofsocialistsovietrepublics")) | ///
(bpl_ipums=="pacificislands" & (bpl_nara=="frenchpacificislandsornewcaledoniaortahiti")) | ///
(bpl_ipums=="portugal" & (bpl_nara=="andorraorportugal")) | ///
(bpl_ipums=="puertorico" & (bpl_nara=="puertoricoincludingvirginislandsandcuba")) | ///
(bpl_ipums=="romania" & (bpl_nara=="roumania")) | ///
(bpl_ipums=="sanmarino" & (bpl_nara=="italyorsanmarino")) | ///
(bpl_ipums=="southamerica" & (bpl_nara=="argentina" | bpl_nara=="chile" | bpl_nara=="paraguay" | bpl_nara=="uruguay" | bpl_nara=="")) | ///
(bpl_ipums=="southeastasians" & (bpl_nara=="baluchistanorbritisheastindiesandfareastorbritishnorthborneoorbruneiorfederatedmalaystatesorhongkongorsarawakorstraitssettlements")) | ///
(bpl_ipums=="stpierreandmiquelon" & (bpl_nara=="britishnorthamericaorcanadaorlabradorornewfoundland")) | ///
(bpl_ipums=="unitedkingdomns" & (bpl_nara=="bahamasorbarbadosorbermudaorbritishcentralamericaorbritishhondurasorbritishwestindiesorcaymanislandsorjamaicaorleewardislandsortobagoortrinidadorturksandcaicosislandsorwindwardislands")) | ///
(bpl_ipums=="usvirginislands" & (bpl_nara=="puertoricoincludingvirginislandsandcuba" | bpl_nara=="bahamasorbarbadosorbermudaorbritishcentralamericaorbritishhondurasorbritishwestindiesorcaymanislandsorjamaicaorleewardislandsortobagoortrinidadorturksandcaicosislandsorwindwardislands")) | ///
(bpl_ipums=="westindies" & (bpl_nara=="bahamasorbarbadosorbermudaorbritishcentralamericaorbritishhondurasorbritishwestindiesorcaymanislandsorjamaicaorleewardislandsortobagoortrinidadorturksandcaicosislandsorwindwardislands")) | ///
(bpl_ipums=="yugoslavia" & (bpl_nara=="jugoslaviaormontenegrooryugoslavia"))


// use distance between reported birthyears as the final demarcators. anything still duped after all this is basically indistinguishable now.
gen byr_absdif = abs(Ubyr-byr)

duplicates tag serial match match_score byr_absdif, gen(yoink)
drop if yoink>0
drop yoink


// do the sort and drop the dupes and full mismatches
gsort serial -match -match_score byr_absdif
drop if serial==serial[_n-1] | match==0


// clean up the file of stuff that you don't really need (i.e. reclink remnants)
rename (U*) (nara_*)


*merge in the ark-pid-deathyears to see whose info we can get!
merge m:1 serial1940 pernum1940 using "V:\FHSS-JoePriceResearch\data\census_data\fs_to_ipums\ark1940_serialpernum1940.dta", keep(1 3) nogen
merge m:1 ark1940 using "V:\FHSS-JoePriceResearch\data\census_data\fs_to_tree\clean_ark_pid_crosswalks\ark1940_pid_clean.dta", keep(1 3) nogen
merge m:1 pid using "V:\FHSS-JoePriceResearch\data\death_data\scraped\updated_10_14_2023.dta", keep(1 3) nogen

drop ark1940 pid hint_status
replace deathyear = . if deathyear<1940 | deathyear>2023

compress
save "$route\output\processed_census_to_WWII_links.dta", replace





