-- Checking the relationship between the tables --

--1. passenger and faculty
SELECT
    *
FROM
    moncity.passenger
WHERE
    facultyid NOT IN (
        SELECT
            facultyid
        FROM
            moncity.faculty
    );

--creating new passenger table
DROP TABLE passengerclean CASCADE CONSTRAINTS PURGE;

CREATE TABLE passengerclean
    AS
        (
            SELECT
                *
            FROM
                moncity.passenger
            WHERE
                passengerid NOT IN (
                    SELECT
                        passenger.passengerid
                    FROM
                        moncity.passenger
                    WHERE
                        facultyid NOT IN (
                            SELECT
                                facultyid
                            FROM
                                moncity.faculty
                        )
                )
        );

--2. Error and accident 
SELECT
    *
FROM
    moncity.accidentinfo
WHERE
    errorcode NOT IN (
        SELECT
            errorcode
        FROM
            moncity.error
    );

--creating new accident info table
DROP TABLE accidentinfoclean CASCADE CONSTRAINTS PURGE;

CREATE TABLE accidentinfoclean
    AS
        (
            SELECT
                *
            FROM
                moncity.accidentinfo
            WHERE
                accidentid NOT IN (
                    SELECT
                        accidentinfo.accidentid
                    FROM
                        moncity.accidentinfo
                    WHERE
                        errorcode NOT IN (
                            SELECT
                                errorcode
                            FROM
                                moncity.accidentinfo
                        )
                )
        );


-- checking for null values 
SELECT
    *
FROM
    moncity.accidentinfo
WHERE
    accidentid IS NULL;

DELETE FROM accidentinfoclean
WHERE
    accidentid IS NULL;


--checking for duplicate values 
SELECT
    bookingid,
    COUNT(*) AS "Duplicate Count"
FROM
    moncity.booking
GROUP BY
    bookingid
HAVING
    COUNT(*) > 1;

--creating new booking table
DROP TABLE bookingclean CASCADE CONSTRAINTS PURGE;

CREATE TABLE bookingclean
    AS
        (
            SELECT DISTINCT
                *
            FROM
                moncity.booking
        );



-- checking for incorrect values 
SELECT
    *
FROM
    moncity.maintenance
WHERE
    maintenancecost < 0;

--creating new maintenance table 
DROP TABLE maintenanceclean CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenanceclean
    AS
        (
            SELECT
                *
            FROM
                moncity.maintenance
            WHERE
                maintenancecost > 0
        );