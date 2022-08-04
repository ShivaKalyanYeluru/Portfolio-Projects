-- Using Indian Census 2011 database
USE IndianCensus2011;

-- Checking the contents of table literacy
SELECT * FROM Literacy;

EXEC sp_help Literacy;

-- Checking the contents of table population
SELECT * FROM Population;

EXEC sp_help Population;

-- No of rows in the tables
SELECT DISTINCT COUNT(*) Literacy FROM Literacy;
SELECT DISTINCT COUNT(*) Population FROM Population;

-- Total population in India
SELECT SUM(population) PopulationOfIndia FROM Population;

-- Average growth rate, sex ratio, literacy in India
SELECT CONCAT(ROUND(AVG(Growth)*100,2),'%') AverageGrowthRateIndia FROM Literacy;
SELECT ROUND(AVG(Sex_Ratio),0) AverageSexRatioIndia FROM Literacy;
SELECT CONCAT(ROUND(AVG(Literacy),2),'%') AverageLiteracyIndia FROM Literacy;

-- Data for Andhra Pradesh (AP)
SELECT * FROM Literacy
WHERE state = 'Andhra Pradesh';

SELECT * FROM Population
WHERE state = 'Andhra Pradesh';


-- Population in AP
SELECT SUM(population) PopulationOfAP FROM Population
WHERE state = 'Andhra Pradesh';

-- Population in each state
SELECT state, SUM(population) Population FROM Population
GROUP BY state;

-- Average growth rate, sex ratio, literacy in AP
SELECT CONCAT(ROUND(AVG(Growth)*100,2),'%') AverageGrowthRateAP FROM Literacy
WHERE state = 'Andhra Pradesh';
SELECT ROUND(AVG(Sex_Ratio),0) AverageSexRatioAP FROM Literacy
WHERE state = 'Andhra Pradesh';
SELECT CONCAT(ROUND(AVG(Literacy),2),'%') AverageLiteracyAP FROM Literacy
WHERE state = 'Andhra Pradesh';


-- Let's check the above stats for all the states
SELECT state, CONCAT(ROUND(AVG(Growth)*100,2),'%') AverageGrowthRate FROM Literacy
GROUP BY state 
ORDER BY ROUND(AVG(Growth)*100,2) DESC;
SELECT state, ROUND(AVG(Sex_Ratio),0) AverageSexRatio FROM Literacy
GROUP BY state
ORDER BY ROUND(AVG(Sex_Ratio),0) DESC;
SELECT state, CONCAT(ROUND(AVG(Literacy),2),'%') AverageLiteracy FROM Literacy
GROUP BY state
ORDER BY ROUND(AVG(Literacy),2) DESC;


-- States with literacy higher than 90%
SELECT state, CONCAT(ROUND(AVG(Literacy),2),'%') AverageLiteracy FROM Literacy
GROUP BY state
HAVING ROUND(AVG(Literacy),2) > 90;


-- Top 5 states with highest average growth rate
SELECT TOP 5 state, CONCAT(ROUND(AVG(growth*100),2),'%') AvgGrowthRate FROM Literacy
GROUP BY state
ORDER BY ROUND(AVG(growth*100),2) DESC;


-- Top 5 states with lowest sex ratio
SELECT Top 5 state, ROUND(AVG(Sex_Ratio),0) AverageSexRatio FROM Literacy
GROUP BY state
ORDER BY ROUND(AVG(Sex_Ratio),0);


-- Top and bottom 3 states with highest literacy
WITH top3states AS 
( 
SELECT TOP 3 state, CONCAT(ROUND(AVG(Literacy),2),'%') AverageLiteracy FROM Literacy
GROUP BY state
ORDER BY ROUND(AVG(Literacy),2) DESC
),
bottom3states AS
(
SELECT TOP 3 state, CONCAT(ROUND(AVG(Literacy),2),'%') AverageLiteracy FROM Literacy
GROUP BY state
ORDER BY ROUND(AVG(Literacy),2)
)
SELECT * FROM top3states
UNION
SELECT * FROM bottom3states
ORDER BY AverageLiteracy DESC;


-- Districts starting with letter 's'
SELECT district FROM Literacy
WHERE LOWER(District) LIKE 's%';

-- Districts starting with letter 's' and ending with 'i'
SELECT district FROM Literacy
WHERE LOWER(District) LIKE 's%i'; 
-- OR
SELECT district FROM Literacy
WHERE LOWER(District) LIKE 's%' AND LOWER(District) LIKE '%i';


-- Joining tables, Literacy and Population 
SELECT L.*, P.Population, P.Area_km2 FROM Literacy L
JOIN Population P
ON L.District = P.District;

-- Creating a temporary table combining literacy and population data
DROP TABLE IF EXISTS joinedtable;
SELECT L.*, P.Population, P.Area_km2
INTO joinedtable
FROM Literacy L
JOIN Population P
ON L.District = P.District;

SELECT * FROM joinedtable;


-- Male and Female population in each state

/*	Calculating Male and Female population from the given data
	 We have Population and Sex Ratio
	 Sex Ratio = (Female/Male)*1000, Population = Male + Female
	 Male = (Female/Sex Ratio)*1000 
	 Population = (Female/Sex Ratio)*1000 + Female
	 Female = (Population*Sex Ratio)/(1000 + Sex Ratio) 
	 Male = (Female/Sex Ratio)*1000
	 Male = Population/(1000 + Sex Ratio)
*/

WITH malefemale AS 
(
SELECT *, ROUND((Population*1000)/(1000+Sex_Ratio),0) MalePopulation, 
ROUND((Population*Sex_Ratio)/(1000+Sex_Ratio),0) FemalePopulation
FROM joinedtable
)
SELECT State, SUM(malepopulation) MalePopulation, SUM(femalepopulation) FemalePopulation FROM malefemale
GROUP BY State;


-- Population in previous census
SELECT SUM(s.PreviousCensusPopulation) PreviousCensusPopulation, SUM(s.Census2011Population) Census2011Population
FROM 
(SELECT d.state, SUM(d.PreviousCensusPopulation) PreviousCensusPopulation, SUM(d.Census2011Population) Census2011Population
FROM 
(SELECT District, state, ROUND(Population/(1+Growth),0) PreviousCensusPopulation, Population Census2011Population 
FROM joinedtable) d
GROUP BY d.State) s;


-- Population Density per sq km
SELECT District, State, ROUND(population/area_km2,0) PopulationDensity FROM joinedtable;

-- Add column Population Density to joinedtable
ALTER TABLE joinedtable
ADD 
PreviousCensusPopulation int, 
PopulationDensity int;
SELECT * FROM joinedtable;

-- Update column previous census population in joinedtable
UPDATE joinedtable
SET PreviousCensusPopulation = ROUND(Population/(1+Growth),0)
WHERE PreviousCensusPopulation IS NULL;
SELECT * FROM joinedtable;

-- Update column population density in joinedtable
UPDATE joinedtable
SET PopulationDensity = population/Area_km2
WHERE PopulationDensity IS NULL;
SELECT * FROM joinedtable;

-- State wise population density
SELECT state, ROUND(population/area_km2,0) PopulationDensity
FROM
(SELECT State, SUM(population) Population, SUM(area_km2) Area_km2 FROM joinedtable
GROUP BY State) s;

-- Population density in India
SELECT ROUND(SUM(Population)/SUM(Area_km2),0) PopulationDensityIndia
FROM
(SELECT State, SUM(population) Population, SUM(area_km2) Area_km2 FROM joinedtable
GROUP BY State) s;

-- Delete column population density
ALTER TABLE joinedtable
DROP COLUMN populationdensity;
SELECT * FROM joinedtable;

-- Current vs Previous Census population density

-- State wise
SELECT State, ROUND(SUM(Population)/SUM(Area_km2),0) CurrentPopulationDensity, 
ROUND(SUM(PreviousCensusPopulation)/SUM(Area_km2),0) PreviousPopulationDensity
FROM joinedtable GROUP BY State;

-- India
SELECT ROUND(SUM(Population)/SUM(Area_km2),0) CurrentPopulationDensity, 
ROUND(SUM(PreviousCensusPopulation)/SUM(Area_km2),0) PreviousPopulationDensity,
SUM(area_km2) Area_km2, SUM(Population) Population, SUM(PreviousCensusPopulation) PreviousCensusPopulation
FROM 
(SELECT state, SUM(area_km2) Area_km2, SUM(Population) population, SUM(PreviousCensusPopulation) PreviousCensusPopulation
FROM joinedtable GROUP BY State) s

-- Top 3 districts with highest literacy in each state
SELECT district, state, literacy, rnk
FROM 
(SELECT District, State, Literacy, rank() over(partition by state order by literacy desc) rnk FROM Literacy) r
WHERE rnk < 4;

-- Top 3 districts with highest population density in each state
SELECT district, state, populationdensity, rnk
FROM 
(SELECT District, State, ROUND(Population/Area_km2,0) populationdensity, rank() over(partition by state order by population/area_km2 desc) rnk FROM joinedtable) r
WHERE rnk < 4;