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



--------------------------------Worldwide---------------------------------
---Creating a temp-table with the current total values (total_cases, total_deaths etc.)  
--DROP TABLE IF EXISTS #CountriesTotals
--CREATE TABLE #CountriesTotals (Country NVARCHAR(50), Continent NVARCHAR(50), Population BIGINT, total_cases BIGINT, total_deaths INT, total_cases_pm FLOAT, total_deaths_pm FLOAT)

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

---- Comparing positions different countries have in total cases, total deaths, 


---- Total Death by total cases ratio by country
--SELECT location, MAX(total_deaths)/ MAX(total_cases) Ratio
--FROM CovidDeaths
--GROUP BY location
--ORDER BY Ratio DESC

--- Death Rate by continent


--SELECT continent, ROUND((SUM(total_deaths)/ SUM(total_cases) * 100), 2) Ratio
--FROM #CountriesTotals
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY SUM(total_deaths)/ SUM(total_cases) DESC

---- Finding the Country for each Month since the onset of Covid which had the highest share of infections
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

--Romania Has a 113% death rate in June 2021:
--SELECT date, location, new_deaths, new_cases, new_deaths/new_cases * 100 Ratio 
--FROM CovidDeaths
--WHERE Year(date) = 2021 AND Month(date) = 6 AND location = 'Romania'
-- In the later part of the month the ratio is far above 100% which probably can only be explained by some errors in the generation of the data
-- They probably had cases where people came in just to die and where not anymore counted as New Cases
