
IMPORT $, Visualizer;
CityDS       := $.File_AllData.City_DS;
PopulationDS := $.File_AllData.pop_estimatesDS;

// POPULATION ANALYSIS
// ----------------//

// Population Analysis by county
Population_by_county := PopulationDS(attribute = 'POP_ESTIMATE_2020' 
                                    and FIPS_Code % 1000 <> 0 );
OUTPUT(Population_by_county, NAMED('Population_by_county'));
OUTPUT(COUNT(SORT(Population_by_county, FIPS_Code)), NAMED('Count_of_Population_by_county'));

// Population Analysis by state
Population_by_state := PopulationDS(attribute = 'POP_ESTIMATE_2020'   
                                and FIPS_Code % 1000 = 0 and FIPS_Code <> 0 );
OUTPUT(Population_by_state, , NAMED('Population_by_state'));
OUTPUT(COUNT(SORT(Population_by_state, FIPS_Code)), NAMED('Count_of_Population_by_state'));


Tbl_recs := RECORD
STRING2 State;
REAL8 Population;
END;

Tbl_recs ToPopulation_tbl(Population_by_state Le) := TRANSFORM
SELF.State := Le.State;
SELF.Population := Le.Value;
END;


// Map of Population by state
Population_tbl := PROJECT(Population_by_state, ToPopulation_tbl(LEFT));
OUTPUT(Population_tbl, NAMED('PopulationCount_by_state'));
viz_usstates := Visualizer.Choropleth.USStates('usStates',, 'PopulationCount_by_state');
viz_usstates;


// Bar Chart of Population by state
viz_bar := Visualizer.MultiD.Bar('bar',, 'PopulationCount_by_state');
viz_bar;

population_by_county_tbl_recs := RECORD
UNSIGNED3 FIPS_Code;
STRING50 County;
REAL8 Population;
END;

population_by_county_tbl_recs ToPopulation_by_county_tbl(Population_by_county Le) := TRANSFORM
SELF.FIPS_Code := Le.FIPS_Code;
SELF.County := Le.Area_name;
SELF.Population := Le.Value;
END;

Population_by_county_tbl := PROJECT(Population_by_county, ToPopulation_by_county_tbl(LEFT));
OUTPUT(Population_by_county_tbl, NAMED('PopulationCount_by_county'));
OUTPUT(Population_by_county_tbl,,'~SAFE::OUT::POP', OVERWRITE);

// Calculate the min and max of the dataset
mini := MIN(Population_by_county_tbl, Population);
maxi := MAX(Population_by_county_tbl, Population);

// Define a transform that adds a MinMax scaled field to each record
population_by_county_minmax := RECORD
    Population_by_county_tbl;
    REAL8 NormPopulation;
END;

population_by_county_minmax add_minmax(population_by_county_tbl le) := TRANSFORM
    SELF := le;
    SELF.NormPopulation := (le.Population - mini) / (maxi - mini);
END;

// Use the transform to add a MinMax scaled field to each record in the dataset
Population_by_county_Norm := PROJECT(Population_by_county_tbl, add_minmax(LEFT));
OUTPUT(Population_by_county_Norm);
OUTPUT(Population_by_county_Norm(NormPopulation > 0.99));
OUTPUT(Population_by_county_Norm,,'~SAFE::OUT::POPNORM', OVERWRITE);