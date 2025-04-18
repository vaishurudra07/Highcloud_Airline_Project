use highcloud;
set sql_safe_updates = 0;


# --------------------------------------------*** For cards ***-----------------------------------------------------------------------
create view cards as
SELECT 
    count(distinct(`carrier name`)) as Total_Airline,           
    count(distinct(`origin country`)) as Total_country,
    COUNT(DISTINCT(`%Region Code`)) as Total_Region,
    SUM(Distance) AS Total_Distance,
    sum(`# Transported Passengers`) as Total_Passengers
FROM maindata;




# ------------------load factor Calculation------------
alter table maindata add column LoadFactor decimal(3,0);
update maindata set LoadFactor = 
			case when `# Transported Passengers` = 0 then null
            else (`# Transported Passengers` / `# Available Seats`)*100
            end;



# ------------------Datefield Calculation------------

alter table maindata 
     add column `Date` date,                           -- date field
     add column Weekday int,                           -- weekno
     add column `Weekdayname` varchar(10),             -- weekdayname
     add column monthname varchar(10),                 -- monthfullname
     add column Weekend_vs_Weekday varchar(10),        -- Weekend_vs_Weekday
     add column `Year_month` varchar(20),              -- Year_month
     add column `Quarter` varchar(10),                 -- Quarter
	 add column FinancialMonth varchar(10),            -- Financialmonth
	 add column FinancialQuarter varchar(10);          -- FinancialQuarter

update maindata set `Date` = concat(`year`,'-',`month (#)`,'-',`day`);
update maindata set Weekday = weekday(`date`);
update maindata set `Weekdayname` = dayname(`date`); 
update maindata set monthname = monthname(`date`) ;
update maindata set `Quarter` =  CONCAT("Q", QUARTER(`date`)) ;
UPDATE maindata SET `Year_month` = CONCAT(year, '-', MONTHNAME(date));
update maindata set Weekend_vs_Weekday = case weekday 
	when 5 then "Weekend"
	when 6 then "weekend"
	else "weekday"
	end;
UPDATE maindata SET FinancialMonth = CASE 
	WHEN `Month (#)` >= 4 THEN `Month (#)` - 3 
	ELSE `Month (#)` + 9 
	END;

 UPDATE maindata SET FinancialQuarter = CASE 
	WHEN `Month (#)` BETWEEN 4 AND 6 THEN 'Q1'
	WHEN `Month (#)` BETWEEN 7 AND 9 THEN 'Q2'
	WHEN `Month (#)` BETWEEN 10 AND 12 THEN 'Q3'
	ELSE 'Q4'
    END;              



#-------------------------------------------------*** QUE 1 ***---------------------------------------------------------------------
/*
"1.calcuate the following fields from the Year	Month (#)	Day  fields ( First Create a Date Field from Year , Month , Day fields)"
   A.Year
   B.Monthno
   C.Monthfullname
   D.Quarter(Q1,Q2,Q3,Q4)
   E. YearMonth ( YYYY-MMM)
   F. Weekdayno
   G.Weekdayname
   H.FinancialMOnth
   I. Financial Quarter 
   */

Create view KPI_1_datefiled as   
SELECT `date`, 
	`year`, 
	`month (#)` AS `monthno`, 
	`monthname`, 
	`Quarter`, 
	`year_month`,
	`weekday`, 
    `Weekdayname`,
	`Weekend_vs_Weekday`,
	concat("FM", FinancialMonth) as FinancialMonth,                                            
	FinancialQuarter                                    
FROM Maindata;






#------------------------------------------QUE 2---------------------------------------------------------------------
#2. Find the load Factor percentage on a yearly , Quarterly , Monthly basis ( Transported passengers / Available seats)

Create view KPI_2_yearly as
select `year`, 
		round((sum(LoadFactor) / (select sum(LoadFactor)from maindata)*100),2) as `LF%` 
        from maindata group by `year`;

Create view KPI_2_Quarterly as        
select `Quarter`, 
		round((sum(LoadFactor)/(select sum(LoadFactor) from maindata) * 100),2) as `LF%`
		from maindata group by `Quarter` order by `quarter`;

Create view KPI_2_Monthly as         
select `Month (#)`, 
		round((sum(LoadFactor)/(select sum(LoadFactor) from maindata) * 100),2) as `LF%`
		from maindata group by `Month (#)` order by `Month (#)` ;






#------------------------------------------QUE 3---------------------------------------------------------------------
#3. Find the load Factor percentage on a Carrier Name basis ( Transported passengers / Available seats)

create view KPI_3_CarrierBy_LF as
select `carrier name`, 
round((sum(LoadFactor)/(select sum(LoadFactor) from maindata) * 100),2) as `LF%`
from maindata
group by `carrier name`
order by sum(LoadFactor) desc limit 10;






#------------------------------------------QUE 4---------------------------------------------------------------------
#4. Identify Top 10 Carrier Names based passengers preference 

create view KPI_4_Top10Carrier_by_pp as
select `carrier name`, sum(`# Transported Passengers`) as Total_passengers
from maindata
group by `carrier name`
order by Total_passengers desc limit 10;






#------------------------------------------QUE 5---------------------------------------------------------------------
#5. Display top Routes ( from-to City) based on Number of Flights 

create view KPI_5_TopRoute as
select `From - To City`, count(`From - To City`) as flights_count
from maindata
group by `From - To City`
order by flights_count desc limit 5; 






#------------------------------------------QUE 6---------------------------------------------------------------------
#6. Identify the how much load factor is occupied on Weekend vs Weekdays.

create view KPI_6_Weekday_VS_weekend as
select Weekend_vs_Weekday, 
		round((sum(LoadFactor)/(select sum(LoadFactor) from maindata) * 100),2) as `LF%`
        from maindata group by Weekend_vs_Weekday order by sum(LoadFactor) desc;





#------------------------------------------QUE 7---------------------------------------------------------------------
#7. Identify number of flights based on Distance group

create view KPI_7_DistanceGroup as
SELECT 
    `%Distance Group ID` as Distance_group, 
    COUNT(*) AS Number_Of_Flights
FROM maindata
GROUP BY `%Distance Group ID`
ORDER BY Number_Of_Flights DESC limit 5;



