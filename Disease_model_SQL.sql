-- Creation of table for storing various types of diseases
CREATE TABLE disease_type(
    disease_type_cd CHAR(5) PRIMARY KEY, -- Primary Key for Disease Type
    disease_type_desc VARCHAR(1000) NOT NULL, -- Description of Disease Type
    notes TEXT -- Additional notes for Disease Type, increased field size for flexibility
);

-- Creation of table for storing details about diseases
CREATE TABLE disease(
    disease_id SERIAL PRIMARY KEY, -- Using SERIAL for auto-incrementing primary key
    disease_name VARCHAR(100) NOT NULL, -- Name of the Disease
    intensity_lvl_qty INT, -- Intensity level quantity, now allowing NULLs
    disease_type_cd CHAR(5) NOT NULL, -- Foreign key to Disease Type
    source_disease_cd CHAR(5), -- Allows NULL if no source disease
    FOREIGN KEY(disease_type_cd) REFERENCES disease_type(disease_type_cd)
        ON UPDATE CASCADE ON DELETE CASCADE -- Cascade updates/deletes to this foreign key
);

-- Creation of table for storing details about medicines
CREATE TABLE medicine(
    med_id SERIAL PRIMARY KEY, -- Using SERIAL for auto-incrementing primary key
    standard_ind_num VARCHAR(250), -- Standard Industry Number
    med_name VARCHAR(25) NOT NULL, -- Medicine Name
    company_name VARCHAR(150), -- Company Name
    active_ing_name VARCHAR(150) -- Active Ingredient Name
);

-- Creation of table for storing indications of medicines for diseases
CREATE TABLE indication(
    med_id INT NOT NULL,
    disease_id INT NOT NULL,
    indication_date DATE, -- Date of indication
    effectiveness NUMERIC(5, 2), -- Effectiveness percentage, now with precision
    PRIMARY KEY(med_id, disease_id), -- Composite primary key
    FOREIGN KEY(disease_id) REFERENCES disease(disease_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY(med_id) REFERENCES medicine(med_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Creation of table for storing different races
CREATE TABLE race(
    race_code CHAR(5) PRIMARY KEY, -- Primary Key for Race
    race_desc VARCHAR(100) NOT NULL -- Description of the Race
);

-- Creation of table for storing propensity of races for diseases
CREATE TABLE propensity(
    race_code CHAR(5),
    disease_id INT,
    propensity_value INT CHECK (propensity_value BETWEEN 1 AND 10), -- Ensuring value is within 1-10
    PRIMARY KEY(race_code, disease_id),
    FOREIGN KEY(race_code) REFERENCES race(race_code)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY(disease_id) REFERENCES disease(disease_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Creation of table for storing geographical locations
CREATE TABLE location(
    location_id SERIAL PRIMARY KEY, -- Using SERIAL for auto-incrementing primary key
    city_name VARCHAR(100) NOT NULL,
    state_name VARCHAR(100),
    county_name VARCHAR(100) NOT NULL,
    developing_flag CHAR(1), -- Flag to indicate if the location is developing
    wealth_rank_num INT CHECK (wealth_rank_num >= 1) -- Check constraint for wealth rank
);

-- Creation of table for storing personal details
CREATE TABLE person(
    person_id SERIAL PRIMARY KEY, -- Using SERIAL for auto-incrementing primary key
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    gender CHAR(1) NOT NULL CHECK (gender IN ('M', 'F', 'U')), -- Check constraint for gender
    location_id INT NOT NULL,
    race_code CHAR(5) NOT NULL,
    FOREIGN KEY(race_code) REFERENCES race(race_code)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY(location_id) REFERENCES location(location_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- Creation of table for storing patient disease records
CREATE TABLE patient(
    person_id INT NOT NULL,
    disease_id INT NOT NULL,
    severity_value INT NOT NULL DEFAULT 1, -- Default severity
    start_date DATE NOT NULL,
    end_date DATE,
    PRIMARY KEY(person_id, disease_id), -- Composite primary key
    FOREIGN KEY(disease_id) REFERENCES disease(disease_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY(person_id) REFERENCES person(person_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);


SELECT * FROM location;
SELECT * FROM race;
SELECT * FROM medicine;
SELECT * FROM disease_type;
SELECT * FROM disease;
SELECT * FROM indication;
SELECT * FROM propensity;
SELECT * FROM person;
SELECT * FROM patient;

-- Query to list all medicines and their indications for 'Tuberculosis'
SELECT 
    m.med_name, 
    m.active_ing_name, 
    i.effectiveness, 
    i.indication_date 
FROM 
    medicine m 
    JOIN indication i ON m.med_id = i.med_id 
WHERE 
    i.disease_id = (SELECT disease_id FROM disease WHERE disease_name = 'Tuberculosis'); 






-- Query to summarize the number of disease incidences by location
SELECT 
    l.city_name, 
    l.state_name, 
    COUNT(p.disease_id) AS disease_count 
FROM 
    patient p 
    JOIN person per ON p.person_id = per.person_id 
    JOIN location l ON per.location_id = l.location_id 
GROUP BY 
    l.city_name, l.state_name; 



-- Query to get details of patients suffering from 'HIV/AIDS'
SELECT 
    per.first_name, 
    per.last_name, 
    p.severity_value, 
    p.start_date, 
    p.end_date 
FROM 
    patient p 
    JOIN person per ON p.person_id = per.person_id s
WHERE 
    p.disease_id = (SELECT disease_id FROM disease WHERE disease_name = 'HIV/AIDS'); 



-- Query to analyze the propensity of races for different diseases
SELECT 
    r.race_desc, 
    d.disease_name, 
    pr.propensity_value 
FROM 
    propensity pr 
    JOIN race r ON pr.race_code = r.race_code 
    JOIN disease d ON pr.disease_id = d.disease_id 
ORDER BY 
    pr.propensity_value DESC; 


-- Query to count the number of diseases by their type
SELECT 
    dt.disease_type_desc, 
    COUNT(d.disease_id) AS disease_count 
FROM 
    disease d 
    JOIN disease_type dt ON d.disease_type_cd = dt.disease_type_cd 
GROUP BY 
    dt.disease_type_desc; 




--Dimensional Model

-- Creating a new schema for the data warehouse
CREATE SCHEMA IF NOT EXISTS disease_dw;

-- Dropping existing dimension and fact tables if they exist
DROP TABLE IF EXISTS disease_dw.factDisease, disease_dw.dimDisease, 
                  disease_dw.dimDisease_Type, disease_dw.dimPatient, 
                  disease_dw.dimPerson, disease_dw.dimLocation, 
                  disease_dw.dimRace, disease_dw.dimMedicine CASCADE;

-- Creating dimension table for Disease Type
CREATE TABLE disease_dw.dimDisease_Type(
    Disease_Type_Cd CHAR(5) PRIMARY KEY, 
    Disease_Type_Desc VARCHAR(1000) NOT NULL, 
    Notes VARCHAR(2000) 
);

-- Populating the dimDisease_Type table from the existing disease_type table
INSERT INTO disease_dw.dimDisease_Type 
SELECT Disease_Type_Cd, Disease_Type_Desc, Notes FROM disease_type;

-- Creating dimension table for Disease
CREATE TABLE disease_dw.dimDisease(
    Disease_Id INT PRIMARY KEY, 
    Disease_Name VARCHAR(100) NOT NULL, 
    Disease_Type_Cd CHAR(5) NOT NULL, -- Foreign Key to Disease Type
    Source_Disease_Cd CHAR(5) NOT NULL, -- Source Disease Code
    FOREIGN KEY(Disease_Type_Cd) REFERENCES disease_dw.dimDisease_Type(Disease_Type_Cd)
        ON UPDATE CASCADE ON DELETE CASCADE -- Cascade updates and deletes to this foreign key
);

-- Populating the dimDisease table from the existing disease table
INSERT INTO disease_dw.dimDisease 
SELECT Disease_Id, Disease_Name, Disease_Type_Cd, Source_Disease_Cd FROM disease;

-- Creating dimension table for Location in the data warehouse
CREATE TABLE disease_dw.dimLocation(
    Location_Id INT PRIMARY KEY, -- Primary Key for Location
    City_Name VARCHAR(100) NOT NULL, 
    State_Name VARCHAR(100), 
    County_Name VARCHAR(100) NOT NULL, 
    Developing_Flag CHAR(1), -- Flag indicating if the location is developing
    Wealth_Rank_Num INT NOT NULL -- Numerical ranking of wealth in the location
);

-- Populating the dimLocation table from the existing location table
INSERT INTO disease_dw.dimLocation 
SELECT Location_Id, City_Name, State_Name, County_Name, 
       Developing_Flag, Wealth_Rank_Num FROM location;

-- Creating dimension table for Race in the data warehouse
CREATE TABLE disease_dw.dimRace(
    Race_Code CHAR(5) PRIMARY KEY, -- Primary Key for Race
    Race_Desc VARCHAR(100) NOT NULL -- Description of the Race
);

-- Populating the dimRace table from the existing race table
INSERT INTO disease_dw.dimRace 
SELECT Race_Code, Race_Desc FROM race;







-- Creating dimension table for Person in the data warehouse
CREATE TABLE disease_dw.dimPerson(
    Person_Id INT PRIMARY KEY, -- Primary Key for Person
    Last_Name VARCHAR(50) NOT NULL, 
    First_Name VARCHAR(50) NOT NULL, 
    Gender CHAR(1) NOT NULL, 
    Location_Id INT NOT NULL, -- Foreign key to Location
    Race_Code CHAR(5) NOT NULL, -- Foreign key to Race
    FOREIGN KEY(Race_Code) REFERENCES disease_dw.dimRace(Race_Code)
        ON UPDATE CASCADE ON DELETE CASCADE, -- Cascade updates/deletes to Race
    FOREIGN KEY(Location_Id) REFERENCES disease_dw.dimLocation(Location_Id)
        ON UPDATE CASCADE ON DELETE CASCADE -- Cascade updates/deletes to Location
);

-- Populating the dimPerson table from the existing person table
INSERT INTO disease_dw.dimPerson 
SELECT Person_Id, Last_Name, First_Name, Gender, Location_Id, Race_Code FROM person;

-- Creating dimension table for Medicine in the data warehouse
CREATE TABLE disease_dw.dimMedicine(
    Med_Id INT PRIMARY KEY, -- Primary Key for Medicine
    Standard_Ind_Num VARCHAR(250), -- Standard Industry Number
    Med_Name VARCHAR(25) NOT NULL, -- Name of the Medicine
    Company_Name VARCHAR(150), -- Name of the Company that manufactures the Medicine
    Active_Ing_Name VARCHAR(150) -- Active Ingredient in the Medicine
);

-- Populating the dimMedicine table from the existing medicine table
INSERT INTO disease_dw.dimMedicine 
SELECT Med_Id, Standard_Ind_Num, Med_Name, Company_Name, Active_Ing_Name FROM medicine;


-- Drop the existing dimPatient table if it exists
DROP TABLE IF EXISTS disease_dw.dimPatient;


-- Creating dimension table for Patient in the data warehouse
CREATE TABLE disease_dw.dimPatient(
    Person_Id INT NOT NULL,
    Disease_Id INT NOT NULL,
    Severity_Value INT NOT NULL DEFAULT 1,
    Start_Date DATE NOT NULL,
    End_Date DATE,
    PRIMARY KEY(Person_Id, Disease_Id)  -- Composite primary key
);


-- Insert data into the dimPatient table from the patient table
INSERT INTO disease_dw.dimPatient
SELECT Person_Id, Disease_Id, Severity_Value, Start_Date, End_Date FROM patient;

-- Creating the fact table for Disease
CREATE TABLE disease_dw.factDisease(
    Disease_Id INT, 
    Person_Id INT, 
    Med_Id INT, 
    Severity_Value INT, -- Severity of the disease
    Intensity_Lvl_Qty INT, -- Intensity level quantity of the disease
    Indication_Date DATE, -- Date of medication indication
    Effectiveness FLOAT, -- Effectiveness of the medicine
    Propensity_Value INT, -- Propensity value related to race and disease
    FOREIGN KEY(Disease_Id) REFERENCES disease_dw.dimDisease(Disease_Id),
    FOREIGN KEY(Person_Id, Disease_Id) REFERENCES disease_dw.dimPatient(Person_Id, Disease_Id),
    FOREIGN KEY(Med_Id) REFERENCES disease_dw.dimMedicine(Med_Id)
);


-- Populating the factDisease table by joining data from OLTP tables
INSERT INTO disease_dw.factDisease
SELECT 
    a.Disease_Id AS Disease_Id,
    a.Person_Id AS Person_Id,
    c.Med_Id AS Med_Id,
    a.Severity_Value AS Severity_Value,
    b.Intensity_Lvl_Qty AS Intensity_Lvl_Qty,
    c.Indication_Date AS Indication_Date,
    c.Effectiveness AS Effectiveness,
    d.Propensity_Value AS Propensity_Value
FROM 
    patient a
    INNER JOIN disease b ON a.Disease_Id = b.Disease_Id
    INNER JOIN indication c ON a.Disease_Id = c.Disease_Id
    INNER JOIN medicine e ON c.Med_Id = e.Med_Id
    INNER JOIN propensity d ON a.Disease_Id = d.Disease_Id;

-- Sample queries to view data from the dimensional model and fact table
SELECT * FROM disease_dw.dimDisease;
SELECT * FROM disease_dw.factDisease;





-- Analytical Queries

-- Trend Analysis of Disease Incidence Over Time:
-- This query analyzes the yearly trend of different diseases based on the number of cases.

SELECT d.disease_name, COUNT(pt.disease_id) AS incidence_count, EXTRACT(YEAR FROM pt.start_date) AS year
FROM patient pt
JOIN disease d ON pt.disease_id = d.disease_id
GROUP BY d.disease_name, EXTRACT(YEAR FROM pt.start_date)
ORDER BY year, incidence_count DESC;




-- Geographical Distribution of Specific Diseases:
-- This query identifies the distribution of diseases across cities and states.

SELECT l.city_name, l.state_name, d.disease_name, COUNT(p.disease_id) AS cases
FROM patient p
JOIN person pr ON p.person_id = pr.person_id
JOIN location l ON pr.location_id = l.location_id
JOIN disease d ON p.disease_id = d.disease_id
GROUP BY l.city_name, l.state_name, d.disease_name
ORDER BY cases DESC;




-- Medication Effectiveness Analysis:
-- This query evaluates the effectiveness of medications for different diseases.

SELECT d.disease_name, m.med_name, AVG(i.effectiveness) AS average_effectiveness
FROM indication i
JOIN disease d ON i.disease_id = d.disease_id
JOIN medicine m ON i.med_id = m.med_id
GROUP BY d.disease_name, m.med_name
ORDER BY d.disease_name, average_effectiveness DESC;





--Correlation Between Race and Disease Propensity:
-- This query examines if certain races have higher propensities for specific diseases.

SELECT r.race_desc, d.disease_name, AVG(p.propensity_value) AS average_propensity
FROM propensity p
JOIN race r ON p.race_code = r.race_code
JOIN disease d ON p.disease_id = d.disease_id
GROUP BY r.race_desc, d.disease_name
ORDER BY average_propensity DESC;



-- Patient Demographics for Specific Diseases:
-- This query provides demographic insights (gender, race) for patients with specific diseases.
SELECT d.disease_name, pr.gender, r.race_desc, COUNT(*) AS patient_count
FROM patient p
JOIN person pr ON p.person_id = pr.person_id
JOIN race r ON pr.race_code = r.race_code
JOIN disease d ON p.disease_id = d.disease_id
GROUP BY d.disease_name, pr.gender, r.race_desc;


