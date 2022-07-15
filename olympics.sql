
-- replace strings so that all strings are consistent 
Update olympics..programs2020 
Set NGB = REPLACE(NGB, 'US ', 'USA ')

Update olympics..programs2019 
Set NGB = REPLACE(NGB, 'US ', 'USA ')

Update olympics..training2020 
Set NGB = REPLACE(NGB, 'US ', 'USA ')

Update olympics..training2019
Set NGB = REPLACE(NGB, 'US ', 'USA ')

Update olympics..NGBHealthDataOutput
Set [Overall Parent NGB] = REPLACE([Overall Parent NGB], 'US ', 'USA ')

Update olympics..medals
Set [Event] = 'USA ' + [Event]

--------------------------------------------------------
-- get sum of all training facility numbers for each NGB
Alter Table training2019
Add Total money
Update olympics..training2019
Set Total = [Chula Vista, California] + [Colorado Springs, Colorado] + [Lake Placid, New York] + [Salt Lake City, Utah]
From olympics..training2019

Alter Table olympics..training2020
Add Total money
Update olympics..training2020
Set Total = [Chula Vista, California] + [Colorado Springs, Colorado] + [Lake Placid, New York] + [Salt Lake City, Utah]
From olympics..training2020

---------------------------------------------------------
-- add column for year 
Alter Table olympics..training2019
Add Year int
Update olympics..training2019
Set Year = 2019
From olympics..training2019

Alter Table olympics..training2020
Add Year int
Update olympics..training2020
Set Year = 2020
From olympics..training2020

Alter Table olympics..programs2019
Add Year int
Update olympics..programs2019
Set Year = 2019
From olympics..programs2019

Alter Table olympics..programs2020
Add Year int
Update olympics..programs2020
Set Year = 2020
From olympics..programs2020

--------------------------------------------------------
-- calculate profit
Alter Table olympics..NGBHealthDataOutput
Add Profit float
Update olympics..NGBHealthDataOutput
Set Profit = [Total Revenue] - [Total Expenses]
From olympics..NGBHealthDataOutput

-- get number of medals won, total programs resource allocation, and 2019 profit for each NGB
-- this query will be used for Tableau scatterplot
Select NGB, Total, Profit, Count(*) As Number_of_Medals From olympics..programs2020
Join olympics..medals 
On programs2020.NGB = medals.[Event]
Join olympics..NGBHealthDataOutput
On programs2020.NGB = NGBHealthDataOutput.[Overall Parent NGB]
Where NGBHealthDataOutput.[Overall Year] = 2019
Group By NGB, Total, Profit
Order By Number_of_Medals

-- get number of medals won, total facilities resource allocation, and 2019 profit for each NGB
-- this query will be used for Tableau scatterplot
Select NGB, Total, Profit, Count(*) As Number_of_Medals From olympics..training2020
Join olympics..medals
On training2020.NGB = medals.[Event]
Join olympics..NGBHealthDataOutput
On training2020.NGB = NGBHealthDataOutput.[Overall Parent NGB]
Where NGBHealthDataOutput.[Overall Year] = 2019
Group By NGB, Total, Profit
Order By Number_of_Medals

-----------------------------------------------------------
-- add new column to training facilities tables and set all values to 'Training Facility'
Alter Table olympics..training2019
Add Resource_Type nvarchar(255)
Update olympics..training2019
Set Resource_Type = 'Training Facility'
From olympics..training2019

Alter Table olympics..training2020
Add Resource_Type nvarchar(255)
Update olympics..training2020
Set Resource_Type = 'Training Facility'
From olympics..training2020

-- add new column to programs tables and set all values to 'High Performance Program'
Alter Table olympics..programs2019
Add Resource_Type nvarchar(255)
Update olympics..programs2019
Set Resource_Type = 'High Performance Program'
From olympics..programs2019

Alter Table olympics..programs2020
Add Resource_Type nvarchar(255)
Update olympics..programs2020
Set Resource_Type = 'High Performance Program'
From olympics..programs2020

---------------------------------------------------------
-- make new table to combine parts from all training and programs tables
-- this new table will be used to create bar chart in Tableau
Create Table #resource_allocation(
	NGB nvarchar(255),
	Total float,
	Year int,
	Resource_Type nvarchar(255)
)

Insert Into #resource_allocation
Select NGB, Total, Year, Resource_Type From olympics..programs2019
Union
Select NGB, Total, Year, Resource_Type From olympics..programs2020
Union 
Select NGB, Total, Year, Resource_Type From olympics..training2019
Union 
Select NGB, Total, Year, Resource_Type From olympics..training2020

-- Calculate averages of resource allocation amounts for Paralympic bodies and Olympic bodies
Select AVG(Total) From #resource_allocation
Where NGB LIKE '%Paralympic%' OR NGB LIKE '%Blind%' OR NGB LIKE '%Wheelchair%'
Union
Select AVG(Total) From #resource_allocation
Where NGB NOT LIKE '%Paralympic%' AND NGB NOT LIKE '%Blind%' AND NGB NOT LIKE '%Wheelchair%'
----------------------------------------------------------