-- ROLLING TOTAL WINDOWED FUNCTION 
-- EXECUTED THIS ORIGINALLY IN PYTHON, RATHER THAN SQL
-- SEE pynguins.py FILE

SELECT DISTINCT 
year, 
COUNT(*) AS count, 
SUM(COUNT(*)) OVER (ORDER BY year) AS running_total

FROM penguins
GROUP BY year