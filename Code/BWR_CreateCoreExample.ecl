// Let's create a core "risk" file that the county code (FIPS) and the primary city.
// We can extra ct this data from the Cities file.

#OPTION('obfuscateOutput',True);
IMPORT $;
CityDS := $.File_AllData.City_DS;
Crime  := $.File_AllData.CrimeDS;

//CityDS(county_fips = 5035); Test to verify data accuracy for the crime score


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
 EducationScore  := 0;
 PovertyScore    := 0;
 PopulationScore := 0;
 CrimeScore      := 0;
 Total           := 0;
END; 
 
RiskTbl := TABLE(BaseInfo,RiskPlusRec);
OUTPUT(RiskTbl,NAMED('BuildTable'));

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
    ArsonPer1000 := (INTEGER)Crime.arson * 1000 / (INTEGER)Crime.population;
    // Burgleries needn't be added since they affect residents more than travellers
    Crime.fips_st;
    fips_cty := (INTEGER)Crime.fips_cty;
    Fips := Crime.fips_st + INTFORMAT(Crime.fips_cty,3,1);
END;

CrimeTbl := TABLE(Crime,CrimeRec);
OUTPUT(CrimeTbl,NAMED('BuildCrimeTable'));

JoinCrime := JOIN(CrimeTbl,RiskTbl,
                  LEFT.fips = (STRING5)RIGHT.county_fips,
                  TRANSFORM(RiskPlusRec,
                            SELF.CrimeScore := LEFT.crimerate * (Left.MurderPer1000 ),
                            SELF            := RIGHT),
                            RIGHT OUTER);
                            
OUTPUT(SORT(JoinCrime,-CrimeScore),NAMED('AddedCrimeScore')); 

//Now go out and get the others! Good like with your challenge! 
//After you complete the other scores, make sure to OUTPUT to a file and then create a DATASET so
//that you can reference and deliver it to the judges.                           



