clear
*clear = forcer stata à nettoyer la base avant de l'ouvrir*
set mem 20M
*permet d'augmenter la mémoire mais askip n'est pas nécessaire*

set more off
*Pour ne pas à avoir presser "more" quand on fait tourner un programme*

capture cd "C:\Users\33620\Documents\M2_AGRI\Modélisation_données_économiques\Data"

capture global output "Output"
capture global input "Input"
*permet de définir les deux nouveaux chemins à partir de Data*

global chemin "C:\Users\33620\Documents\M2_AGRI\Modélisation_données_économiques\Data\Input"
global chemin_output "C:\Users\33620\Documents\M2_AGRI\Modélisation_données_économiques\Data\Output"

use "$chemin/AG_SEC_4A.dta", clear 
*clear = forcer stata à nettoyer la base*

count 
*donne le nombre d'observations dans la base de données*
summarize
codebook y3_hhid
*codebook donne informations sur nb de valeurs uniques et nb de valeurs manquantes, si pas de valeurs manquantes ça veut dire que tout le monde a un identifiant*
*string (str8) = variable non numérique*
*ctrl L pour sélectionner une ligne et ctrl D pour la faire tourner*

describe
*donne la liste de toutes les variables, c'est pratique*

rename ag4a_21 surface
*pour renommer une variable, utiliser des parenthèses quand c'est pour plusieurs variables* 

summarize surface, detail
*donne les infos de base, la distribution d'une variable*
*la virgule permet de donner une "option" à la variable* 
*mean = moyenne*

histogram surface if surface<100

tabulate ag4a_17, missing
*permet de voir la répartition sur les valeurs*

generate perte_avant_recolte = (ag4a_17==1 & ag4a_17!=.)
*pour créer une variable*
*il y a des pertes avant récolte seulement quand cette variable est égale à 1*
*le point d'exclamation veut dire différent*

rename ag4a_04 inter_cropping
tabulate zaocode if inter_cropping==1
tabulate zaocode if inter_cropping==2 

tabulate zaocode inter_cropping, col nofreq
*pour un tableau croisé avec deux variables*
*rajouter "col" pour avoir en plus des pourcentages*

tabulate zaocode inter_cropping, row
*pour voir les pourcentages d'une autre manière, en ligne*

tabulate zaoname ag4a_11, col nofreq
tabulate zaoname ag4a_11, row

tabulate zaocode ag4a_18, col
tabulate zaocode ag4a_18, row 

***TD n°2 : surface des parcelles - fusion des fichiers***
*Base de données longue saison des pluies*


use "$chemin/AG_SEC_2A.dta", clear

rename y3_hhid menage
rename ag2a_04 area_estimate
rename ag2a_09 area_GPS

codebook menage

use "$chemin/AG_SEC_2B.dta", clear

count
rename y3_hhid menage
rename ag2b_15 area_estimate
rename ag2b_20 area_GPS

codebook menage

count if plotnum!= ""
*!= (est différent de) et "" = vide*
*pour voir combien de parcelles il y a dans la short rainy season*
codebook plotnum
*pour voir toutes les parcelles, vides ou pas, sur un tableau*

generate long_rainy_season =0
*on met zéro car on est dans la base de données 4b qui est la short rainy season, c'est pour ça qu'on crée une colonne avec long rainy = 0 car il y a pas de parcelles long rainy ici*

keep menage plotnum area_GPS area_estimate long_rainy_season

tempfile base2b
*pour créer une base temporaire*
save `base2b'
*ctrl alt 7 pour ouvrir ces guillemets étranges qui rendent l'écriture bleue*

use "$chemin/AG_SEC_2A.dta", clear
rename y3_hhid menage
rename ag2a_04 area_estimate
rename ag2a_09 area_GPS

count
count if plotnum != ""
codebook menage

generate long_rainy_season = 1
*car cette base de données correspond à la long rainy season*
keep menage plotnum area_GPS area_estimate long_rainy_season 

codebook menage if plotnum != ""

append using `base2b'
*pour fusionner des bases*
*attention avec la touche clear quand on sélectionne tout et on fait tourner, car ça efface toute la base* 

codebook menage
codebook menage if plotnum!= ""
count
tabulate long_rainy_season
*pour voir la répartition* 

keep if plotnum!= "" 

rename plotnum parcelle
save "$chemin_output/data_surface", replace
corr area_GPS area_estimate
*pour voir la corrélation des deux variables. 1= tjrs mêmes valeurs et 0.86 = 86% les mêmes*

twoway (scatter area_GPS area_estimate if area_estimate<100)(lfit area_GPS area_estimate if area_estimate<100)
 *pour voir deux graphiques, nuage de points et ligne, superposés*
 *la ligne montre la relation linéaire entre les deux variables*
 
use "$chemin/AG_SEC_4B.dta", clear
rename ag4b* ag4*
gen long_rainy_season= 0 

tempfile temp_4b
save `temp_4b'

use "$chemin/AG_SEC_4A.dta", clear
rename ag4a* ag4* 
*étoile c'est pour sélectionner tous ceux qui commencent par 4a*
append using `temp_4b'

count
codebook y3_hhid
codebook y3_hhid if plotnum!= "" & long_rainy_season== 0
codebook y3_hhid if long_rainy_season== 0

drop if plotnum== ""
count

rename ag4_28 prod_volume
rename ag4_29 prod_valeur
rename ag4_21 area

count if prod_volume==.
*pour compter le nb de variables manquantes*

gen renvol= prod_volume / area
*générer une variable pour le rendement en volume = rapport entre deux choses*

help gen
*page pour voir comment marche la commande*

gen renval= prod_valeur / area
*valeur de la production en unités monétaires*
*production en kilos divisés par le volume*
*ren = rendement*

*pour voir le rendement moyen dans la base* 
summarize renvol, detail
summarize renval, detail

save "$chemin_output/data_culture_parcelle", replace

*TD 4 et 5 - 14 novembre* 
*avant d'utiliser cette base, il faut montrer à stata quel est mon chemin, pour qu'il puisse la retrouver*
use "$chemin_output/data_culture_parcelle"
tabstat renvol, by(zaocode) statistics(median)
tabstat renval, by(zaocode)
*médiane = donne valeur en dessous de laquelle il y a 50% de la pop*

tabstat area, by(zaocode)
*pour vérifier la surface des cultures*

histogram renvol 
summarize renvol, detail
generate renvolbis = renvol
replace renvolbis = r(p99) if renvol>r(p99)
*pour gérer le problème des valeurs extrêmes*

histogram renvolbis

tabstat renvol, by(zaocode) statistics(median)
generate renvalbis = renval
replace renvalbis = r(p99) if renval>r(p99)
histogram renvalbis
summarize renval, detail

tabulate zaocode, nolabel
generate maraichage_legumineuses = (zaocode>30 & zaocode<49) | (zaocode>85 & zaocode<102)
*cette variable sera par défaut égale à 1 si ça correspond à l'intervalle, ou égale à 0 si ce n'est pas le cas*

tabulate maraichage_legumineuses zaocode
*pour faire un tableau croisé, pour vérifier si la variable est bien construite*

tabulate maraichage_legumineuses
*pour voir la répartition en pourcentage des cultures maraichères et légumineuses*
tabulate zaocode maraichage_legumineuses
*plus lisible comme ça* 

histogram renvolbis, by(maraichage_legumineuses)

tabulate ag4_08, nolabel
tabulate ag4_14
*les graines améliorées ou non sont définies par culture et non pas par parcelle*
*nolabel pour voir le code et non pas le nom*
generate improved_seed = (ag4_08==1 | ag4_08==3)
generate previous_season = (ag4_14==1)

collapse (sum) prod_valeur prod_volume ag4_12 area (first) ag4_04 (max) improved_seed previous_season (mean) maraichage_legumineuses, by (y3_hhid plotnum)
*une fois lancée, la commande va écraser la base et garder une seule ligne par parcelle par menage* 
*(first) veut dire qu'on garder la valeur telle quelle, sans faire la sommme*
*plus intéressant d'avoir la valeur des graines que la quantité car montre l'investissement des agriculteurs*
*(mean) c'est pour faire la moyenne d'une variable précisée*

rename ag4_04 intercropped
rename ag4_12 seeds_val

label variable prod_valeur "Production par parcelle en valeur (TSH)"
label variable prod_volume "Production par parcelle en volume (kilos)"

save "$chemin_output/data_culture_parcelle_final", replace

*TD 5 : suite jusqu'à la fusion et calcul de rendements*

use "$chemin_output/data_culture_parcelle_final", clear

label variable intercropped "Plusieurs cultures par parcelle"
replace intercropped = 0 if intercropped==2
label define intercropped 1 "Yes" 0 "No"
label values intercropped intercropped

label variable seeds_val "Valeur totale des graines"

tabulate intercropped

label variable improved_seed "Graines améliorées"
label define improved_seed 1 "Yes" 0 "No"
label values improved_seed improved_seed

tabulate improved_seed 

label variable area "Surface cultivée"
*Pour calculer la production par surface, il y aurait un biais de mesure car sur chaque surface parfois il y a plusieurs cultures qui ont eu des rendements différents*

rename y3_hhid menage
rename plotnum parcelle

*merge 1:1 = 1 ménage 1 parcelle* 
merge 1:1 menage parcelle using "$output/data_surface"

tabulate _m
codebook menage if _m==2
keep if _m==3
codebook menage
*pour avoir le nombre de ménages*

generate rendement_gps= prod_valeur / area_GPS
generate rendement_estimé= prod_valeur / area_estimate

summarize rendement_gps rendement_estimé, detail
*on observe des valeurs extrêmes*
generate rendement_gps_mod = rendement_gps
summarize rendement_gps, detail

replace rendement_gps_mod = r(p99) if rendement_gps > r(p99)

generate rendement_estimé_mod = rendement_estimé
summarize rendement_estimé, detail

replace rendement_estimé_mod = r(p99) if rendement_estimé > r(p99)
summarize rendement_estimé_mod, detail

histogram rendement_gps_mod
histogram rendement_estimé_mod

summarize rendement_gps_mod rendement_estimé_mod, detail
*rendements estimés sont moins importants, donc les surfaces sont sûrement surestimées*

xtile surface_GPS_q = area_GPS, nq(10)
tabstat rendement_gps_mod, by(surface_GPS_q)
graph bar (mean) rendement_gps_mod, over(surface_GPS_q)
*représenter rendements moyens pour chaque quintile de la surface*
graph box rendement_gps_mod, over(surface_GPS_q) 

xtile surface_estimé_q = area_estimate, nq(10)
tabstat rendement_estimé_mod, by(surface_estimé_q)
graph bar (mean) rendement_estimé_mod, over(surface_estimé_q)
*même chose avec surface estimée* 
graph box rendement_estimé_mod, over(surface_estimé_q) 

drop _m 
*à chaque fois qu'on merge ça crée une variable _m qu'il faut supprimer si on veut merger une autre fois*
save "$chemin_output/data_rendements_parcelle", replace


capture cd "C:\Users\33620\Documents\M2_AGRI\Modélisation_données_économiques\Data"

*TD 6*

capture global output "Output"
capture global input "Input"
*permet de définir les deux nouveaux chemins à partir de Data*

global chemin "C:\Users\33620\Documents\M2_AGRI\Modélisation_données_économiques\Data\Input"
global chemin_output "C:\Users\33620\Documents\M2_AGRI\Modélisation_données_économiques\Data\Output"

use "$chemin/AG_SEC3.dta", clear 

tabulate plotnum
rename y3_hhid menage
rename plotnum parcelle

replace soil_irrigated = 0 if soil_irrigated==2
tabulate soil_irrigated

tabulate soil_quality
replace soil_quality = 4 if soil_quality==1
replace soil_quality = 1 if soil_quality==2
replace soil_quality = 0 if soil_quality==3
replace soil_quality = 2 if soil_quality==4

label define soil_quality 0 "mauvais" 1 "moyen" 2 "bon"
label values soil_quality soil_quality

describe
*pour voir le numéro dans la question*

tabulate soil_type
label define soil_type 1 "sandy" 2 "loam" 3 "clay" 4 "autre"
label values soil_type soil_type

label define soil_steep 1 "flat_bottom" 2 "flat_top" 3 "slightly_sloped" 4 "very_steep"
label values soil_steep soil_steep
tabulate soil_steep

*Maintenant on va pouvoir faire de beaux graphiques*

save "$chemin_output/information_parcelle", replace

*ctrl L pour sélectionner une ligne et ctrl D pour la faire tourner* 

gen ln_org_value = log(org_value + 1)
*dépenses organiques*
*on rajoute un pour ne pas avoir des valeurs égales à 0* 
gen ln_inorg_value = log(inorg_value + 1)
*dépenses inorganiques*
generate ln_pesticides = log(pest_value + 1)
*dépenses en pesticides

histogram ln_inorg_value
histogram ln_org_value
histogram ln_pesticides

graph bar ln_pesticides, over(soil_quality)
graph bar ln_org_value, over(soil_quality)
graph bar ln_inorg_value, over(soil_quality)

graph pie ln_inorg_value ln_org_value ln_pesticides
*ce graphique montre la répartition des dépenses* 
graph bar ln_inorg_value ln_org_value ln_pesticides

graph bar erosion_prob, over(soil_steep)
graph pie, over(soil_quality)
histogram soil_quality, by(soil_type)

twoway (scatter ln_inorg_value ln_pesticides)
*nuage de points*

*fusionner les bases information_parcelle et data_rendements_parcelle

help merge 
merge 1:1 menage parcelle using "$output/data_rendements_parcelle" 
*pour fusionner, il faut que l'unité d'observation soit la même 1=1, mais aussi qu'il y ait des variables communes*

*TD 6 et 7 : SUITE*
keep if _m==3
drop _m

graph bar (mean) rendement_gps, over(soil_quality) by(soil_type)
graph bar (mean) rendement_gps, over(soil_steep)
graph bar (mean) rendement_gps, over(pest_value)

gen ln_prod_val=log(prod_valeur + 1)
gen ln_area_GPS=log(area + 1)
twoway(scatter ln_prod_val ln_area_GPS)

*regarder la base en la comparant avec base géographique pour les fusionner* 
*d'abord il faut sauvegarder la nouvelle base ou non? non. La première est notre "base master" et la deuxième (ménage) est la "base using"*

use "$chemin/HH_SEC_A.dta", clear 
rename y3_hhid menage 
*ensuite j'ai sauvegardé la base avec "menage"*

merge m:1 menage using "$chemin/HH_SEC_A.dta" 

keep if _m==3
drop _m 

*renommer les variables géographiques pour rendre la base plus parlante*
gen region = hh_a01_1 
rename hh_a02_1 district
rename hh_a03_1 ward
rename hh_a04_1 village_ea 
*on utilise le code car on va créer ensuite des cluster qu'on pourra identifier*
*on veut passer du format numérique de ces variables à un format string=non numérique => pour créer un identifiant unique par région* 

tostring region, replace
tostring district, replace
tostring ward, replace
tostring village_ea, replace 

br region
tabulate region, nolabel
*la variable est bien numérique*

tabulate ward
*il faut avoir les mêmes chiffres pour pouvoir les mettre en cluster*

replace ward= substr(ward, 1,2)
replace ward= "0"+ward if length(ward)<2
replace village_ea= "00"+village_ea if length(village_ea)<2
replace village_ea= "0"+village_ea if length(village_ea)<3
generate village_ea_id = region + district + ward + "O" + village_ea
generate cluster_id = substr(village_ea_id, 1,7)  
*on garde les 7 premiers chiffres du cluster*

tabulate region, summarize(rendement_gps)
graph bar (mean) rendement_gps, over(region)

save "$chemin_output/base_finale", replace

use "$chemin/Information_geographique.dta", clear
duplicates drop menage, force
*pour voir et effacer s'il y a plusieurs observations par ménage* 

rename y3_hhid menage
use "$chemin_output/base_finale", clear

help merge
merge m:1 menage using "$chemin/Information_geographique.dta"

*2029 ménages ne sont pas agricoles = ils ont pas matché, donc on ne va pas les garder*
*pour 5 ménages on ne connaît pas les informations géographiques, on pourrait les garder mais ils vont sauter après, et 5 ce n'est pas signifiant* 
*Si c'était un plus grand nombre, il faudrait l'expliquer ou le prendre en compte dans l'analyse. 

keep if _m==3
drop _m 

summarize
tabulate land03
tabulate clim02
tabulate clim03 

*il va falloir merge à nouveau la prochaine fois*
* si okay de se limiter à ce qu'on a fait, sinon on peut demander de l'aide à l'IA et forums pour de nouvelles commandes*





