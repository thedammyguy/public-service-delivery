-- Add age column to the Citizens Table
ALTER TABLE SQL_Capstone_Project.dbo.Citizens_Table
ADD AGE INT NULL;


--Calculating the age of each citizen that took the survey
UPDATE SQL_Capstone_Project.dbo.Citizens_Table
SET AGE = DATEDIFF(YEAR, Date_Of_Birth, GETDATE());


-- Changing the datatype of the income_level column
ALTER TABLE SQL_Capstone_Project.dbo.Citizens_Table
ALTER COLUMN Income_Level DECIMAL(18,2);


--Removing the dollar sign in front of every cell in income_Level column of citizens_Table
UPDATE SQL_Capstone_Project.dbo.Citizens_Table
SET Income_Level = CAST(REPLACE(Income_Level, '$', '') AS decimal(18, 2));


--Creating the income level demography column
ALTER TABLE SQL_Capstone_Project.dbo.Citizens_Table
ADD Income_Level_Demography NVARCHAR(255) NULL;


-- Populating the income_level_Demography column
UPDATE SQL_Capstone_Project.dbo.Citizens_Table
SET Income_Level_Demography = CASE 
	WHEN Income_Level <= 20000 THEN 'Very Low Earner'
	WHEN Income_Level <=60000 THEN 'Low Earner'
	WHEN Income_Level <= 100000 THEN 'Average Earner'
	WHEN Income_Level >100000 THEN 'Big Pay-day Earner'
END;


-- Populating the null values in the service_Name Column of the Service_Table
UPDATE SQL_Capstone_Project.dbo.Service_Table
SET Service_Name = CASE 
    WHEN Department = 'Department of Labor' THEN 'Wages'
    WHEN Department = 'Department of Energy' THEN 'Electricity'
    WHEN Department = 'Departmnet of Housing and Urban Development' THEN 'Housing and Development'
    WHEN Department = 'Departmnet of Health' THEN 'HealthCare'
	WHEN Department = 'Departmnet of Education' THEN 'Education'
END
WHERE Service_Name IS NULL;



--Removing the dollar sign in front of every cell in Budget column of Service Table, and casting it as a decimal 
UPDATE SQL_Capstone_Project.dbo.Service_Table
SET Budget = CAST(REPLACE(Budget, '$', '') AS decimal(18, 2));



-- Changing the data type of the budget column of service_Table
ALTER TABLE SQL_Capstone_Project.dbo.Service_Table
ALTER COLUMN Budget DECIMAL(18,2);



--ADD a new budget classification column to the [Service Table]
ALTER TABLE SQL_Capstone_Project.dbo.Service_Table
ADD Budget_Classification NVARCHAR(255) NULL;


--Filling the cells of Budget Classification
UPDATE Service_Table
SET Budget_Classification = CASE 
	WHEN Budget < 20000000 THEN 'Poorly Funded'
	WHEN Budget <= 40000000 THEN 'Modestly Funded'
	WHEN Budget > 40000000 THEN 'Heavily Funded'
END;


-- Adding a new column to classify the ratings given by each citizen for different services 
ALTER TABLE SQL_Capstone_Project.dbo.Feedback_Table$
ADD Rating_Classification NVARCHAR(255) NULL;


--Filling the cells of Rating_Classification
UPDATE Feedback_Table$
SET Rating_Classification = CASE 
	WHEN Rating < 2 THEN 'Bad'
	WHEN Rating <= 3.8 THEN 'Neutral'
	WHEN Rating >3.8 THEN 'Good'
END;



-- Adding a new column to classify the days taken to solve the complaints of each citizen
ALTER TABLE SQL_Capstone_Project.dbo.Feedback_Table$
ADD Response_Time_Classification NVARCHAR(255) NULL;


--Filling the cells of Response_Time_Classification
UPDATE Feedback_Table$
SET Response_Time_Classification = CASE 
	WHEN days_to_resolution < 7 THEN 'Timely'
	WHEN days_to_resolution <= 15 THEN 'Normal'
	WHEN days_to_resolution >15 THEN 'Late'
END;



CREATE VIEW Service_Satisfaction_Summary AS
SELECT
	s.Service_ID,
    s.Service_Name,
    s.Department,
    s.State,
	s.City,
    ROUND(AVG(f.Rating), 2) AS Avg_Rating,
    COUNT(f.Feedback_ID) AS Total_Feedback_Count,
    SUM(CASE WHEN f.Resolution_Status = 'Resolved' THEN 1 ELSE 0 END) AS Resolved_Count,
    ROUND(AVG(f.days_to_resolution), 2) AS Avg_Resolution_Days,
    s.Budget,
	s.Budget_Classification,
    s.Employee_Count
FROM SQL_Capstone_Project.dbo.Service_Table s
LEFT JOIN SQL_Capstone_Project.dbo.Feedback_Table$ f ON s.Service_ID = f.[Service-ID]
GROUP BY 
	s.Service_ID,
    s.Service_Name,
    s.Department,
    s.State,
	s.City,
    s.Budget,
	s.[Budget_Classification],
    s.Employee_Count;




-- Creating the Citizen Feedback Analysis View
CREATE VIEW Citizen_Feedback_Analysis AS
SELECT 
    c.Citizen_ID,
    c.Name,
	c.Gender,
	c.AGE,
	c.Income_Level_Demography,
    c.State AS Citizen_State,
    c.Employment_Status,
    f.[Service-ID],
    s.Service_Name,
    f.Rating,
    f.Feedback_Date,
    f.Resolution_Status,
	f.Rating_Classification,
	Response_Time_Classification
FROM Citizens_Table c
JOIN Feedback_Table$ f ON c.Citizen_ID = f.Citizen_ID
JOIN Service_Table s ON f.[Service-ID] = s.Service_ID;




-- Cleaning the Amount column in payment Table to remove the dollar sign and make it a FLOAT Datatype
UPDATE TDI_Capstone_Project.dbo.payment
SET Amount = CAST(REPLACE(Amount, '$', '') AS FLOAT);


-- Cleaning the Amount column in Contracts Table to remove the dollar sign and make it a FLOAT Datatype
UPDATE TDI_Capstone_Project.dbo.Contracts
SET Budget = CAST(REPLACE(Budget, '$', '') AS decimal(18,2));


-- Rename the column current_status to project_status in the contracts table
EXEC sp_rename 'TDI_Capstone_Project.dbo.Contracts.contract_status', 'Project_Status', 'COLUMN'


--Standardize the Projet_Status fields to start with capital letters 
UPDATE TDI_Capstone_Project.dbo.Contracts
SET Project_Status = CASE 
	WHEN Project_Status = 'ongoing' THEN 'Ongoing'
	WHEN Project_Status = 'abandoned' THEN 'Delayed'
	WHEN Project_Status = 'completed' THEN 'Completed'
END;



-- Merging contracts table and vendors table into a new table with a LEFT JOIN
SELECT C.Vendor_ID, C.Contract_ID, V.Vendor_Name, V.Specialization, V.Country, C.Contract_Start_Date, C.Contract_End_Date, C.Budget, C.Project_Status, C.contract_Region
INTO Vendor_contract_Details2
FROM TDI_Capstone_Project.dbo.Contracts C
LEFT JOIN TDI_Capstone_Project.dbo.Vendors V
ON C.Vendor_ID = V.Vendor_ID
ORDER BY C.VENDOR_ID;




-- Merging the combined table with the payment table 
SELECT CV.Vendor_ID, CV.Vendor_Name, CV.Specialization, CV.Country, CV.Contract_Start_Date, CV.Contract_End_Date, CV.Budget, CV.Project_Status, CV.contract_Region,P.Amount, P.Payment_Mathod
INTO Combined_Dataset
FROM TDI_Capstone_Project.dbo.Vendor_contract_Details2 CV
RIGHT JOIN TDI_Capstone_Project.dbo.payment  P
ON CV.Contract_ID = P.Contract_ID



SELECT CV.Vendor_ID, CV.Vendor_Name, CV.Specialization, CV.Country, CV.Contract_Start_Date, CV.Contract_End_Date, CV.Budget, CV.Project_Status, CV.contract_Region,P.Amount, P.Payment_Mathod
FROM TDI_Capstone_Project.dbo.Vendor_contract_Details2 CV
FULL OUTER JOIN TDI_Capstone_Project.dbo.payment  P
ON CV.Contract_ID = P.Contract_ID
order by cv.Vendor_Name



--calculating the average rating
SELECT AVG(Rating) AS Average_rating
FROM SQL_Capstone_Project.dbo.Final_Table


--calculating the average resolution days
SELECT AVG(days_to_resolution) AS Average_resolution_day
FROM SQL_Capstone_Project.dbo.Final_Table



--calculating tOtal budget allocated
SELECT SUM(Budget) AS Average_resolution_day
FROM SQL_Capstone_Project.dbo.Final_Table


--Sorting the states with the highest average satisfaction rating
SELECT State, AVG(Rating) AS Average_satisfaction_rating
FROM SQL_Capstone_Project.dbo.Final_Table
GROUP BY State
ORDER BY Average_satisfaction_rating DESC;



--- checking the services rendered and their average rating
SELECT Corresponding_Service_Name, AVG(Rating) AS Average_satisfaction_rating
FROM SQL_Capstone_Project.dbo.Final_Table
GROUP BY Corresponding_Service_Name
ORDER BY Average_satisfaction_rating DESC;




--- checking the average rating rating of Departments
SELECT Department, AVG(Rating) AS Average_satisfaction_rating
FROM SQL_Capstone_Project.dbo.Final_Table
GROUP BY Department
ORDER BY Average_satisfaction_rating DESC;




--- checking the quality of service rendered to different gender groups
SELECT Gender, AVG(Rating) AS Average_satisfaction_rating
FROM SQL_Capstone_Project.dbo.Final_Table
GROUP BY Gender
ORDER BY Average_satisfaction_rating DESC;



--- checking the average rating based on response time
SELECT Response_Time_Classification, AVG(Rating) AS Average_satisfaction_rating
FROM SQL_Capstone_Project.dbo.Final_Table
GROUP BY Response_Time_Classification
ORDER BY Average_satisfaction_rating DESC;


--- checking the average rating based on resolution status
SELECT resolution_status, AVG(Rating) AS Average_satisfaction_rating
FROM SQL_Capstone_Project.dbo.Final_Table
GROUP BY resolution_status
ORDER BY Average_satisfaction_rating DESC;