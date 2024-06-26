*! version 2.1 abuxton 23sep2007. 23Oct2013
*! cureregr8, version 8.2 cure model regression or parametric cure model PCM
* 16jan2005 (on 24dec2004) save 'e(predict)' gets '_cureregr' predict will pass control to _cureregr.ado
* 07nov2004 to add capacity to work with multiple records subject with contiguous intervals & tvc
* 01oct2004 share initial cureregr.ado

program cureregr8
version 8.2
local cmdstr `"`0'"'
        if replay() & `"`e(cmd)'"' == "cureregr8" {
                /*di `"hello here we are prior to qui capture Replay"'*/
                qui capture {
                        Replay `cmdstr'
                }
                if _rc==0 {
                /*di `"hello here we are prior to Replay"'*/
                        Replay `cmdstr'
                }
                else {
                /*di `"hello here we are prior to Replay->estimate again?"'*/
                        Estimate `cmdstr'
                }
        }
        else {
        /*di `"hello here we are prior to estimate directly"'*/
        Estimate `cmdstr'
        }
end
/*(default=none)*/
program Estimate, eclass
         local oktype = cond(`c(stata_version)' < 9,                      ///
                 "integer `c(level)'", "cilevel")
        st_is 2 analysis                                // on ver2
        syntax  [varlist(default=none)] [if] [in]        ///
                [,                             ///
                Distribution_option(string)    ///
                Class_option(string)           ///
                LInk_option(string)            ///
                SCale_model(varlist)           ///
                SHape_model(varlist)           ///
                Noconstant                     ///
                scale_noc                      ///
                shape_noc                      ///
                LEFTcensor                     ///
                noDESCriptionmodel             ///
                noSHow                         ///
                noLOg                          ///
                noLRTEST                       ///
                Level(cilevel)                 ///
                *                              ///
                ]

/* bgn snytax check */
        local distopt `"`distribution_option'"'
        local clssopt `"`class_option'"'
        local linkopt `"`link_option'"'
        local linkvlst_n : word count `varlist'
        if `linkvlst_n' >= 1 {
                local flagA=1
                }
                else  {
                local flagA=0
                }

        local scale_model_n : word count `scale_model'
        if `scale_model_n' >= 1 {
                local flagB=1
                }
                else {
                local flagB=0
                }

        local shape_model_n : word count `shape_model'
        if `shape_model_n' == 1 {
                local flagC=1
                }
                else  {
                local flagC=0
                }

/* shall the full model step be attemped */
if `flagA'==0 & `flagB'==0 & `flagC'==0 {
        local fmcontin 0
}
else {
        local fmcontin 1
}

        local temp0 : word count `distopt'
        /*display `"`temp0'"'*/
        if `temp0' == 1 {
                if lower(substr(`"`distopt'"',1,4)) == `"logi"' {
                local kernal_dist = `"logistic"'
                local krn = `"03"'
                }
                else if lower(substr(`"`distopt'"',1,1)) == `"w"' {
                local kernal_dist = `"weibull"'
                local krn = `"01"'
                }
                else if lower(substr(`"`distopt'"',1,4)) == `"logn"' {
                local kernal_dist = `"lognormal"'
                local krn = `"02"'
                }
                else if lower(substr(`"`distopt'"',1,4)) == `"gamm"' {
                local kernal_dist = `"gamma"'
                local krn = `"04"'
                }
                else if lower(substr(`"`distopt'"',1,3)) == `"exp"' {
                local kernal_dist = `"exponential"'
                local krn = `"05"'
                }
                else {
                display `"unrecognized distribution (kernal)"'
                display `"recognized: (weibull | lognormal | logistic | gamma | exponential)"'
                error 197
                }
        }
        else if `temp0' > 1 {
                display `"too many specifications for distribution (kernal) option"'
                display `"recognized: (weibull | lognormal | logistic | gamma | exponential)"'
                error 197
        }
        else if `temp0' == 0 {
                local kernal_dist = `"weibull"'                                 /* default == weibull*/
                local krn = `"01"'
                }
        else {
                error 199
                }

        local temp0 : word count `clssopt'
        /*display `"`temp0'"'*/
        if `temp0' == 1 {
                /* mixture */
                if lower(substr(`"`clssopt'"',1,1)) == `"m"' {
                local clss_func = `"mixture"'
                local lnl = `"00"'
                }
                /* non-mixture */
                else if lower(substr(`"`clssopt'"',1,1)) == `"n"' {
                local clss_func = `"non_mixture"'
                local lnl = `"01"'
                }
                else {
                display `"unrecognized class (or kernal), class(), function"'
                display `"recognized: (mixture | non-mixture)"'
                error 197
                }
        }
        else if `temp0' > 1 {
                display `"too many specifications for class (or kernal), class() function"'
                display `"recognized: (mixture | non-mixture)"'
                error 197
        }
        else if `temp0' == 0 {
                local clss_func = `"mixture"'                                   /* default == mixture*/
                local lnl = `"00"'
                }
        else {
                error 199
                }

        local temp0 : word count `linkopt'
        /*display `"`temp0'"'*/
        if `temp0' == 1 {
                /* linear */
                if lower(substr(`"`linkopt'"',1,3)) == `"lin"' {
                local link_func = `"linear"'
                local cfl = `"03"'
                }
                /* log-minus-log */
                else if lower(substr(`"`linkopt'"',1,3)) == `"lml"' {
                local link_func = `"lml"'
                local cfl = `"02"'
                }
                /* logistic */
                else if lower(substr(`"`linkopt'"',1,4)) == `"logi"' {
                local link_func = `"logistic"'
                local cfl = `"01"'
                }
                else {
                display `"unrecognized cure-fraction-link, link(), function"'
                display `"recognized: (logistic | lml, log-minus-log | linear)"'
                error 197
                }
        }
        else if `temp0' > 1 {
                display `"too many specifications for cure-fraction-link, link(), function"'
                display `"recognized: (logistic | lml, log-minus-log | linear)"'
                error 197
        }
        else if `temp0' == 0 {
                local link_func = `"logistic"'                                  /* default == logistic*/
                local cfl = `"01"'
                }
        else {
                error 199
                }

        /* option noconstant, cure-fraction-model */
        if `"`noconstant'"'==`"noconstant"' &  `flagA' == 1 {
                local noconstant1 1
                local cf_schema `"`varlist'"'
                }
        else if `flagA' == 0 {
                local noconstant1=.
                local cf_schema `"cons"'
                }
        else {
                local noconstant1 0
                local cf_schema `"cons `varlist'"'
                }

        /* option noconstant scale */
        if `"`scale_noc'"'==`"scale_noc"' & `flagB' == 1 {
                local scale_noc1 1
                local sc_schema `"`scale_model'"'
                }
        else if `flagB' == 0 {
                local scale_noc1 = .
                local sc_schema `"cons"'
                }
        else {
                local scale_noc1 0
                local sc_schema `"cons `scale_model'"'
                }

        /* option noconstant shape */
        if `"`shape_noc'"'==`"shape_noc"' & `flagC' == 1 {
                local shape_noc1 1
                local sh_schema `"`shape_model'"'
                }
        else if `flagC' == 0 {
                local shape_noc1 = .
                local sh_schema `"cons"'
                }
        else {
                local shape_noc1 0
                local sh_schema `"cons `shape_model'"'
                }

        /* option leftcensor */                                         //on ver2
        if `"`leftcensor'"'==`""' {
                local left_cr = 0
                }
        else if `"`leftcensor'"'==`"leftcensor"' {
                local left_cr = 1
                }
                if `left_cr' == 0 {
                        local leftcensortxt = `""'
                        }
                else if `left_cr' == 1 {
                        local leftcensortxt = `", {res}leftcensor{txt}: in e(depvar) _leftd"'
                }

        /* option nodescriptionmodel */
        if `"`descriptionmodel'"'==`""' {
                local nodesc_cr 0
                }
        else if `"`descriptionmodel'"'==`"nodescriptionmodel"' {
                local nodesc_cr 1
                }

        /* option noshow */
        if `"`show'"'==`""' {
                local noshow_cr 0
                }
        else if `"`show'"'==`"noshow"' {
                local noshow_cr 1
                }

/*      display `" link model list:            "'   `"`varlist'"'           */
/*      display `" T|F noconstant link :       "'   `"`noconstant1'"'       */
/*      display `" cure fraction model SCHEMA: "'   `"`cf_schema'"'         */
/*      display `" scale model list:           "'   `"`scale_model'"'       */
/*      display `" T|F noconstant scale:       "'   `"`scale_noc1'"'        */
/*      display `" scale model SCHEMA:         "'   `"`sc_schema'"'         */
/*      display `" shape model list:           "'   `"`shape_model'"'       */
/*      display `" T|F noconstant shape:       "'   `"`shape_noc1'"'        */
/*      display `" shape model SCHEMA:         "'   `"`sh_schema'"'         */
/*      display `" cf distribution option:     "'   `"`distopt'"'           */
/*      display `" cf distribution actual:     "'   `"`kernal_dist'"'       */
/*      display `" class option:               "'   `"`clssopt'"'           */
/*      display `" class actual:               "'   `"`clss_func'"'         */
/*      display `" link option:                "'   `"`linkopt'"'           */
/*      display `" link actual:                "'   `"`link_func'"'         */
/*      display `" T|F leftcensor:             "'   `"`left_cr'"'           */
/*      display `"nodescriptionmodel:          "'   `"`nodesc_cr'"'         */
/*      display `"noshow:                      "'   `"`noshow_cr'"'         */


/* end snytax check */

tempvar sortstore
qui gen `sortstore' = _n

        // check syntax
        mlopts mlopts, `options'
        local cns `s(constraints)'                      // for future reference -- constraints.

        if "`log'" != "" {
                local qui quietly
        }
        // mark the estimation sample
        marksample touse
        qui replace `touse' = 0 if _st==0               // on ver2
        markout `touse'

/* bgn define left censor status and internal subject id */

        tempname varlcensor                                             // on ver2, left censor variable indication on last digit of event list
        qui gen `varlcensor'=0 if `touse'                                       //with `touse'
        local stfl ="`_dta[st_bd]'"'
        if `"`_dta[st_ev]'"' ~= `""' {
        *di `"`_dta[st_ev]'"'
                tokenize `_dta[st_ev]'
                local temp0 : word count `_dta[st_ev]'
                local temp1 : word `temp0' of `_dta[st_ev]'
        *di `"`temp0'"'                         // event list count of number codes
        *di `"`temp1'"'                         // event list string with last code
        if `"`stfl'"' == `""' {
                qui replace `varlcensor'=0 if `touse'
                }
        else {
                if `left_cr'==0 {
                        qui replace `varlcensor'=0 if `touse'
                        }
                else if `left_cr'==1 {
                        qui replace `varlcensor'=(`stfl' == `temp1') if `touse'
                        }
                }
        }
        else if `"`stfl'"' ~= `""' {
                qui summarize `stfl' ,detail
                local temp0 = `r(max)'
                if `left_cr'==0 {
                        qui replace `varlcensor'=0 if `touse'
                        }
                else if `left_cr'==1 {
                        qui replace `varlcensor'= (`stfl' == `temp0') if `touse'
                        }
                }
        else {
                di `"{err}cureregr8 does model a fraction surviving & all subjects (assumed) to end in failure{txt}"'
                di `"{err}as 'failure()' was not specified in stset, please reconsider.{txt}"'
                exit
        }
        tempname varid                          // on ver2, variable_id is internal sure to exist id
        local stid ="`_dta[st_id]'"'
        if `"`stid'"' == `""' {
                qui gen `varid'=_n if `touse'
                }
        else {
                qui capture confirm numeric variable `stid'
                local numericstid = _rc
                        if `numericstid'==0 {
                                qui gen `varid'=`stid' if `touse'
                                }
                        else if `numericstid'~=0 {
                                qui capture confirm string variable `stid'
                                local stringstid = _rc
                                if `stringstid'==0 {
                                        encode  `stid' if `touse' , gen(`varid')
                                }
                                else {
                                        di `"{err} id var exists and is not string or numeric? cureregr8 prefers numeric.{txt}"'
                                        exit
                                }
                        }
                }
        tempvar varfirst
        bysort `varid': gen `varfirst' = _n
        qui summarize `varid' if `varfirst'==1, detail
        local subjectn = `r(N)'
/* end define left censor status and internal subject id */
qui display `"{txt}==== ==== ==== ==== ===="'
        /* bgn check ml arguments concerning constant or not */
                if `noconstant1' == 1 & `"`varlist'"' ~= `""' {
                        local cure_frac_constant = `", noconstant"'
                        qui di `"{txt}0-- (cure_frac: _t _d = `varlist' `cure_frac_constant')"'
                        }
                        else if `noconstant1' == 0 & `"`varlist'"' == `""' {
                        qui di `"{txt}0-- (cure_frac: _t _d = _cons)"'
                        }
                        else  {
                        local cure_frac_constant = `""'
                        qui di `"{txt}1-- (cure_frac: _t _d = `varlist' `cure_frac_constant')"'
                        }
                if `scale_noc1' == 1 & `"`scale_model'"' ~= `""' {
                        local scale_constant = `", noconstant"'
                        qui di `"{txt}0-- (scale: `scale_model' `scale_constant')"'
                        }
                        else  {
                        local scale_constant = `""'
                        qui di `"{txt}1-- (scale: `scale_model' `scale_constant')"'
                        }
                if `shape_noc1' == 1 & `"`shape_model'"' ~= `""' {
                        local shape_constant = `", noconstant"'
                        qui di `"{txt}0-- (shape: `shape_model' `shape_constant')"'
                        }
                        else  {
                        local shape_constant = `""'
                        qui di `"{txt}1-- (shape: `shape_model' `shape_constant')"'
                        }
        /* end check ml arguments concerning constant or not */

/* fit model */

        /*bgn  calculate the initial value */
                tempvar km_est
                qui sts gen `km_est' = s if `touse'
                qui summarize `km_est',detail
                local pi_est = r(min)
                if `pi_est' > 0.005 & `pi_est' < 0.995 {
                        }
                else if `pi_est' <= 0.005 {
                        local pi_est=0.005
                        }
                else if `pi_est' >= 0.995 {
                        local pi_est=0.995
                        }
                else {
                        display `"big pi_est problem: `pi_est'"'
                        local pi_est=0.5
                }
                if              `"`link_func'"' == `"linear"' {
                        local cf_est = `pi_est'
                        }
                else if `"`link_func'"' == `"lml"' {
                        local cf_est = ln(-ln(`pi_est'))
                        }
                else if `"`link_func'"' == `"logistic"' {
                        local cf_est = -ln((1/`pi_est')-1)
                        }
                local initopt init(                     ///
                                cure_frac:_cons=`cf_est'         ///
                                scale:_cons=0           ///
                                shape:_cons=0)          ///
                        search(quietly)
        if `"`krn'"' == `"05"' {
                local initopt init(                     ///
                                cure_frac:_cons=`cf_est'         ///
                                scale:_cons=0)                  ///
                        search(quietly)
        }
        /* end calculate the initial value */
        /* bgn non-constant initial values set-up */
                if `"`varlist'"'==`""' {
                        local var_last = `"cure_frac:_cons=`cf_est'"'                   //check init value assign cure_frac
                        }
                else {
                local i=1
                foreach Charx of varlist `varlist' {
                        if `i' == `linkvlst_n' {
                                local var_lastB = `"cure_frac:`Charx'=`cf_est'"'        //check init value assign cure_frac
                                }
                        else {
                                local var_lastB = `"cure_frac:`Charx'=0"'                       //check init value assign cure_frac
                                }
                        local var_last = `"`var_last' `var_lastB'"'
                        local i=`i'+1
                        }
                        }
                if `"`scale_model'"'==`""' {
                        local sc_last = `"scale:_cons=0"'                       //check init value assign scale
                        }
                else {
                local i=1
                foreach Charx of varlist `scale_model' {
                        if `i' == `scale_model_n' {
                                local sc_lastB = `"scale:`Charx'=0"'    //check init value assign scale
                                }
                        else {
                                local sc_LastB = `"scale:`Charx'=0"'
                                }
                        local sc_last = `"`sc_last' `sc_lastB'"'        //check init value assign scale
                        local i=`i'+1
                        }
                        }
                if `"`shape_model'"'==`""' {
                        local sh_last = `"shape:_cons=0"'                       //check init value assign shape
                        }
                else {
                local i=1
                foreach Charx of varlist `shape_model' {
                        if `i' == `shape_model_n' {
                                local sh_lastB = `"shape:`Charx'=0"'    //check init value assign shape
                                }
                        else {
                                local sh_LastB = `"shape:`Charx'=0"'    //check init value assign shape
                                }
                        local sh_last = `"`sh_last' `sh_lastB'"'
                        local i=`i'+1
                        }
                        }
                local initopt_noconst init(             ///
                                `var_last'                              ///
                                `sc_last'                               ///
                                `sh_last')                              ///
                        search(quietly)
        if `"`krn'"' == `"05"' {
                local initopt_noconst init(             ///
                                `var_last'                              ///
                                `sc_last')                              ///
                        search(quietly)
        }
        /* end non-constant initial values set-up */
                /* 00zzzz mixture==class lnl, logLikelihood*/
                /* 01zzzz non-mixture==class */
                /* zz01zz weibull==kernal, krn */
                /* zz02zz lognormal==kernal */
                /* zz03zz logistic==kernal */
                /* zz04zz gamma==kernal */
                /* zz05zz gamma==kernal, shape==1 therefore exponential */
                /* zz06zz lognormal in ln(t), not in ln(tt) as zz02zz is*/
                /* zz07zz lognormal in ln(t) where sigma==1, not in ln(tt) as zz02zz is*/
                /* zzzz01 logistic==cf, cfl, cure fraction link */
                /* zzzz02 lml, logminus log==cf */
                /* zzzz03 linear==cf */
        local pi_est1 = string(`pi_est' , "%5.4f")
        local cf_est1 = string(`cf_est' , "%5.4f")
        local PCMmodelNo = `"`lnl'`krn'`cfl'"'
/* bgn find evaluator exist */
capture {
        qui which PCM`PCMmodelNo'_lf.ado        /* 19oct2004 dev v2 draft censor options evaluators */
        }
        if _rc != 0 {
                        di `"{err}cureregr8 cannot find the evaluator: PCM`PCMmodelNo'_lf.ado{txt}"'
                        exit
                        }
/* end find evaluator exist */
        local titletxt0 `"{txt}cf: {res}`link_func', {txt}kn: {res}`kernal_dist', {txt}model: {res}`clss_func'"'
        local titletxt1 `"{txt}No. of subjects = {res}`subjectn'{txt}"'
        local titletxt `"`titletxt1'"'

if `"`krn'"' ~= `"05"' {
        st_show `show'
        if `nodesc_cr' == 0 {
        if `noshow_cr' == 1 {
        di
        }
        display `"{txt}cf: {res}`link_func', {txt}kn: {res}`kernal_dist', {txt}model: {res}`clss_func'"'
        display `"{txt}cf_initial_coef: `cf_est1' pi: `pi_est1'"'
        /*display `"{txt}b1 evaluator: PCM`PCMmodelNo'_lf`leftcensortxt'{txt}"'*/
        }
        if (((`noconstant1' == 0) | (`noconstant1' == .))&      ///
                ((`scale_noc1' == 0) | (`scale_noc1' == .))&    ///
                ((`shape_noc1' == 0) | (`shape_noc1' == .)))    {       // bgn nocons
                `qui' di as txt _n "Fitting constant-only model:"
                 ml model lf PCM`PCMmodelNo'_lf                 ///
                        (cure_frac: _t _d _t0 `varlcensor' = )  ///
                        (scale: )                               ///
                        (shape: )                               ///
                        if `touse' ,            ///
                        `log'                                   ///
                        `mlopts'                                ///
                        `initopt'                               ///
                        nocnsnotes                              ///
                        missing                                 ///
                        title(`"`titletxt'"')                   ///
                        maximize
                if "`lrtest'" == "" {
                        local contin continue search(off)
                }
                else {
                        tempname b0
                        mat `b0' = e(b)
                        local contin init(`b0') search(off)

                }
                if `fmcontin'==1 {
                `qui' di as txt _n "Fitting full model:"
                }
        }                                                                                                               // end nocons

        if `"`contin'"' == `""' & `fmcontin'==0 {                                                               // bgn continue
        // fit the full model
                 ml model lf PCM`PCMmodelNo'_lf                 ///
                        (cure_frac: _t _d _t0 `varlcensor' = `varlist' `cure_frac_constant')    ///
                        (scale: `scale_model' `scale_constant')                                 ///
                        (shape: `shape_model' `shape_constant')                                 ///
                        if `touse' ,                                                                            ///
                `log'                                   ///
                `mlopts'                                ///
                `robust'                                ///
                `clopt'                                 ///
                `initopt_noconst'               ///
                missing                                 ///
                title(`"`titletxt'"')                   ///
                maximize
                }
        else if `fmcontin'==1 {
        // fit the full model
                 ml model lf PCM`PCMmodelNo'_lf                                                 ///
                        (cure_frac: _t _d _t0 `varlcensor' = `varlist' `cure_frac_constant')    ///
                        (scale: `scale_model' `scale_constant')                                 ///
                        (shape: `shape_model' `shape_constant')                                 ///
                        if `touse' ,                                                                            ///
                `log'                                   ///
                `mlopts'                                ///
                `robust'                                ///
                `clopt'                                 ///
                `contin'                                ///
                missing                                 ///
                title(`"`titletxt'"')   ///
                maximize
                }                                                                                                       // end continue

        if `left_cr' == 1 {
        capture confirm variable _leftd
                if _rc ==0 {
                        capture confirm variable numeric _leftd
                        if _rc==0 {
                        qui replace _leftd=`varlcensor'
                        qui recast byte _leftd
                        }
                        else {
                                qui drop _leftd
                                qui gen byte _leftd=`varlcensor'
                                }
                        }
                else {
                        qui gen byte _leftd=`varlcensor'
                        }
                ereturn local depvar "_t _d _t0 _leftd"
                }
        else {
                if `left_cr' ==0 {
                        capture confirm variable _leftd
                        if _rc==0 {
                                qui drop _leftd
                                }
                        }
                ereturn local depvar "_t _d _t0"
                }

        ereturn local cmd cureregr8
        ereturn local predict _cureregr8
        ereturn local varlist "`varlist' `scale_model' `shape_model'"

        Replay , level(`level')
        }
else if `"`krn'"' == `"05"' {                           // krn==05, exponential
        st_show `show'
        if `nodesc_cr' == 0 {
        if `noshow_cr' == 1 {
        di
        }
        display `"{txt}cf: {res}`link_func', {txt}kn: {res}`kernal_dist', {txt}model: {res}`clss_func'"'
        display `"{txt}cf_initial_coef: `cf_est1' pi: `pi_est1'"'
        /*display `"{txt}evaluator: PCM`PCMmodelNo'_lf`leftcensortxt'{txt}"'*/
        }
        if (((`noconstant1' == 0) | (`noconstant1' == .))&      ///
                ((`scale_noc1' == 0) | (`scale_noc1' == .))     ///
                )       {       // bgn nocons
                `qui' di as txt _n "Fitting constant-only model:"
                 ml model lf PCM`PCMmodelNo'_lf                 ///
                        (cure_frac: _t _d _t0 `varlcensor' = )  ///
                        (scale: )                               ///
                                                                        ///
                        if `touse' ,            ///
                        `log'                                   ///
                        `mlopts'                                ///
                        `initopt'                               ///
                        nocnsnotes                              ///
                        missing                                 ///
                        title(`"`titletxt'"')                   ///
                        maximize
                if "`lrtest'" == "" {
                        local contin continue search(off)
                }
                else {
                        tempname b0
                        mat `b0' = e(b)
                        local contin init(`b0') search(off)

                }
                if `fmcontin'==1 {
                `qui' di as txt _n "Fitting full model:"
                }
        }                                                                                                               // end nocons

if `"`contin'"' == `""' & `fmcontin'==0 {                                                               // bgn continue
        // fit the full model
                 ml model lf PCM`PCMmodelNo'_lf                 ///
                        (cure_frac: _t _d _t0 `varlcensor' = `varlist' `cure_frac_constant')    ///
                        (scale: `scale_model' `scale_constant')                                 ///
                                                                                                                                        ///
                        if `touse' ,                                                                            ///
                `log'                                   ///
                `mlopts'                                ///
                `robust'                                ///
                `clopt'                                 ///
                `initopt_noconst'               ///
                missing                                 ///
                title(`"`titletxt'"')                   ///
                maximize
                }
        else if `fmcontin'==1 {
        // fit the full model
                 ml model lf PCM`PCMmodelNo'_lf                                                 ///
                        (cure_frac: _t _d _t0 `varlcensor' = `varlist' `cure_frac_constant')    ///
                        (scale: `scale_model' `scale_constant')                                 ///
                                                                                                                                        ///
                        if `touse' ,                                                                            ///
                `log'                                   ///
                `mlopts'                                ///
                `robust'                                ///
                `clopt'                                 ///
                `contin'                                ///
                missing                                 ///
                title(`"`titletxt'"')   ///
                maximize
                }                                                                                                       // end continue

        if `left_cr' == 1 {
        capture confirm variable _leftd
                if _rc ==0 {
                        capture confirm variable numeric _leftd
                        if _rc==0 {
                        qui replace _leftd=`varlcensor'
                        qui recast byte _leftd
                        }
                        else {
                                qui drop _leftd
                                qui gen byte _leftd=`varlcensor'
                                }
                        }
                else {
                        qui gen byte _leftd=`varlcensor'
                        }
                ereturn local depvar "_t _d _t0 _leftd"
                }
        else {
                if `left_cr' ==0 {
                        capture confirm variable _leftd
                        if _rc==0 {
                                qui drop _leftd
                                }
                        }
                ereturn local depvar "_t _d _t0"
                }

        ereturn local cmd cureregr8
        ereturn local predict _cureregr8
        ereturn local varlist `"`varlist' `scale_model'"'

        Replay , level(`level')
        }
qui sort `sortstore'
end

program Replay
         local oktype = cond(`c(stata_version)' < 9, ///
                 "integer `c(level)'", "cilevel")
        syntax  [, Level(`oktype') ]
        ml display , level(`level')
end

