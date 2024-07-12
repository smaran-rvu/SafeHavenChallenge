# The Safe Haven ECL Challenge! 
Welcome to another HPCC Systems and ECL Code Challenge!

## Introduction
Many travelers find themselves on occasion in a strange land and a strange city, sometimes without their control. Without knowing the risks and dangers in that area, sometimes a tourist can suddenly be in a dangerous situation. What can we do as developers to help prevent this? 

## The Challenge
Your challenge is to analyze different social factors such as poverty, unemployment, and other factors in US Counties and develop insights and additional information for the traveler.

The goal of the challenge is to provide two important sets of information:

1.	Analysis of social factors in an area (unemployment, education, poverty, and population) and identify it as a "Hot Spot".

2.	Provide additional information to the traveler to help find "safe haven" resources in their area (fire and police stations, hospitals, churches, food banks, etc.).

### NOTE: This repo focuses on the aspect 1 - Identification of Hot Spots

## The Data
The following public datasets has been collected from all 50 states.

These datasets include:

**Education**

**Unemployment**

**Poverty**

**Population**

**Crime**

**Police**

**Fire Stations**

**Hospitals**

**Places of Worship**

**Food Banks**

Auxiliary Datasets: 

A **Cities** dataset with related FIPS and Zip Codes

**Unemployment Rates** (Not really used in this challenge but interesting data!)

**Gun Violence Rates** - https://www.kaggle.com/datasets/jameslko/gun-violence-data

## File for Analysis:

File path - `./Code/BWR_HotSpotAnalysis.ecl`

## Aspects for Analysis:

1. Crime: 
We have changed the crime dataset a bit to also include the other crimes listed in the dataset proportional to their weights according to how they affect the traveller

- Firstly, we have calculated the respective crime rates of Murder, Rape, Robbery, Assault, Larceny (note: It is pronounced as 'Larseny') and Theft per 1000 individuals. This gives us a clear idea of how often the crime occurs without the influence of how large the population is in the specific county.

- We have assigned and multiplied each crime rate with its weight. We have given a decreasing order of weight to the crime rates as follows:
   i) Murder
  ii) Rape
 iii) Robbery
 iv) Assault
  v) Larceny
 vi) Theft
The order signifies a decreasing level of damage/harm to the victim of the crime.

2. Poverty:
According to the Beureau of Justice Statistics, the average income for a criminal is around $15,000 (15K), which matches the poverty line's boundary. Thus, we have taken the Estimate percentage of people of all ages in poverty in 2021. This is our poverty score

3. Education/Illiteracy:
We have taken 3 statistics for finding out the illiteracy rate for each county - 
a) Percent of adults with less than a high school diploma, 
b) Percent of adults completing some college or associate's degree, 2017-21 and
c) Percent of adults with a bachelor's degree or higher, 2017-21
According to the United States Sentencing Commission, close to half of all criminals fall under category (a), i.e. they have less than a high school diploma. Category (b) has more individuals committing more sexually involved crimes, while the last category comprises of individuals committing fraud. This was the inspiration behind the choosing of weight values for each category.

4. Unemployment:
All statistics point out that unemployment and severe divides in the socio-economic status in the society cause more crime. Since unemployment directly affects crime rates irrespective of type, we have chosen to use the unemployment rate (percentage) of every county in 2021.

5. Gun Violence:
As much as this crime would have been included under crime score, we felt the need to specifically emphasize the impact of Gun violence in America. This crime has a higher impact when compared to most crimes and is recently on the rise for targeting specific ethnic groups, which is why we felt the need to include it separately. We took reference from a Kaggle dataset and dropped all the columns which were not necessary in calculating the number of fatalities that have occurred because of gun violence. The number of deaths are given more emphasis and higher weights when compare to the number of injuries.