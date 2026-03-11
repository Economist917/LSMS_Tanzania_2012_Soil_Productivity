************************************************************
* PROJECT: Agroecological practices, soil quality, erosion
* DATA: LSMS-ISA Tanzania
* PURPOSE:
* 1. Append section 3A + 3B
* 2. Append section 5A + 5B
* 3. Harmonize variables
* 4. Merge section 3 and section 5
* 5. Create erosion/residue variables
* 6. Draw Graph 1 and table
************************************************************

clear all
set more off

************************************************************
* STEP 0. Set working directory
************************************************************
* Change this to your folder path
cd "C:\Users\USER\Downloads"

************************************************************
* STEP 1. APPEND SECTION 3A + 3B
************************************************************
use "3A.dta", clear
append using "3B.dta"
save "section3_combined.dta", replace

************************************************************
* STEP 2. APPEND SECTION 5A + 5B
************************************************************
use "5A.dta", clear
append using "5B.dta"
save "section5_combined.dta", replace

************************************************************
* STEP 3. CLEAN / HARMONIZE SECTION 3
************************************************************
use "section3_combined.dta", clear

* Harmonized erosion variable
gen erosion = .
replace erosion = ag3a_13 if !missing(ag3a_13)
replace erosion = ag3b_13 if missing(erosion) & !missing(ag3b_13)

* Harmonized irrigation yes/no
gen irrigated = .
replace irrigated = ag3a_18 if !missing(ag3a_18)
replace irrigated = ag3b_18 if missing(irrigated) & !missing(ag3b_18)

* Harmonized irrigation type
gen irrigation_type = .
replace irrigation_type = ag3a_19 if !missing(ag3a_19)
replace irrigation_type = ag3b_19 if missing(irrigation_type) & !missing(ag3b_19)

* Harmonized soil quality
gen soil_quality = .
replace soil_quality = ag3a_11 if !missing(ag3a_11)
replace soil_quality = ag3b_11 if missing(soil_quality) & !missing(ag3b_11)

* Harmonized source of soil quality information
gen soil_quality_source = .
replace soil_quality_source = ag3a_12 if !missing(ag3a_12)
replace soil_quality_source = ag3b_12 if missing(soil_quality_source) & !missing(ag3b_12)

* Harmonized inorganic fertilizer use
gen inorganic_fert = .
replace inorganic_fert = ag3a_47 if !missing(ag3a_47)
replace inorganic_fert = ag3b_47 if missing(inorganic_fert) & !missing(ag3b_47)

* Harmonized inorganic fertilizer quantity
gen fert_qty = .
replace fert_qty = ag3a_49 if !missing(ag3a_49)
replace fert_qty = ag3b_49 if missing(fert_qty) & !missing(ag3b_49)

* Keep only useful variables
keep y3_hhid occ plotnum erosion irrigated irrigation_type ///
     soil_quality soil_quality_source inorganic_fert fert_qty

* Remove duplicates
duplicates drop y3_hhid occ, force

* Save clean section 3
save "section3_clean.dta", replace

************************************************************
* STEP 4. CLEAN / HARMONIZE SECTION 5
************************************************************
use "section5_combined.dta", clear

* First residue response
gen residue1 = .
replace residue1 = ag5a_33_1 if !missing(ag5a_33_1)
replace residue1 = ag5b_33_1 if missing(residue1) & !missing(ag5b_33_1)

* Second residue response
gen residue2 = .
replace residue2 = ag5a_33_2 if !missing(ag5a_33_2)
replace residue2 = ag5b_33_2 if missing(residue2) & !missing(ag5b_33_2)

* Final binary variable: residue left in field
gen residue_left = 0
replace residue_left = 1 if residue1==2 | residue2==2

* Keep only useful variables
keep y3_hhid occ zaocode zaoname residue1 residue2 residue_left

* Save clean section 5
save "section5_clean.dta", replace

************************************************************
* STEP 5. MERGE SECTION 3 + SECTION 5
************************************************************
use "section3_clean.dta", clear
merge 1:m y3_hhid occ using "section5_clean.dta"

* Check merge
tab _merge

* Keep matched observations only
keep if _merge==3
drop _merge

* Save final merged dataset
save "final_agri_analysis.dta", replace

************************************************************
* STEP 6. CREATE FINAL EROSION VARIABLE FOR GRAPH
************************************************************
use "final_agri_analysis.dta", clear

* Check coding first
tab erosion

* Create binary erosion variable
* Assumption used before:
* 1 = yes (erosion)
* 2 = no (no erosion)

gen erosion_yes = .
replace erosion_yes = 1 if erosion==1
replace erosion_yes = 0 if erosion==2

************************************************************
* STEP 7. LABEL VARIABLES FOR GRAPH
************************************************************
label define reslab 0 "Résidus non laissés au champ" 1 "Résidus laissés au champ"
label values residue_left reslab

label define erolab 0 "Pas d'érosion" 1 "Érosion"
label values erosion_yes erolab

************************************************************
* STEP 8. GRAPH 1
************************************************************
graph bar (mean) erosion_yes, over(residue_left) ///
title("Érosion selon la gestion des résidus de culture") ///
ytitle("Proportion de parcelles avec érosion") ///
blabel(bar, format(%4.2f))

************************************************************
* STEP 9. TABLE FOR GRAPH 1
************************************************************
tab erosion_yes residue_left, row

************************************************************
* STEP 10. MERGE THE AGRICULTURAL ANALYSIS FILE WITH THE
*          FINAL PLOT-LEVEL DATABASE
************************************************************
* Purpose:
* We merge the dataset constructed from Sections 3 and 5
* (`final_agri_analysis.dta`) with the dataset `base_finale.dta`,
* which contains additional plot-level characteristics such as
* intercropping practices and agricultural yields.

use base_finale.dta, clear

* Harmonize variable names so identifiers match across datasets
rename menage y3_hhid
rename parcelle plotnum

* Save cleaned version
save base_finale_clean.dta, replace

* Load dataset constructed previously from Sections 3 and 5
use final_agri_analysis.dta, clear

* Merge datasets using household ID and plot number
merge m:1 y3_hhid plotnum using base_finale_clean.dta

* Check merge result
tab _merge

* Keep only matched observations
keep if _merge==3
drop _merge

* Save final merged dataset used for analysis
save final_agri_with_base.dta, replace


************************************************************
* STEP 11. CHECK UNIQUENESS OF PLOT IDENTIFIERS
************************************************************
* This diagnostic step verifies whether each household–plot
* combination appears only once in the dataset.

duplicates report y3_hhid plotnum


************************************************************
* STEP 12. GRAPHICAL ANALYSIS: CROP RESIDUE MANAGEMENT
*          AND SOIL EROSION
************************************************************

* Recreate binary erosion variable
gen erosion_yes = .
replace erosion_yes = 1 if erosion==1
replace erosion_yes = 0 if erosion==2

graph pie, over(intercropped) ///
title("Répartition des parcelles selon la pratique de cultures intercalaires")

graph pie, over(erosion_yes) ///
title("Part des parcelles affectées par l'érosion")

graph bar (mean) erosion_yes, over(residue_left) ///
blabel(bar, format(%4.2f)) ///
title("Proportion de parcelles avec érosion selon la gestion des résidus") ///
ytitle("Proportion avec érosion")

graph bar (mean) erosion_yes, over(residue_left) ///
blabel(bar, format(%4.2f)) ///
title("Proportion de parcelles avec érosion selon la gestion des résidus")

************************************************************
* STEP 13. GRAPHICAL ANALYSIS: INTERCROPPING AND EROSION
************************************************************
* Purpose:
* Another agroecological practice potentially limiting erosion
* is intercropping (polyculture). We therefore compare erosion
* rates between plots with and without intercropping.

* Check coding of the intercropping variable
tab intercropped

* Recode into a binary variable for easier interpretation
gen intercropped_yes = .
replace intercropped_yes = 1 if intercropped==1
replace intercropped_yes = 0 if intercropped==2

* Add readable labels
label define intercroplab 0 "Pas de cultures intercalaires" 1 "Cultures intercalaires"
label values intercropped_yes intercroplab

* Bar graph showing proportion of erosion by intercropping status
graph bar (mean) erosion_yes, over(intercropped_yes) ///
title("Érosion selon la pratique de cultures intercalaires") ///
ytitle("Proportion de parcelles avec érosion")

* Cross-tabulation accompanying the graph
tab erosion_yes intercropped_yes, row
