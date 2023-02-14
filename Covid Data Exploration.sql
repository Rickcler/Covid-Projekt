--SELECT *
--FROM CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM CovidVaccinations
--ORDER BY 3,4


-- Selecting a few important variables
--SELECT Location, date, total_cases, new_cases, total_deaths, population
--FROM CovidDeaths
--ORDER BY Location, Date

----------------------------Germany-------------------------------

---- Death Rate development in Germany over time
--SELECT date, total_cases, total_deaths, ROUND(total_deaths/total_cases *100, 2) as DeathRatio
--FROM CovidDeaths
--WHERE Location = 'Germany'
--ORDER BY date

---- Average rate of new deaths to new cases by Months in Germany 
--SELECT Year(date) AS Year, Month(date) AS Month, SUM(new_cases) NewCases, SUM(new_deaths) NewDeaths, ROUND(SUM(new_deaths)/ SUM(new_cases) * 100, 2) AS DeathRatio
--FROM CovidDeaths
--WHERE Location = 'Germany'
--GROUP BY Year(date), Month(date)
--ORDER BY Year(date), Month(date)

-- Average rate of Infections compared to total Population in Germany by Year and Month
-- What share of the German population had Covid in any given Month since Covid started
--SELECT Year(date) AS Year, Month(date) AS Month, SUM(new_cases) NewCases, AVG(population) Population,  ROUND(SUM(new_cases)/ AVG(population) * 100, 3) AS ShareOfTotal
--FROM CovidDeaths
--WHERE Location = 'Germany'
--GROUP BY Year(date), Month(date)
--ORDER BY Year(date), Month(date)



--------------------------------Countries----------------------------------

---Creating a temp-table with the current total values (total_cases, total_deaths etc.)  
--DROP TABLE IF EXISTS #CountriesTotals
--CREATE TABLE #CountriesTotals (Country NVARCHAR(50), Continent NVARCHAR(50), Population BIGINT, total_cases FLOAT, total_deaths FLOAT, total_cases_pm FLOAT, total_deaths_pm FLOAT)

---- Here I am Using the MAX Function for any of those variables, because, at least in principle, this should return the most recent value (as it wouldn't make sense
---- for those values to go done again. Additionally, I add Continent IS NOT NULL to exclude all the non Country locations.
--INSERT INTO #CountriesTotals
--SELECT location Country, Continent, MAX(Population) Population, MAX(total_cases) total_cases, MAX(total_deaths) total_deaths,
--	   MAX(total_cases_per_million) total_cases_pm, MAX(total_deaths) total_deaths_pm
--FROM CovidDeaths
--WHERE Continent IS NOT NULL
--GROUP BY location, Continent

----Table of Total Cases Ordered By Total Cases
--SELECT * 
--FROM #CountriesTotals
--ORDER BY total_cases DESC

----Table of Total Cases Ordered By Total Deaths
--SELECT * 
--FROM #CountriesTotals
--ORDER BY total_deaths DESC


---- Table for Total Death by total cases ratio by country in Percent
---- According to the table, North Korea has a Death Rate of 600% which can only be explained by wrong Data. Hence, it's been excluded.
--SELECT Country, Continent, CONCAT(ROUND((total_deaths/ total_cases *100), 2), '%') Ratio
--FROM #CountriesTotals
--WHERE Country <> 'North Korea'
--ORDER BY ROUND((total_deaths/ total_cases), 2) DESC


---- Comparing the relative positions different countries have in total cases, total deathsa and death rate
--SELECT Country, Continent, ROW_NUMBER() OVER (ORDER BY  total_cases DESC) Position_Cases, ROW_NUMBER() OVER (ORDER BY  total_deaths DESC) Position_Deaths, 
--	   ROW_NUMBER() OVER (ORDER BY total_deaths/ total_cases DESC) Position_Ratio
--FROM #CountriesTotals
--WHERE total_cases IS NOT NULL OR total_deaths IS NOT NULL AND Country <> 'North Korea'
--ORDER BY  ROW_NUMBER() OVER (ORDER BY  total_cases DESC)

/* It becomes quite clear that the Position in the Cases-Ranking and the position in the Deaths-Ranking are only loosely related, with especially European
   countries having comparativelly low ranks. One possible explanation would be that the actions different countries took indeed had an impact on the Amount of Deaths.
   The relation to the Position Ratio seems to be non-existent with smaller Asian, African and South American countries being on top here*/


---- Finding the Country for each Month since the onset of Covid which had the highest share of new infections
--WITH ByCountry AS
--	(SELECT Year(Date) Year, Month(Date) Month, Location, SUM(new_cases) NewCases, SUM(new_deaths) NewDeaths
--	 FROM CovidDeaths
--	 WHERE Location <> 'International'
--	 GROUP BY Year(Date), Month(Date), Location
--	 HAVING SUM(new_cases) <> 0),
--	 death_rate_per_month AS 
--	(SELECT Year, Month, Location, ROUND(NewDeaths/NewCases*100,3)  AS DeathRate
--	 FROM ByCountry)
--SELECT year, month, location, DeathRate
--FROM death_rate_per_month
--WHERE DeathRate = (SELECT MAX(DeathRate)
--				   FROM death_rate_per_month as dpm
--				   WHERE dpm.year = death_rate_per_month.year
--				   AND dpm.Month = death_rate_per_month.Month)
--ORDER BY year, month


-- According to that Query there would be countries who had Death Rates of 100 and even above. Under the assumption that some of these mistakes come from a number
-- of cases that is to small, I'll adjust the query so that it only looks at Months where more then 500 people died
--WITH ByCountry AS
--	(SELECT Year(Date) Year, Month(Date) Month, Location, SUM(new_cases) NewCases, SUM(new_deaths) NewDeaths
--	 FROM CovidDeaths
--	 WHERE Location <> 'International'
--	 GROUP BY Year(Date), Month(Date), Location
--	 HAVING SUM(new_cases) <> 0 AND SUM(new_deaths) > 500),
--	 death_rate_per_month AS 
--	(SELECT Year, Month, Location, ROUND(NewDeaths/NewCases*100,3)  AS DeathRate
--	 FROM ByCountry)
--SELECT year, month, location, DeathRate
--FROM death_rate_per_month
--WHERE DeathRate = (SELECT MAX(DeathRate)
--				   FROM death_rate_per_month as dpm
--				   WHERE dpm.year = death_rate_per_month.year
--				   AND dpm.Month = death_rate_per_month.Month)
--ORDER BY year, month
-- Returns much more realistic Results for most Months. However some still seem quite odd with Values over 100%

--Romania Has a 113% death rate in June 2021, let's examine this in more Detail:
--SELECT date, location, new_deaths, new_cases, new_deaths/new_cases * 100 Ratio 
--FROM CovidDeaths
--WHERE Year(date) = 2021 AND Month(date) = 6 AND location = 'Romania'

-- In the later part of the month the ratio is far above 100% which probably can only be explained by some errors in the generation of the data
-- They may have had cases where people came in just to die and where not anymore counted as New Cases


----------------------------------Continents------------------------------------
--- Death Rate by continent (still using the same temp table)

--SELECT continent, CONCAT(ROUND((SUM(total_deaths)/ SUM(total_cases) * 100), 2), '%') Ratio
--FROM #CountriesTotals
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY SUM(total_deaths)/ SUM(total_cases) DESC

----------------------------------Non Country Locations--------------------------
----- There are some Instances of Non-Country Locations in the Data, which can be found by looking for cases with NULL in Continent:
--SELECT DISTINCT(location)
--FROM CovidDeaths
--WHERE Continent IS NULL

--- Besides the different continents and a world and international instance, 
--- there are also Income Regions listed. Let's create a table Grouped by those Income locations:

--DROP TABLE IF EXISTS #IncomeClass
--CREATE TABLE #IncomeClasses (Classes NVARCHAR(50),
--							 Date DATE,
--							 Population BIGINT,
--							 Total_Cases FLOAT,
--							 Total_Deaths FLOAT,
--							 New_Cases FLOAT,
--							 New_Deaths FLOAT)
--INSERT INTO #IncomeClasses
--SELECT location, date, population, total_cases, total_deaths, new_cases, new_deaths
--FROM CovidDeaths
--WHERE location like '%income'

--Overview--
--SELECT *
--FROM #IncomeClasses

--Looking at Total Deaths, Total Cases and Death Cases Ratio in the different Income Regions--
--SELECT Classes, MAX(Total_Cases) Total_Cases, MAX(Total_Deaths) Total_Deaths, FORMAT(ROUND(MAX(Total_Deaths)/ MAX(Total_cases), 4),'P') Ratio
--FROM #IncomeClasses
--GROUP BY Classes
--ORDER BY MAX(Total_Deaths)/ MAX(Total_cases) DESC
---- Low Income Countries have the highest Ratio, followed by upper middle, lower middle and High Income.
---- According to the table there way more Total cases in High Income Countries than in Low income countries. However, this may be due to worse testing infrastructure