set search_path to mimiciii;



-- HERE EXTRACT LAB RESULTS

DROP TABLE IF EXISTS D_lab CASCADE;
CREATE TABLE D_lab AS
SELECT
le.hadm_id
  ,avg(CASE WHEN itemid = 51006 and valuenum between 0 and 10000 THEN valuenum ELSE null END) as UREA
  ,avg(CASE WHEN itemid = 50960 and valuenum between 0 and 10000 THEN valuenum ELSE null END) as MAGNESIUM  
  ,avg(CASE WHEN itemid = 50893 and valuenum between 0 and 10000 THEN valuenum ELSE null END) as CALCIUM  
  
  , avg(CASE WHEN itemid = 50868 and valuenum between 0 and 10000 THEN valuenum ELSE null END) as ANIONGAP
  , avg(CASE WHEN itemid = 50862 and valuenum between 0 and 10 THEN valuenum ELSE null END) as ALBUMIN
  , avg(CASE WHEN itemid = 51144 and valuenum between 0 and 100 THEN valuenum ELSE null END) as BANDS
  , avg(CASE WHEN itemid = 50882 and valuenum between 0 and 10000 THEN valuenum ELSE null END) as BICARBONATE
  
  , avg(case when itemid = 50804 and valuenum > 0 then valuenum else null end) as TOTALCO2
  , avg(case when itemid = 50805 and valuenum > 0 then valuenum else null end) as CARBOXYHEMOGLOBIN


  , avg(CASE WHEN itemid = 50885 and valuenum between 0 and 150 THEN valuenum ELSE null END) as BILIRUBIN
  , avg(CASE WHEN itemid = 50912 and valuenum between 0 and 150 THEN valuenum ELSE null END) as CREATININE
  , avg(CASE WHEN itemid = 50806 and valuenum between 0 and 10000 THEN valuenum ELSE null END) as CHLORIDE
  , avg(CASE WHEN itemid in (50809,50931) and valuenum between 0 and 10000 THEN valuenum ELSE null END) as GLUCOSE
  , avg(CASE WHEN itemid in (50810,51221) and valuenum between 0 and 100 THEN valuenum ELSE null END) as HEMATOCRIT
  , avg(CASE WHEN itemid in (50811,51222) and valuenum between 0 and 50 THEN valuenum ELSE null END) as HEMOGLOBIN
  , avg(CASE WHEN itemid = 50813 and valuenum between 0 and 50 THEN valuenum ELSE null END) as LACTATE

  , avg(case when itemid = 50815 and valuenum > 0 and valuenum <=  70 then valuenum else null end) as O2FLOW

  , avg(CASE WHEN itemid = 51265 and valuenum between 0 and 10000 THEN valuenum ELSE null END) as PLATELET
  , avg(CASE WHEN itemid in (50822,50971) and valuenum between 0 and 30 THEN valuenum ELSE null END) as POTASSIUM
  , avg(CASE WHEN itemid = 51275 and valuenum between 0 and 150 THEN valuenum ELSE null END) as PTT
  , avg(CASE WHEN itemid = 51237 and valuenum between 0 and 50 THEN valuenum ELSE null END) as INR
  , avg(CASE WHEN itemid = 51274 and valuenum between 0 and 150 THEN valuenum ELSE null END) as PT
  , avg(CASE WHEN itemid in (50824,50983) and valuenum between 0 and 200 THEN valuenum ELSE null end) as SODIUM
  , avg(case when itemid = 50825 and valuenum > 0 then valuenum else null end) as TEMPERATURE
  , avg(case when itemid = 50826 and valuenum > 0 then valuenum else null end) as TIDALVOLUME
  , avg(case when itemid = 50827 and valuenum > 0 then valuenum else null end) as VENTILATIONRATE
  , avg(CASE WHEN itemid = 51006 and valuenum between 0 and 300 THEN valuenum ELSE null end) as BUN
  , avg(CASE WHEN itemid in (51300,51301) and valuenum between 0 and 1000 THEN valuenum ELSE null end) as WBC
    
  FROM labevents le
  where hadm_id IS NOT NULL and valuenum IS NOT NULL
  GROUP BY le.hadm_id
  ORDER BY le.hadm_id,le.charttime

 
 -- GET ALL CHARTED DATA
 
DROP TABLE IF EXISTS D_ce CASCADE;
CREATE TABLE D_ce AS
SELECT
ce.icustay_id
  , avg(case when itemid in (211,220045) and valuenum > 0 and valuenum < 300 then valuenum else null end) as HeartRate
  , avg(case when itemid in (51,442,455,6701,220179,220050) and valuenum > 0 and valuenum < 400 then valuenum else null end) as SysBP
  , avg(case when itemid in (8368,8440,8441,8555,220180,220051) and valuenum > 0 and valuenum < 300 then valuenum else null end) as DiasBP
  , avg(case when itemid in (456,52,6702,443,220052,220181,225312) and valuenum > 0 and valuenum < 300 then valuenum else null end) as MeanBP
  , avg(case when itemid in (615,618,220210,224690) and valuenum > 0 and valuenum < 70 then valuenum else null end) as RespRate
  , avg(case when itemid in (223761,678) and valuenum > 70 and valuenum < 120 then (valuenum-32)/1.8 -- converted to degC in valuenum call
     when itemid in (223762,676) and valuenum > 10 and valuenum < 50  then valuenum else null end) as TempC
  , avg(case when itemid in (646,220277) and valuenum > 0 and valuenum <= 100 then valuenum else null end) as SpO2
  , avg(case when itemid in (807,811,1529,3745,3744,225664,220621,226537) and valuenum > 0 then valuenum else null end) as Glucose
    
  FROM chartevents ce
  where valuenum IS NOT NULL AND valuenum >0
  group by ce.icustay_id
  order by ce.icustay_id;
    
set search_path to mimiciii;



set search_path to mimiciii;
DROP TABLE IF EXISTS D_vita CASCADE;
CREATE TABLE D_vita AS

with ce as
(
select ce.icustay_id
,date_trunc('hour', min(charttime)+interval '59' minute) as intime_hr
,date_trunc('hour',max(charttime)+interval '59' minute) as outtime_hr

from chartevents ce
inner join icustays ie 
on ce.icustay_id=ie.icustay_id
and ce.charttime>ie.intime - interval '12' hour
and ce.charttime<ie.outtime + interval '12' hour
where itemid in (211,220045) -- heartrate
group by ce.icustay_id
)

SELECT

    ie.subject_id, ie.hadm_id,ie.icustay_id
    ,round((cast (ad.admittime as date)-cast(pat.dob as date))/365,3) as age
    ,case when pat.gender ='M' then 1 else 0 end as male_flag
  ,case when ad.ADMISSION_TYPE IN ('URGENT','EMERGENCY') THEN 1 ELSE 0 END AS emergency_admission
    
 , case when ad.ethnicity in
 (
    'WHITE' --  40996
  , 'WHITE - RUSSIAN' --    164
 , 'WHITE - OTHER EUROPEAN' --     81
 , 'WHITE - BRAZILIAN' --     59
 , 'WHITE - EASTERN EUROPEAN' --     25
 ) then 1 else 0 end as Ethnic_white

    ,case when ad.ethnicity in 
    (
        'BLACK/AFRICAN AMERICAN' 
      , 'BLACK/CAPE VERDEAN' 
      , 'BLACK/HAITIAN' 
      , 'BLACK/AFRICAN' 
      , 'CARIBBEAN ISLAND' 
  ) then 1 else 0 end as Ethnic_black
  
   , case when ad.ethnicity in
  (
    'HISPANIC OR LATINO' 
  , 'HISPANIC/LATINO - PUERTO RICAN' 
  , 'HISPANIC/LATINO - DOMINICAN' 
  , 'HISPANIC/LATINO - GUATEMALAN' 
  , 'HISPANIC/LATINO - CUBAN' 
  , 'HISPANIC/LATINO - SALVADORAN' 
  , 'HISPANIC/LATINO - CENTRAL AMERICAN (OTHER)' 
  , 'HISPANIC/LATINO - MEXICAN' 
  , 'HISPANIC/LATINO - COLOMBIAN' 
  , 'HISPANIC/LATINO - HONDURAN' 
  ) then 1 else 0 end as Ethnic_hispanic

   , case when ad.ethnicity in
  (
      'ASIAN' --   1509
    , 'ASIAN - CHINESE' --    277
    , 'ASIAN - ASIAN INDIAN' --     85
    , 'ASIAN - VIETNAMESE' --     53
    , 'ASIAN - FILIPINO' --     25
    , 'ASIAN - CAMBODIAN' --     17
    , 'ASIAN - OTHER' --     17
    , 'ASIAN - KOREAN' --     13
    , 'ASIAN - JAPANESE' --      7
    , 'ASIAN - THAI' --      4
  ) then 1 else 0 end as Ethnic_asian
  , case when ad.ethnicity in
  (

      'UNKNOWN/NOT SPECIFIED' --   4523
    , 'OTHER' --   1512
    , 'UNABLE TO OBTAIN' --    814
    , 'PATIENT DECLINED TO ANSWER' --    559
    , 'MULTI RACE ETHNICITY' --    130
    , 'PORTUGUESE' --     61
    , 'AMERICAN INDIAN/ALASKA NATIVE' --     51
    , 'MIDDLE EASTERN' --     43
    , 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' --     18
    , 'SOUTH AMERICAN' --      8
    , 'AMERICAN INDIAN/ALASKA NATIVE FEDERALLY RECOGNIZED TRIBE' --      3
  ) then 1 else 0 end as Ethnic_other
  
    ,ad.HOSPITAL_EXPIRE_FLAG
    ,ie.los as icu_los
    ,extract(epoch from (ad.dischtime-ad.admittime))/60/60/24 as hosp_los
    
    -- set up flags to exclude some entries
    , case when round((cast(ad.admittime as date)-cast(pat.dob as date))/365,4)<18 then 1     
    when ad.HAS_CHARTEVENTS_DATA=0 THEN 1
    WHEN ie.intime is null then 1
    when ie.outtime is null then 1
    when ce.intime_hr is null then 1
    when ce.outtime_hr is null then 1
    when (ce.outtime_hr-ce.intime_hr) <=interval '4' hour then 1
    when ((lower(diagnosis) like '%organ donor%' and deathtime is not null)
    or (lower(diagnosis) like '%donor account%' and deathtime is not null)) then 1
    else 0 end as exclusion_flag
    
    from icustays ie
    inner join admissions ad
    on ie.hadm_id=ad.hadm_id
    inner join patients pat
    on ie.subject_id=pat.subject_id
    left join ce
    on ie.icustay_id=ce.icustay_id


    
DROP TABLE IF EXISTS D_urineout CASCADE;
CREATE TABLE D_urineout AS

SELECT
icustay_id
,sum(UrineOutput) as UrineOutput
from
(
select vt.icustay_id
  
,case when oe.itemid =227489 then -1*oe.value
else oe.value end as UrineOutput
from D_vita vt
  
inner join outputevents oe
  on vt.icustay_id=oe.icustay_id
where oe.iserror IS DISTINCT FROM 1
AND vt.exclusion_flag =0
and itemid in 
(
  -- these are the most frequently occurring urine output observations in CareVue
  40055, -- "Urine Out Foley"
  43175, -- "Urine ."
  40069, -- "Urine Out Void"
  40094, -- "Urine Out Condom Cath"
  40715, -- "Urine Out Suprapubic"
  40473, -- "Urine Out IleoConduit"
  40085, -- "Urine Out Incontinent"
  40057, -- "Urine Out Rt Nephrostomy"
  40056, -- "Urine Out Lt Nephrostomy"
  40405, -- "Urine Out Other"
  40428, -- "Urine Out Straight Cath"
  40086,--  Urine Out Incontinent
  40096, -- "Urine Out Ureteral Stent #1"
  40651, -- "Urine Out Ureteral Stent #2"

  -- these are the most frequently occurring urine output observations in CareVue
  226559, -- "Foley"
  226560, -- "Void"
  226561, -- "Condom Cath"
  226584, -- "Ileoconduit"
  226563, -- "Suprapubic"
  226564, -- "R Nephrostomy"
  226565, -- "L Nephrostomy"
  226567, --  Straight Cath
  226557, -- R Ureteral Stent
  226558, -- L Ureteral Stent
  227488, -- GU Irrigant Volume In
  227489  -- GU Irrigant/Urine Volume Out
  )
)v1
group by v1.icustay_id
order by v1.icustay_id


set search_path to mimiciii;

DROP TABLE IF EXISTS D_total CASCADE;
CREATE TABLE D_total AS

select 
vt.subject_id
,vt.hadm_id
,vt.icustay_id

,vt.male_flag
,vt.emergency_admission
,vt.Ethnic_other
,vt.Ethnic_asian
,vt.Ethnic_hispanic
,vt.Ethnic_black
,vt.Ethnic_white
,vt.HOSPITAL_EXPIRE_FLAG
,vt.age
,vt.icu_los
,vt.hosp_los

,ce.heartrate
,ce.SysBP
,ce.DiasBP
,ce.MeanBP
,ce.RespRate
,ce.SpO2
,ce.Glucose

,uo.UrineOutput

,lab.UREA
,lab.MAGNESIUM
,lab.CALCIUM
,lab.ANIONGAP
,lab.ALBUMIN
,lab.BANDS
,lab.BICARBONATE
,lab.TOTALCO2
,lab.CARBOXYHEMOGLOBIN
,lab.BILIRUBIN
,lab.CREATININE
,lab.CHLORIDE
,lab.HEMATOCRIT
,lab.HEMOGLOBIN
,lab.LACTATE
,lab.O2FLOW
,lab.PLATELET
,lab.POTASSIUM
,lab.PTT
,lab.INR
,lab.PT
,lab.SODIUM
,lab.TIDALVOLUME
,lab.VENTILATIONRATE
,lab.BUN
,lab.WBC


, coalesce(lab.TEMPERATURE, ce.TempC) as tempc
, coalesce(lab.GLUCOSE,ce.Glucose) as glucose

,saps.saps
,sapsii.sapsii
 
from d_vita vt
left join d_ce ce
  on  vt.icustay_id = ce.icustay_id
left join d_urineout uo
  on  vt.icustay_id = uo.icustay_id
left join d_lab lab
  on  vt.hadm_id = lab.hadm_id
left join saps
  on vt.icustay_id=saps.icustay_id
left join sapsii
  on vt.icustay_id=sapsii.icustay_id
    where vt.exclusion_flag=0
order by vt.subject_id, vt.hadm_id, vt.icustay_id;

