
IMPORT $, Visualizer;
CityDS       := $.File_AllData.City_DS;
EducationDS  := $.File_AllData.EducationDS;


// EDUCATION ANALYSIS
// ----------------//

// Education Analysis by county
Education_by_county := EducationDS(attribute = 'Percent of adults with less than a high school diploma, 2017-21' 
                                    and FIPS_Code % 1000 <> 0 );
OUTPUT(Education_by_county, NAMED('Education_by_county'));
OUTPUT(COUNT(SORT(Education_by_county, FIPS_Code)), NAMED('Count_of_Education_by_county'));

// Education Analysis by state
Education_by_state := EducationDS(attribute = 'Percent of adults with less than a high school diploma, 2017-21'  
                                and FIPS_Code % 1000 = 0 and FIPS_Code <> 0 );
OUTPUT(Education_by_state, , NAMED('Education_by_state'));
OUTPUT(COUNT(SORT(Education_by_state, FIPS_Code)), NAMED('Count_of_Education_by_state'));


Tbl_recs := RECORD
STRING2 State;
REAL8 Education;
END;

Tbl_recs ToEducation_tbl(Education_by_state Le) := TRANSFORM
SELF.State := Le.State;
SELF.Education := Le.Value;
END;


// Map of Education by state
Education_tbl := PROJECT(Education_by_state, ToEducation_tbl(LEFT));
OUTPUT(Education_tbl, NAMED('Education_percent_by_state'));
viz_usstates := Visualizer.Choropleth.USStates('usStates',, 'Education_percent_by_state');
viz_usstates;


// Bar Chart of Education by state
viz_bar := Visualizer.MultiD.Bar('bar',, 'Education_percent_by_state');
viz_bar;

education_by_county_tbl_recs := RECORD
UNSIGNED3 FIPS_Code;
STRING50 County;
REAL8 Education;
END;

education_by_county_tbl_recs ToEducation_by_county_tbl(Education_by_county Le) := TRANSFORM
SELF.FIPS_Code := Le.FIPS_Code;
SELF.County := Le.Area_name;
SELF.Education := Le.Value;
END;

Education_by_county_tbl := PROJECT(Education_by_county, ToEducation_by_county_tbl(LEFT));
OUTPUT(Education_by_county_tbl, NAMED('Education_percent_by_county'));
OUTPUT(Education_by_county_tbl,,'~AVI::OUT::EDU', OVERWRITE);

// Calculate the min and max of the dataset
mini := MIN(Education_by_county_tbl, Education);
maxi := MAX(Education_by_county_tbl, Education);

// Define a transform that adds a MinMax scaled field to each record
education_by_county_minmax := RECORD
    Education_by_county_tbl;
    REAL8 NormEducation;
END;

education_by_county_minmax add_minmax(education_by_county_tbl le) := TRANSFORM
    SELF := le;
    SELF.NormEducation := (le.Education - mini) / (maxi - mini);
END;

// Use the transform to add a MinMax scaled field to each record in the dataset
Education_by_county_Norm := PROJECT(Education_by_county_tbl, add_minmax(LEFT));
OUTPUT(Education_by_county_Norm);
OUTPUT(Education_by_county_Norm(NormEducation > 0.99));
OUTPUT(Education_by_county_Norm,,'~SAFE::OUT::EDUNORM', OVERWRITE,NAMED('EducDataMerge'));

