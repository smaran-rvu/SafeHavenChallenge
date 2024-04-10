//TO DO - Add Food Banks
IMPORT $,STD;
UpperIt(STRING txt) := Std.Str.ToUpperCase(txt);
 CoreFIPSKey     := $.File_SvcData.CleanCoreFIPSIDX; 
 CoreCitySTKey   := $.File_SvcData.CleanCityStIDX; 
 FireKey         := $.File_CleanResponders.CleanFireIDX;
 FireFIPSKey     := $.File_CleanResponders.CleanFireFIPSIDX; 
 PoliceKey       := $.File_CleanResponders.CleanPoliceIDX;
 HospitalKey     := $.File_CleanResponders.CleanHospitalIDX;
 ChurchCityStKey := $.File_CleanResponders.CleanChurchIDX; 
 ChurchFIPSKey   := $.File_CleanResponders.CleanChurchFIPSIDX;
 
 UNSIGNED3 fips_value  := 0   : STORED('FIPS');
 STRING23  city_value  := ''  : STORED('City');
 STRING2   state_value  := '' : STORED('State');
 

GetPrimary  := IF(fips_value = 0,
                   OUTPUT(CoreCitySTKey(City = UpperIt(city_Value) AND State_id = UpperIt(state_Value)),NAMED('CoreDataByCity')),
                   OUTPUT(CoreFIPSKey(county_fips = fips_value),NAMED('CoreDataByFIPS')));  
              
GetFire     := IF(city_value <> '',
                   OUTPUT(FireKey(City = UpperIt(city_Value) AND State = UpperIt(state_Value)),NAMED('Fire_Stations_ByCity')),
                   OUTPUT(FireFIPSKey(primaryfips = fips_value),NAMED('Fire_Stations_ByFIPS')));  
               
GetPolice   := IF(city_value <> '',
                   OUTPUT(PoliceKey(City = UpperIt(city_Value) AND State = UpperIt(state_Value) AND WILD(countyfips)),NAMED('Police_Stations_ByCity')),
                   OUTPUT(PoliceKey(countyfips = fips_value),NAMED('Police_Stations_ByFIPS')));

GetHospital := IF(city_value <> '',
                   OUTPUT(HospitalKey(City = UpperIt(city_Value) AND State = UpperIt(state_Value) AND WILD(countyfips)),NAMED('Hospitals_ByCity')),
                   OUTPUT(HospitalKey(countyfips = fips_value),NAMED('Hospitals_ByFIPS')));
                   
GetChurches := IF(Fips_Value = 0,
                  OUTPUT(ChurchCityStKey(City=UpperIt(City_Value),State=UpperIt(State_Value)),NAMED('Worship_ByCity')),
                  OUTPUT(ChurchFIPSKey(PrimaryFIPS=Fips_Value),NAMED('Worship_ByFIPS')));

EXPORT SafeHaven_Svc := SEQUENTIAL(GetPrimary,GetFire,GetPolice,GetHospital,GetChurches);

