* ssc install metan

import excel "C:\Users\fvendrel\Dropbox\Pirradas\Papers\Paper Rodrigo Metaanalisis\Table Coding results v5.xlsx", sheet("Hoja1") firstrow



*** ARREGLAR VARIABLES - EN PROCESO
gen primary = 0 
replace primary = 1 if Data=="Survey"
* Collapse the data to the paper level

gen Year_ = 1 if Year==2018
replace Year_ = 2 if Year==2019
replace Year_ = 3 if Year==2020
replace Year_ = 4 if Year==2021
replace Year_ = 5 if Year==2022
replace Year_ = 6 if Year==2023
replace Year_ = 7 if Year==2024
replace Year_ = 8 if Year==2025
replace Year_ = 9 if Year==2026
gen Year_sq = Year_*Year_
****

*** COLAPSAR PARA GRAFICOS - CUANDO QUEREMOS DAR EL LISTADO DE PAPERS MEJOR QUE CADA PAPER SALGA SOLO UNA VEZ
preserve
collapse (mean) mean_effect = Effectsize (mean) mean_sample_size = Samplesize (mean) mean_Desv_s = Desv_s (mean) mean_year = Year (first) studylbl, by(Study)
meta set mean_effect mean_Desv_s,  random studylabel(studylbl)
meta forestplot, subgroup(mean_year)
restore

*** SET META Y ALGUNOS TESTS
* Para establecer las variables a analizar y el tipo de efectos, aqui aleatorios:
meta set Effectsize Desv_s, studylabel(studylbl) random


* Sumario de estudios
meta summarize

* Para analizar la heteogeneidad
meta forestplot

meta forestplot, subgroup(primary)

*** El test sugiere que los estudios no son homogéneos y que hay variabilidad significativa entre ellos. Habria que ver que causa dicha heterogeneidad.

meta funnelplot

meta funnelplot, contours(1 5 10)

* Efecto del tamño de la muestra en los resultados del estudio, ¿existe publication bias?
meta bias, egger
*** No se rechaza la hipotesis nula, luego el test sugiere que no hay evidencia estadísticamente significativa de que los estudios pequeños afecten los resultados. Luego no es el tamaño muestral lo que crea heterogeneidad. Para comprobarlo veo si me falta algun estudio dentro del funnel:
meta trimfill, funnel
*** Todos los puntos amarillos estan fuera, luego no me faltaria ninguno. El tamaño de los estudios no causa la heterogeneidad.

* Para ver si las regiones causan heterogeneidad
meta summarize, subgroup(Region)
*** Oscar  esto significa que los efectos de los estudios varían significativamente entre regiones
*** Ferran: el problema aqui es que hay estudios que ponen global y no son lo mismo. Tambien hay estudios con paises repetidos pero son solo en parte, ej, Alemania sale en dos estudios pero es una muestra con otro pais que no comparte el estudio. He mandado correo a autores para intentar tener lista de paises precisas - 

* Oscar: El tipo de industria tambien presenta diferencias significativas
meta summarize, subgroup(Industry) 
/* FERRAN: Aqui el problema es que la variable de industria es demasiado generica - la mayoria es simple manufacturing, hay otra categoria que es multiple - pocos estudios con industria especifica dentro de manufacturing - hay algo que se pueda hacer*/

* El tipo de datos tambien:
meta summarize, subgroup(Data)


*** REGRESSION ANALYSIS 
**********Hay dos tipos de modelos que vamos a correr 
*---------1. Los analisis con 'meta regress'. Estos analisis son perfectos para tener en cuenta que estamos haciendo un meta-analisis.
*---------2. Los analisis usando mixed. Esto es un robustness para tener en cuenta que tenemos dos niveles de analisis, el de paper y el de modelo. Se trata de un multinivel que tienen en cuenta esto. 

gen Avscore_sq = Avscore*Avscore
encode Perf, gen(Perf_num)
encode Method, gen(Method_num)
encode Serv, gen(Serv_num)
encode IndCode1, gen(NACE_num)


*xi: meta regress Year_ Year_sq  primary Avtop ib4.Perf_num
xi: meta regress Avscore Avscore_sq ib1.Perf_num ib2020.Year ib3.Method_num ib3.Serv_num ib1.NACE_num primary
outreg2 using table1.rtf, replace pdec(4) bdec(4) stats(coef se pval) ctitle(Meta-regress)

* Meta-regression with quadratic effect using factor notation
meta regress c.Avscore##c.Avscore ///
    ib1.Perf_num ib2020.Year ib3.Method_num ///
    ib3.Serv_num ib1.NACE_num primary

* Compute turning point
nlcom -_b[Avscore] / (2*_b[c.Avscore#c.Avscore])

* Predicted values across the observed range of Avscore
margins, at(Avscore=(0(5)100)) atmeans

* Plot the quadratic relationship with confidence intervals
marginsplot, recast(line) recastci(rarea) ///
    ytitle("Predicted Outcome") ///
    xtitle("Global Digitalization Index") ///
    title("Quadratic Effect of Global Digitalization")

/*este esta interesante, parece que hay un maximo del efecto mas o menos en 2022 y luego baja otra vez*/
/* Podria ser posible encontrar el ano en que los datos se coleccionan en lugar del ano de publicacion? */

** Modelo multinivel - habria que hacer el meta regress como estandar - y el mixed como robustness. El mixed no es propiamente un meta-analisis, pero permite controlar por el efecto de ser el mismo estudio.

mixed Effectsize || No: || Obs:
xi: mixed Effectsize Avscore Avscore_sq ib1.Perf_num ib2020.Year ib3.Method_num ib3.Serv_num ib1.NACE_num primary || No: || Obs:
outreg2 using table1.rtf, pdec(4) bdec(4) stats(coef se pval) ctitle(Multi-level)

