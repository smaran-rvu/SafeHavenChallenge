// Let's create a core "risk" file that the county code (FIPS) and the primary city.
// We can extra ct this data from the Cities file.

// #OPTION('obfuscateOutput',True);
IMPORT $, STD;
IMPORT Visualizer;
CityDS := $.File_AllData.City_DS;
Crime  := $.File_AllData.CrimeDS;
UNEMP     := $.File_AllData.unemp_byCountyDS;
EDU       := $.File_AllData.EducationDS;
POVTY     := $.File_AllData.pov_estimatesDS;
GUNV      := $.File_AllData.GunViolenceDS;
fipsRec := RECORD
    UNSIGNED3 county_fips;
END;
fipsInfo := PROJECT(CityDS, fipsRec);

// Declare our core RECORD:
RiskRec := RECORD
    STRING45  city;
    STRING2   state_id;
    STRING20  state_name;
    UNSIGNED3 county_fips;
    STRING30  county_name;
END;

BaseInfo := PROJECT(CityDS,RiskRec);
OUTPUT(BaseInfo,NAMED('BaseData'));

RiskPlusRec := RECORD
 BaseInfo;
 IlliteracyScore  := 0.0;
 PovertyScore    := 0.0;
 CrimeScore      := 0.0;
 GunViolenceScore := 0.0,
 UnemploymentScore := 0.0,
 Total           := 0.0;
END; 
 
RiskTbl := TABLE(BaseInfo,RiskPlusRec);

//Let's add a Crime Score!

CrimeRec := RECORD
    CrimeRate := TRUNCATE((INTEGER)Crime.crime_rate_per_100000);
    // Getting values of different crimes per 1000 people
    MurderPer1000 := (INTEGER)Crime.murder * 1000 / (INTEGER)Crime.population;
    RapePer1000 := (INTEGER)Crime.rape * 1000 / (INTEGER)Crime.population;
    RobberyPer1000 := (INTEGER)Crime.robbery * 1000 / (INTEGER)Crime.population;
    AssltPer1000 := (INTEGER)Crime.AGASSLT * 1000 / (INTEGER)Crime.population;
    LarcenyPer1000 := (INTEGER)Crime.larceny * 1000 / (INTEGER)Crime.population;
    TheftPer1000 := (INTEGER)Crime.mvtheft * 1000 / (INTEGER)Crime.population;
    // Burgleries and Arson can be ignored since they affect residents more than travellers
    // BurgleriesPer1000 := (INTEGER)Crime.Burglry * 1000 / (INTEGER)Crime.population;
    // ArsonPer1000 := (INTEGER)Crime.arson * 1000 / (INTEGER)Crime.population;
    Crime.fips_st;
    fips_cty := (INTEGER)Crime.fips_cty;
    Fips := Crime.fips_st + INTFORMAT(Crime.fips_cty,3,1);
END;

CrimeTbl := TABLE(Crime,CrimeRec);

JoinCrime := JOIN(CrimeTbl,RiskTbl,
                  LEFT.fips = (STRING)RIGHT.county_fips,
                  TRANSFORM(RiskPlusRec,
                            SELF.CrimeScore := LEFT.crimerate * 0.01 * (
                                                                    (Left.MurderPer1000 * 0.4) + 
                                                                    (Left.RapePer1000 * 0.3) + 
                                                                    (Left.RobberyPer1000 * 0.1) + 
                                                                    (Left.AssltPer1000 * 0.1) +
                                                                    (Left.LarcenyPer1000 * 0.05) + 
                                                                    (Left.TheftPer1000 * 0.05)
                                                                ),
                            SELF            := RIGHT),
                            RIGHT OUTER);
                            
OUTPUT(SORT(JoinCrime,-CrimeScore),NAMED('AddedCrimeScore')); 

CrimeTbViz := TABLE(JoinCrime,{JoinCrime.county_fips, CrimeScore});
OUTPUT(SORT(CrimeTbViz, -CrimeScore),NAMED('CrimePerFIPS'), ALL);


// Let's go to Poverty Score!

// PCTPOVALL_2021 - Estimate percentage of people of all ages in poverty 2021
PovAll := TABLE(POVTY((STD.Str.Find(attribute, 'PCTPOVALL_2021',1) <> 0)),
                {Fips_Code,attribute,value});

JoinPoverty := JOIN(PovAll,JoinCrime,
                  LEFT.fips_code = (INTEGER)RIGHT.county_fips,
                  TRANSFORM(RiskPlusRec,
                            SELF.PovertyScore := LEFT.value,
                            SELF            := RIGHT),
                            RIGHT OUTER);
OUTPUT(SORT(JoinPoverty,-PovertyScore),NAMED('AddedPoveryScore')); 

OUTPUT(SORT(PovAll, -value), NAMED('PovertyPerFIPS'), ALL);

// Let's go to the Education Score!

// Less than High School Education
EduHigh := TABLE(EDU((STD.Str.Find(attribute, 'Percent of adults with less than a high school diploma, 2017-21',1) <> 0)),
                {Fips_Code,tot := ROUND(AVE(GROUP,value),2)},fips_code);
// With College Education
EduColl := TABLE(EDU((STD.Str.Find(attribute, 'Percent of adults completing some college or associate\'s degree, 2017-21',1) <> 0)),
                {Fips_Code,tot := ROUND(AVE(GROUP,value),2)},fips_code);
// With Graduate Education
EduGrad := TABLE(EDU((STD.Str.Find(attribute, 'Percent of adults with a bachelor\'s degree or higher, 2017-21', 1) <> 0)),
                {Fips_Code,tot := ROUND(AVE(GROUP,value),2)},fips_code);

EduRecord := RECORD
 fipsInfo;
 HighEducation  := 0.0;
 CollEducation  := 0.0;
 GradEducation  := 0.0;
 END; 
EduTemp0 := PROJECT(fipsInfo, EduRecord);

EduTemp1 := JOIN(EduHigh, EduTemp0,
                LEFT.fips_code = (INTEGER)RIGHT.county_fips,
                TRANSFORM(EduRecord,
                        SELF.HighEducation := LEFT.tot,
                        SELF            := RIGHT),
                    RIGHT OUTER);

EduTemp2 := JOIN(EduColl, EduTemp1,
                LEFT.fips_code = (INTEGER)RIGHT.county_fips,
                TRANSFORM(EduRecord,
                        SELF.CollEducation := LEFT.tot,
                        SELF            := RIGHT),
                    RIGHT OUTER);

EduTable := JOIN(EduGrad, EduTemp2,
                LEFT.fips_code = (INTEGER)RIGHT.county_fips,
                TRANSFORM(EduRecord,
                        SELF.GradEducation := LEFT.tot,
                        SELF            := RIGHT),
                    RIGHT OUTER);

OUTPUT(EduTable, NAMED('Education'));

JoinEdu := JOIN(EduTable,JoinPoverty,
                  LEFT.county_fips = (INTEGER)RIGHT.county_fips,
                  TRANSFORM(RiskPlusRec,
                            SELF.IlliteracyScore := (
                                                    LEFT.HighEducation * 0.5 + 
                                                    LEFT.CollEducation * 0.3 +
                                                    LEFT.GradEducation * 0.2
                                                ),
                            SELF            := RIGHT),
                            RIGHT OUTER);
OUTPUT(SORT(JoinEdu,-IlliteracyScore),NAMED('AddedIlliteracyScore')); 

EduTableViz := TABLE(JoinEdu,{JoinEdu.county_fips, IlliteracyScore});
OUTPUT(SORT(EduTableViz, -IlliteracyScore),NAMED('IlliteracyPerFIPS'), ALL);

// Let's Go to the Unemployment Score

UnempPer := TABLE(UNEMP((STD.Str.Find(attribute, 'Unemployment_rate_2021',1) <> 0)),
                {Fips_Code,cnt := ROUND(AVE(GROUP,value),2)},Fips_Code);

JoinUnemp := JOIN(UnempPer,JoinEdu,
                  LEFT.fips_code = (INTEGER)RIGHT.county_fips,
                  TRANSFORM(RiskPlusRec,
                            SELF.UnemploymentScore := LEFT.cnt,
                            SELF            := RIGHT),
                            RIGHT OUTER);
OUTPUT(SORT(JoinUnemp,-UnemploymentScore),NAMED('AddedUnemploymentScore')); 

OUTPUT(SORT(UnempPer, -cnt), NAMED('UnemplymentPerFIPS'), ALL);

// Let's go to Gun Violence
OUTPUT(SORT(GUNV, -n_killed), NAMED('GunViolence'));

JoinGunV := JOIN(GunV,JoinUnemp,
                  LEFT.county_name = (STRING)RIGHT.county_name,
                  TRANSFORM(RiskPlusRec,
                            SELF.GunViolenceScore := (0.7 * LEFT.n_killed) + (0.3 * LEFT.n_injured),
                            SELF            := RIGHT),
                            RIGHT OUTER);
OUTPUT(SORT(JoinGunV,-GunViolenceScore),NAMED('AddedGunViolenceScore')); 

GunViolenceViz := TABLE(JoinGunV,{JoinGunV.county_fips, GunViolenceScore});
OUTPUT(SORT(GunViolenceViz, -GunViolenceScore),NAMED('GunViolenceScorePerFIPS'), ALL);
