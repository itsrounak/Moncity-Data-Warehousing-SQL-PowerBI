-- DIMENSIONS

-- ********** Creating Maintenance Dimensions **********

-- DIM: MaintenanceTeamDIM
DROP TABLE maintenanceteamdim CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenanceteamdim
    AS
        (
            SELECT
                t.teamid,
                1 / COUNT(be.centerid) AS weight_factor,
                LISTAGG(be.centerid, '_') WITHIN GROUP(
                ORDER BY
                    be.centerid
                )                      AS teamgrouplist
            FROM
                moncity.maintenanceteam t,
                moncity.belongto        be
            WHERE
                be.teamid = t.teamid
            GROUP BY
                t.teamid
        );

-- DIM: MaintenanceTypeDim
DROP TABLE maintenancetypedim CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenancetypedim
    AS
        (
            SELECT
                maintenancetype
            FROM
                moncity.maintenancetype
        );

-- DIM: ResearchCenterDIM
DROP TABLE researchcenterdim CASCADE CONSTRAINTS PURGE;

CREATE TABLE researchcenterdim
    AS
        (
            SELECT
                centerid,
                centername
            FROM
                moncity.researchcenter
        );

-- Bridge: MaintenanceResearch 
DROP TABLE maintenanceresearchbridge CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenanceresearchbridge
    AS
        (
            SELECT
                *
            FROM
                moncity.belongto
        );

-- ********** Creating Booking Dimensions **********

-- DIM: PassengerDIM
DROP TABLE passengerdim CASCADE CONSTRAINTS PURGE;

CREATE TABLE passengerdim (
    passenger_age_id   VARCHAR2(10),
    passenger_age_desc VARCHAR2(50),
    age_max            NUMBER(3),
    age_min            NUMBER(3)
);

INSERT INTO passengerdim VALUES (
    'Group1',
    'Young Adults',
    18,
    35
);

INSERT INTO passengerdim VALUES (
    'Group2',
    'Middle-aged Adults',
    36,
    59
);

INSERT INTO passengerdim VALUES (
    'Group3',
    'Old-aged Adults',
    60,
    120
);

--DIM: FacultyDIM
DROP TABLE facultydim CASCADE CONSTRAINTS PURGE;

CREATE TABLE facultydim
    AS
        (
            SELECT
                facultyid,
                facultyname
            FROM
                moncity.faculty
        );

--DIM: TimeDIM
DROP TABLE timedim CASCADE CONSTRAINTS PURGE;

CREATE TABLE timedim
    AS
        (
            SELECT DISTINCT
                to_char(bookingdate, 'MM')    AS month_id,
                to_char(bookingdate, 'Month') AS month_desc
            FROM
                bookingclean
        );

-- ********** Creating Acident Dimensions **********

--DIM: ErrorCodeDIM
DROP TABLE errorcodedim CASCADE CONSTRAINTS PURGE;

CREATE TABLE errorcodedim
    AS
        (
            SELECT
                errorcode
            FROM
                moncity.error
        );

--DIM: AccidentZoneDIM
DROP TABLE accidentzonedim CASCADE CONSTRAINTS PURGE;

CREATE TABLE accidentzonedim
    AS
        (
            SELECT DISTINCT
                accidentzone
            FROM
                accidentinfoclean
        );

--DIM: CarDamageSeverityDIM
DROP TABLE cardamageseveritydim CASCADE CONSTRAINTS PURGE;

CREATE TABLE cardamageseveritydim
    AS
        (
            SELECT DISTINCT
                car_damage_severity
            FROM
                accidentinfoclean
        );

--DIM: V1_AccidentInfoDIM
DROP TABLE v1_accidentinfodim CASCADE CONSTRAINTS PURGE;

CREATE TABLE v1_accidentinfodim
    AS
        (
            SELECT
                i.accidentid,
                1 / COUNT(a.accidentid) AS weight_factor,
                LISTAGG(a.registrationno, '_') WITHIN GROUP(
                ORDER BY
                    i.accidentid
                )                       AS teamaccidentgouplist
            FROM
                accidentinfoclean   i,
                moncity.caraccident a
            WHERE
                i.accidentid = a.accidentid
            GROUP BY
                i.accidentid
        );

--BRIDGE: CarAccident
DROP TABLE caraccidentbridge CASCADE CONSTRAINTS PURGE;

CREATE TABLE caraccidentbridge
    AS
        (
            SELECT
                registrationno,
                accidentid
            FROM
                moncity.caraccident
        );

-- ********** Creating Shared Dimensions **********
--DIM: CarbodyDIM
DROP TABLE carbodydim CASCADE CONSTRAINTS PURGE;

CREATE TABLE carbodydim
    AS
        (
            SELECT DISTINCT
                carbodytype,
                numseats
            FROM
                moncity.car
        );

--DIM: CarDIM
DROP TABLE cardim CASCADE CONSTRAINTS PURGE;

CREATE TABLE cardim
    AS
        (
            SELECT DISTINCT
                registrationno,
                carbodytype,
                numseats
            FROM
                moncity.car
        );


--FACTS

-- ********** Creating Maintenance FACTS **********

DROP TABLE maintenancefact CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenancefact
    AS
        (
            SELECT
                m.maintenancetype,
                carbodytype,
                m.teamid,
                COUNT(DISTINCT m.maintenanceid) AS count_records,
                SUM(m.maintenancecost)          AS maintenance_cost
            FROM
                maintenanceclean        m,
                (
                    SELECT DISTINCT
                        be.teamid
                    FROM
                        moncity.maintenanceteam,
                        moncity.belongto be,
                        moncity.researchcenter
                )                       mte,
                moncity.maintenancetype ty,
                moncity.car             c
            WHERE
                    m.teamid = mte.teamid
                AND ty.maintenancetype = m.maintenancetype
                AND c.registrationno = m.registrationno
            GROUP BY
                m.maintenancetype,
                carbodytype,
                m.teamid
        );

-- ********** Creating Accident FACTS **********
DROP TABLE accidentfact CASCADE CONSTRAINTS PURGE;

CREATE TABLE accidentfact
    AS
        (
            SELECT
                accidentid,
                accidentzone,
                car_damage_severity,
                errorcode,
                COUNT(accidentid) AS accident_numbers
            FROM
                accidentinfoclean
            GROUP BY
                accidentid,
                accidentzone,
                car_damage_severity,
                errorcode
        );

-- ********** Creating Booking FACTS **********
-- Creating tempfact 
DROP TABLE bookingtempfact CASCADE CONSTRAINTS PURGE;

CREATE TABLE bookingtempfact
    AS
        (
            SELECT
                to_char(bookingdate, 'MM') AS monthid,
                f.facultyid,
                b.bookingid,
                c.carbodytype,
                p.passengerage
            FROM
                bookingclean    b,
                passengerclean  p,
                moncity.faculty f,
                moncity.car     c
            WHERE
                    b.passengerid = p.passengerid
                AND f.facultyid = p.facultyid
                AND b.registrationno = c.registrationno
        );

ALTER TABLE bookingtempfact ADD (
    passenger_age_id VARCHAR(15)
);

UPDATE bookingtempfact
SET
    passenger_age_id = 'Group 1'
WHERE
    ( passengerage BETWEEN 18 AND 35 );

UPDATE bookingtempfact
SET
    passenger_age_id = 'Group 2'
WHERE
    ( passengerage BETWEEN 36 AND 59 );

UPDATE bookingtempfact
SET
    passenger_age_id = 'Group 3'
WHERE
    ( passengerage BETWEEN 60 AND 120 );


-- Creating BookingFACT
DROP TABLE bookingfact CASCADE CONSTRAINTS PURGE;

CREATE TABLE bookingfact
    AS
        (
            SELECT
                facultyid,
                carbodytype,
                passenger_age_id,
                monthid,
                COUNT(bookingid) AS number_of_bookings
            FROM
                bookingtempfact
            GROUP BY
                facultyid,
                carbodytype,
                passenger_age_id,
                monthid
        );