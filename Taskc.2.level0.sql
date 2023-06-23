-- DIMENSIONS

-- ********** Creating Maintenance Dimensions **********

-- DIM: MaintenanceDIM
DROP TABLE maintenancedim CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenancedim
    AS
        (
            SELECT
                maintenanceid
            FROM
                maintenanceclean
        );

-- DIM: MaintenanceTeamDIM
DROP TABLE maintenanceteamdim CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenanceteamdim
    AS
        (
            SELECT
                teamid
            FROM
                moncity.maintenanceteam
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

CREATE TABLE passengerdim
    AS
        (
            SELECT
                passengerid,
                passengerage
            FROM
                passengerclean
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
            SELECT
                bookingdate
            FROM
                bookingclean
        );


-- ********** Creating Acident Dimensions **********

--DIM: CarDIM
DROP TABLE cardim CASCADE CONSTRAINTS PURGE;

CREATE TABLE cardim
    AS
        (
            SELECT DISTINCT
                registrationno,
                carbodytype
            FROM
                moncity.car
        );

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

--DIM: CarAccidentDIM 
DROP TABLE caraccidentdim CASCADE CONSTRAINTS PURGE;

CREATE TABLE caraccidentdim
    AS
        (
            SELECT
                registrationno,
                accidentid
            FROM
                moncity.caraccident
        );

--DIM: V2_AccidentInfoDIM 
DROP TABLE v2_accidentinfodim CASCADE CONSTRAINTS PURGE;

CREATE TABLE v2_accidentinfodim
    AS
        (
            SELECT
                accidentid
            FROM
                accidentinfoclean
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


--FACTS

-- ********** Creating Maintenance FACTS **********

DROP TABLE maintenancefact CASCADE CONSTRAINTS PURGE;

CREATE TABLE maintenancefact
    AS
        (
            SELECT
                m.maintenanceid,
                m.maintenancetype,
                c.carbodytype,
                m.teamid,
                COUNT(DISTINCT maintenanceid) AS record_numbers,
                SUM(maintenancecost)          AS total_cost
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
                c.carbodytype,
                m.teamid,
                m.maintenanceid
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
DROP TABLE bookingfact CASCADE CONSTRAINTS PURGE;

CREATE TABLE bookingfact
    AS
        (
            SELECT
                f.facultyid,
                c.carbodytype,
                p.passengerage,
                b.bookingdate,
                b.bookingid,
                COUNT(b.bookingid) AS number_of_bookings
            FROM
                bookingclean    b,
                passengerclean  p,
                moncity.car     c,
                moncity.faculty f
            WHERE
                    b.registrationno = c.registrationno
                AND f.facultyid = p.facultyid
                AND p.passengerid = b.passengerid
            GROUP BY
                f.facultyid,
                b.bookingid,
                c.carbodytype,
                p.passengerage,
                b.bookingdate
        );