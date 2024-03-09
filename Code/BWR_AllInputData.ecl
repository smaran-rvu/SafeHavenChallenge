IMPORT $;
SAFE := $.File_AllData;

OUTPUT(SAFE.unemp_byCountyDS,NAMED('Unemployment'));
OUTPUT(SAFE.EducationDS,NAMED('Education'));
OUTPUT(SAFE.pov_estimatesDS,NAMED('Poverty'));
OUTPUT(SAFE.pop_estimatesDS,NAMED('Population'));
OUTPUT(SAFE.PoliceDS,NAMED('Police'));
OUTPUT(SAFE.FireDS,NAMED('Fire'));
OUTPUT(SAFE.HospitalDS,NAMED('Hospitals'));
OUTPUT(SAFE.ChurchDS,NAMED('Churches'));
OUTPUT(SAFE.FoodBankDS,NAMED('FoodBanks'));
OUTPUT(SAFE.CrimeDS,NAMED('Crime'));
OUTPUT(SAFE.City_DS,NAMED('Cities'));
OUTPUT(COUNT(SAFE.City_DS),NAMED('Cities_Cnt'));