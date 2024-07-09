IMPORT $,Visualizer;

Cities := $.File_AllData.City_DS;

//Build Table
DensityTbl := TABLE(Cities,{fips := INTFORMAT(Cities.county_fips,5,1),(INTEGER)density});

OUTPUT(DensityTbl,NAMED('DenFIPS'));

Visualizer.Choropleth.USCounties('Fips_demo',,'DenFIPS', , , DATASET([{'paletteID', 'Default'}], Visualizer.KeyValueDef));


