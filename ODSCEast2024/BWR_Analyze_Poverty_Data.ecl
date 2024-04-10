
IMPORT $, Visualizer;
CityDS := $.File_AllData.City_DS;
PovertyDS  := $.File_AllData.pov_estimatesDS;


// POVERTY ANALYSIS
// ----------------//

// Poverty Analysis by county
Poverty_by_county := PovertyDS(attribute = 'PCTPOVALL_2021' and FIPS_Code % 1000 <> 0 );
OUTPUT(Poverty_by_county, NAMED('Poverty_by_county'));
OUTPUT(COUNT(SORT(Poverty_by_county, FIPS_Code)), NAMED('Count_of_poverty_by_county'));

// Poverty Analysis by state
Poverty_by_state := PovertyDS(attribute = 'PCTPOVALL_2021' and FIPS_Code % 1000 = 0 and FIPS_Code <> 0 );
OUTPUT(Poverty_by_state, , NAMED('Poverty_by_state'));
OUTPUT(COUNT(SORT(Poverty_by_state, FIPS_Code)), NAMED('Count_of_poverty_by_state'));


Tbl_recs := RECORD
STRING2 State;
REAL8 Poverty;
END;

Tbl_recs ToPoverty_tbl(Poverty_by_state Le) := TRANSFORM
SELF.State := Le.State;
SELF.Poverty := Le.Value;
END;


// Map of Poverty by state
Poverty_tbl := PROJECT(Poverty_by_state, ToPoverty_tbl(LEFT));
OUTPUT(Poverty_tbl, NAMED('Poverty_percent_by_state'));
viz_usstates := Visualizer.Choropleth.USStates('usStates',, 'Poverty_percent_by_state');
viz_usstates;


// Bar Chart of Poverty by state
viz_bar := Visualizer.MultiD.Bar('bar',, 'Poverty_percent_by_state');
viz_bar;

pov_by_county_tbl_recs := RECORD
UNSIGNED3 FIPS_Code;
STRING50 County;
REAL8 Poverty;
END;

pov_by_county_tbl_recs ToPoverty_by_county_tbl(Poverty_by_county Le) := TRANSFORM
SELF.FIPS_Code := Le.FIPS_Code;
SELF.County := Le.Area_name;
SELF.Poverty := Le.Value;
END;

Poverty_by_county_tbl := PROJECT(Poverty_by_county, ToPoverty_by_county_tbl(LEFT));
OUTPUT(Poverty_by_county_tbl, NAMED('Poverty_percent_by_county'));
OUTPUT(Poverty_by_county_tbl,,'~SAFE::OUT::POV', OVERWRITE);

// Calculate the min and max of the dataset
mini := MIN(Poverty_by_county_tbl, Poverty);
maxi := MAX(Poverty_by_county_tbl, Poverty);

// Define a transform that adds a MinMax scaled field to each record
poverty_by_county_minmax := RECORD
    Poverty_by_county_tbl;
    REAL8 NormPoverty;
END;

poverty_by_county_minmax add_minmax(poverty_by_county_tbl le) := TRANSFORM
    SELF := le;
    SELF.NormPoverty := (le.Poverty - mini) / (maxi - mini);
END;

// Use the transform to add a MinMax scaled field to each record in the dataset
Poverty_by_county_Norm := PROJECT(Poverty_by_county_tbl, add_minmax(LEFT));
// OUTPUT(Poverty_by_county_Norm);
// OUTPUT(Poverty_by_county_Norm(NormPoverty = 0));
OUTPUT(Poverty_by_county_Norm,,'~SAFE::OUT::POVNORM', OVERWRITE);

OUTPUT(Poverty_by_county_Norm(fips_code = 1047));
//9110
