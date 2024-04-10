EXPORT File_SvcData := MODULE
Final_risk_recs := RECORD
  string45   city;
  string2    state_id;
  string20   state_name;
  unsigned3  county_fips;
  string30   county_name;
  decimal5_2 educationscore;
  decimal5_2 povertyscore;
  decimal5_2 crimescore;
  decimal5_2 finalscore;
 END;

EXPORT CleanCoreDS  := DATASET('~SAFE::OUT::RISKTBL',Final_risk_recs,FLAT);

//Declare and Build Indexes (special datasets that can be used in the ROXIE data delivery cluster
EXPORT CleanCityStIDX     := INDEX(CleanCoreDS,{city,state_id},{CleanCoreDS},'~SAFE::IDX::CoreFile::CityState');
EXPORT CleanCoreFIPSIDX   := INDEX(CleanCoreDS,{county_fips},{CleanCoreDS},'~SAFE::IDX::CoreFile::FIPS');


END;