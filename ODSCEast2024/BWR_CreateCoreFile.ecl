//This File generates the core "safety" data and indexes used in the SafeHaven Service
IMPORT $, STD;

UpperIt(STRING txt) := Std.Str.ToUpperCase(txt);
CityDS              := $.File_AllData.City_DS;
Crime               := $.File_AllData.CrimeDS;


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
 REAL8 EducationScore  := 0;
 REAL8 PovertyScore    := 0;
 REAL8 PopulationScore := 0;
 REAL8 CrimeScore      := 0;

END; 
 
RiskTbl := TABLE(BaseInfo,RiskPlusRec);
// OUTPUT(RiskTbl,NAMED('BuildTable'));


// Create Crime Table

CrimeRec := RECORD
CrimeRate := TRUNCATE((INTEGER)Crime.crime_rate_per_100000);
Crime.fips_st;
fips_cty := (INTEGER)Crime.fips_cty;
Fips := Crime.fips_st + INTFORMAT(Crime.fips_cty,3,1);
END;

CrimeTbl := TABLE(Crime,CrimeRec);
// OUTPUT(CrimeTbl,NAMED('BuildCrimeTable'));

JoinCrime := JOIN(CrimeTbl,RiskTbl,
                  LEFT.fips = (STRING5)RIGHT.county_fips,
                  TRANSFORM(RiskPlusRec,
                            SELF.city        := STD.STR.ToUpperCase(RIGHT.city),
                            SELF.state_id    := STD.STR.ToUpperCase(RIGHT.state_id),
                            SELF.state_name  := STD.STR.ToUpperCase(RIGHT.state_name),
                            SELF.county_name := STD.STR.ToUpperCase(RIGHT.county_name),
                            SELF.CrimeScore  := LEFT.crimerate,
                            SELF             := RIGHT),
                            RIGHT OUTER);
// Calculate the min and max of the dataset
mini := MIN(JoinCrime, CrimeScore);
maxi := MAX(JoinCrime, CrimeScore);

// Define a transform that adds a MinMax scaled field to each record
crime_by_county_minmax := RECORD
    JoinCrime;
    REAL8 NormCrime;
END;

crime_by_county_minmax add_minmax(JoinCrime le) := TRANSFORM
    SELF := le;
    SELF.NormCrime := ((le.CrimeScore - mini) / (maxi - mini))*100;
END;

// Use the transform to add a MinMax scaled field to each record in the dataset
Crime_by_county_Norm := PROJECT(JoinCrime, add_minmax(LEFT));
// OUTPUT(Crime_by_county_Norm);
// OUTPUT(Crime_by_county_Norm(NormCrime > 0.99));
OUTPUT(Crime_by_county_Norm,,'~SAFE::OUT::CRIMENORM', OVERWRITE);                            
// OUTPUT(SORT(JoinCrime,-CrimeScore),NAMED('AddedCrimeScore')); 
// OUTPUT(COUNT(JoinCrime), NAMED('CountJoinCrime'));


// Add Education Score

EduRecs := RECORD
UNSIGNED3 FIPS_Code;
STRING50 County;
REAL8 NormEducation;
END;

Education := DATASET('~SAFE::OUT::EDUNORM', EduRecs, FLAT); //Generated in BWR_Analyze_Education
// OUTPUT(Education, NAMED('BuildEduTable'));

JoinEdu := JOIN(Education, Crime_by_county_Norm, 
                  LEFT.FIPS_Code = (UNSIGNED3) RIGHT.county_fips,
                  TRANSFORM(RECORDOF(Crime_by_county_Norm),
                            SELF.EducationScore := LEFT.NormEducation*100;
                            SELF := RIGHT),
                            RIGHT OUTER);
// OUTPUT(JoinEdu, NAMED('AddedEduScore'));
// OUTPUT(COUNT(JoinEdu), NAMED('CountJoinEdu'));



// Add Poverty Score

PovertyRecs := RECORD
UNSIGNED3 FIPS_Code;
STRING50 County;
REAL8 NormPoverty;
END;


Poverty := DATASET('~SAFE::OUT::POVNORM', PovertyRecs, FLAT);
// OUTPUT(Poverty, NAMED('BuildPovTable'));

JoinPov := JOIN(Poverty, JoinEdu, 
                  LEFT.FIPS_Code = (UNSIGNED3) RIGHT.county_fips,
                  TRANSFORM(RECORDOF(JoinEdu),
                            SELF.PovertyScore := LEFT.NormPoverty*100;
                            SELF := RIGHT),
                            RIGHT OUTER);
// OUTPUT(JoinPov, NAMED('AddedPovScore'));
// OUTPUT(COUNT(JoinPov), NAMED('CountJoinPov'));


// Add Population Score

PopulationRecs := RECORD
UNSIGNED3 FIPS_Code;
STRING50 County;
REAL8 Population;
END;



Population := DATASET('~SAFE::OUT::POP', PopulationRecs, FLAT);
// OUTPUT(Population, NAMED('BuildPopTable'));

JoinPop := JOIN(Population, JoinPov, 
                  LEFT.FIPS_Code = (UNSIGNED3) RIGHT.county_fips,
                  TRANSFORM(RECORDOF(JoinPov),
                            SELF.PopulationScore := LEFT.Population;
                            SELF := RIGHT),
                            RIGHT OUTER);
// OUTPUT(JoinPop, NAMED('AddedPopScore'));

// Calculate total score

// final_tbl_rec := RECORD
  // Joinpop;
  // REAL8 Total
 // END;
 
// final_tbl_rec calc_total(JoinPop le) := TRANSFORM
  // SELF := le;
  // SELF.Total := (le.educationscore + le.populationscore + le.normcrime + le.povertyscore)/4;
// END;

// Final_tbl := PROJECT(JoinPop, calc_total(LEFT));
// OUTPUT(Final_tbl, NAMED('FinalRiskTable'));

// OUTPUT(SORT(Final_tbl, -total));

final_tbl_rec := RECORD
  Joinpop;
  REAL8 Total
 END;
 
 
 
 crime_weight := 0.5;
 pov_weight   := 0.3;
 edu_weight   := 0.2;
final_tbl_rec calc_total(JoinPop le) := TRANSFORM
  SELF := le;
  SELF.Total := ((edu_weight *le.educationscore) + (crime_weight * le.normcrime) + (pov_weight * le.povertyscore));
END;

Final_tbl := PROJECT(JoinPop, calc_total(LEFT));
OUTPUT(SORT(Final_tbl, total), NAMED('FinalRiskTable'));

OUTPUT(SORT(Final_tbl, -total));
OUTPUT(AVE(Final_tbl, total), NAMED('AverageScore'));
OUTPUT(Min(Final_tbl, total), NAMED('MinScore'));
OUTPUT(MAX(Final_tbl, total), NAMED('MaxScore'));
// OUTPUT(COUNT(Final_tbl(total = 0)));

Final_risk_tbl_recs := RECORD
Final_tbl.city;
Final_tbl.state_id;
Final_tbl.state_name;
Final_tbl.county_fips;
Final_tbl.county_name;
DECIMAL5_2 EducationScore := Final_tbl.educationscore;
DECIMAL5_2 PovertyScore   := Final_tbl.PovertyScore;
DECIMAL5_2 CrimeScore     := Final_tbl.NormCrime;
DECIMAL5_2 FinalScore     := Final_tbl.Total;
END;


Final_risk_tbl := TABLE(Final_tbl, Final_risk_tbl_recs);
OUTPUT(Final_risk_tbl,, '~SAFE::OUT::RISKTBL', OVERWRITE,NAMED('FinalCoreData'));
OUTPUT(SORT(Final_risk_tbl,-FinalScore),NAMED('SortDescFinal'));
    
b0 := COUNT(Final_tbl(total = 0));
b1 := COUNT(Final_tbl(total>0 and total < 10));
b2 := COUNT(Final_tbl(total > 10 and total <20));
b3 := COUNT(Final_tbl(total >= 20 and total <30));
b4 := COUNT(Final_tbl(total >= 30 and total <40));
b5 := COUNT(Final_tbl(total >= 40));
total := COUNT(Final_tbl);
                  
DistTbl := DATASET([  {'0', b0},
                      {'0-10', b1},
                      {'10-20', b2},
                      {'20-30', b3},
                      {'30-40', b4},
                      {'>40', b5},
                      {'total', total}], {STRING5 Score, UNSIGNED3 Cnt});
OUTPUT(DistTbl, NAMED('Distribution_of_Scores'));

//Write out the new file and then define it using DATASET
                                       
CleanCoreDS  := DATASET('~SAFE::OUT::RISKTBL',Final_risk_tbl_recs,FLAT);

//Declare and Build Indexes (special datasets that can be used in the ROXIE data delivery cluster
CleanCoreIDX     := INDEX(CleanCoreDS,{city,state_id},{CleanCoreDS},'~SAFE::IDX::CoreFile::CityState');
CleanCoreFIPSIDX := INDEX(CleanCoreDS,{county_fips},{CleanCoreDS},'~SAFE::IDX::CoreFile::FIPS');
BuildCoreIDX     := BUILD(CleanCoreIDX ,OVERWRITE,NAMED('CoreIDXByCityState'));
BuildCoreFIPSIDX := BUILD(CleanCoreFIPSIDX,OVERWRITE,NAMED('CoreIDXByCountyFIPS'));

//SEQUENTIAL is similar to OUTPUT, but executes the actions in sequence instead of the default parallel actions of the HPCC
SEQUENTIAL(BuildCoreIDX, BuildCoreFIPSIDX);

                      
                      
