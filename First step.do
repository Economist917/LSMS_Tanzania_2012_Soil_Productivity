************************************************************
* PROJECT: Agroecological practices, soil quality, erosion
* DATA: LSMS-ISA Tanzania
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

* Pie chart avec nombre d'observations
graph pie, over(erosion_yes) ///
plabel(_all percent) ///
title("Part des parcelles affectées par l'érosion")

* Pie chart avec les labels
graph pie, over(erosion_yes) ///
plabel(_all percent) ///
legend(label(1 "Pas d'érosion") label(2 "Érosion")) ///
title("Part des parcelles affectées par l'érosion")

graph bar (mean) erosion_yes, over(residue_left) ///
blabel(bar, format(%4.2f)) ///
title("Proportion de parcelles avec érosion selon la gestion des résidus") ///
ytitle("Proportion avec érosion")

graph bar (mean) erosion_yes, over(residue_left) ///
blabel(bar, format(%4.2f)) ///
title("Proportion de parcelles avec érosion selon la gestion des résidus")

ttest rendement_gps_mod, by(erosion_yes)
ttest rendement_gps, by(erosion_yes)
reg rendement_gps_mod i.erosion_prob
reg rendement_gps i.erosion_prob

* rendement vs salinité
scatter rendement_gps_mod soil09

graph box rendement_gps_mod, over(soil09)
graph bar (mean) rendement_gps_mod, over(soil09)
reg rendement_gps_mod i.soil09

graph bar (mean) rendement_gps_mod, over(soil09) ///
title("Rendement moyen selon la salinité du sol") ///
ytitle("Rendement moyen") ///
blabel(bar, format(%9.0fc))

table soil09, statistic(mean rendement_gps_mod) statistic(n rendement_gps_mod)

graph box rendement_gps_mod if soil09!=. & soil09!=5 & soil09!=1, over(soil09) ///
title("Rendement selon la salinité du sol") ///
ytitle("Rendement GPS")

drop if soil09==1 | soil09==5

summ rendement_gps_mod, detail


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

table erosion_prob
label define erolab2 1 "Érosion" 2 "Pas d'érosion", replace
label values erosion_prob erolab2

*boxplot
graph box rendement_gps_mod, over(erosion_prob) ///
title("Rendement agricole selon la présence d'érosion") ///
ytitle("Rendement") ///
ylabel(, format(%9.0fc))

*variable logarithmique
gen ln_rendement_gps = ln(rendement_gps_mod) if rendement_gps_mod>0
graph box ln_rendement_gps, over(erosion_prob) ///
title("Log du rendement agricole selon la présence d'érosion") ///
ytitle("Log du rendement")

*bar chart
graph bar (mean) rendement_gps_mod, over(erosion_prob) ///
title("Rendement moyen selon la présence d'érosion") ///
ytitle("Rendement moyen") ///
blabel(bar, format(%9.0fc)) ///
ylabel(, format(%9.0fc))

scatter rendement_gps_mod soil09, ///
title("Rendement agricole et salinité du sol") ///
ytitle("Rendement") ///
xtitle("Salinité du sol")

*graphique avec soil_quality et rnedement_gps_mod
use base_finale_geo.dta, clear
graph box rendement_gps_mod, over(soil_quality) ///
title("Rendement agricole selon la qualité du sol") ///
ytitle("Rendement") ///
ylabel(, format(%9.0fc))

*log
gen ln_rendement_gps = ln(rendement_gps_mod) if rendement_gps_mod>0
graph box ln_rendement_gps, over(soil_quality) ///
title("Log du rendement agricole selon la qualité du sol") ///
ytitle("Log du rendement")

graph bar (mean) erosion_prob, over(intercropped) ///
title("Proportion de parcelles avec érosion selon les cultures intercalaires") ///
ytitle("Proportion avec érosion") ///
blabel(bar, format(%4.2f))

label define erosionlab 1 "Érosion" 2 "Pas d'érosion"
label values erosion_prob erosionlab

tab erosion_prob intercropped, row chi2
use final_agri_analysis.dta, clear

*****
rename y3_hhid menage
rename plotnum parcelle

describe menage parcelle occ residue_left irrigation_type ///
         soil_quality_source inorganic_fert fert_qty erosion irrigated

duplicates report menage parcelle
duplicates report menage parcelle occ



************************************************************
* Nettoyer final_agri_analysis_ready.dta
************************************************************
use final_agri_analysis_ready.dta, clear

drop if missing(menage) | missing(parcelle) | missing(occ)

duplicates report menage parcelle occ
duplicates tag menage parcelle occ, gen(dup)
browse if dup>0

************************************************************
* Agréger pour avoir une seule ligne par menage-parcelle-occ
************************************************************
collapse (max) residue_left inorganic_fert erosion irrigated ///
         irrigation_type soil_quality soil_quality_source ///
         (sum) fert_qty, by(menage parcelle occ)

save final_agri_analysis_collapsed.dta, replace

************************************************************
* Vérifier unicité
************************************************************
use final_agri_analysis_collapsed.dta, clear
isid menage parcelle occ

************************************************************
* Merge final
************************************************************
use base_finale_geo.dta, clear

merge 1:1 menage parcelle occ using final_agri_analysis_collapsed.dta

tab _merge

keep if _merge==3
drop _merge

save final_complete_analysis.dta, replace

************************************************************
* fertilisation
************************************************************

use final_agri_with_base.dta, clear

* Vérifier le codage
tab inorganic_fert
tab erosion_prob
tab erosion

gen erosion_yes = .
replace erosion_yes = 1 if erosion_prob==1
replace erosion_yes = 0 if erosion_prob==2

* avec erosion :
replace erosion_yes = 1 if missing(erosion_yes) & erosion==1
replace erosion_yes = 0 if missing(erosion_yes) & erosion==2

* fertilisation inorganique
gen fert_use = .
replace fert_use = 1 if inorganic_fert==1
replace fert_use = 0 if inorganic_fert==2

* labels
label define erolab 0 "Pas d'érosion" 1 "Érosion", replace
label values erosion_yes erolab

label define fertlab 0 "Pas d'engrais inorganique" 1 "Utilise engrais inorganique", replace
label values fert_use fertlab

* verification
tab fert_use
tab erosion_yes
tab fert_use erosion_yes, row

graph bar (mean) fert_use, over(erosion_yes) ///
title("Utilisation d'engrais inorganique selon l'érosion") ///
ytitle("Proportion de parcelles utilisant un engrais") ///
blabel(bar, format(%4.2f))

tab fert_use erosion_yes, row chi2

graph box fert_qty, over(erosion_yes) ///
title("Quantité d'engrais selon la présence d'érosion") ///
ytitle("Quantité d'engrais")

table erosion_yes, statistic(mean fert_qty) statistic(n fert_qty)

reg fert_qty i.erosion_yes
reg fert_use i.erosion_yes

graph bar (mean) fert_use, over(erosion_yes, label(angle(0))) ///
title("Usage d'engrais inorganique selon l'état d'érosion") ///
ytitle("Proportion") ///
ylabel(0(.2)1, format(%3.1f)) ///
blabel(bar, format(%4.2f)) ///
legend(off)

graph box fert_qty, over(erosion_yes, label(angle(0))) ///
title("Quantité d'engrais utilisée selon l'érosion") ///
ytitle("Quantité d'engrais") ///
ylabel(, format(%9.0fc))


tab org_fertilizer

gen org_fert_use = .
replace org_fert_use = 1 if org_fertilizer==1
replace org_fert_use = 0 if org_fertilizer==2

label define orglab 0 "Pas d'engrais organique" 1 "Utilise engrais organique", replace
label values org_fert_use orglab

graph bar (mean) org_fert_use, over(erosion_yes) ///
title("Utilisation d'engrais organique selon l'érosion") ///
ytitle("Proportion") ///
blabel(bar, format(%4.2f))

tab org_fert_use erosion_yes, row chi2
