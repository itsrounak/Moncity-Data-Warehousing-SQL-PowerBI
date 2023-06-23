-- Report 1: MonCity's cummulative number of booking records of each month for IT Faculty 

SELECT
    b.facultyid,
    t.month_desc              AS "Month",
    SUM(b.number_of_bookings) AS "Total Bookings",
    to_char(SUM(SUM(number_of_bookings))
            OVER(
        ORDER BY
            b.facultyid,
            TO_DATE(t.month_desc, 'Month')
        ROWS UNBOUNDED PRECEDING
            ),
            '9,999,999')      AS "Cumulative number of booking records"
FROM
    bookingfact b,
    timedim     t
WHERE
        b.monthid = t.month_id
    AND b.facultyid = 'FIT'
GROUP BY
    b.facultyid,
    t.month_desc
ORDER BY
    MIN(t.month_id);

-- Report 2: MonCity's maintenance report

SELECT
    decode(GROUPING(teamid),
           1,
           'All Teams',
           teamid)       AS "Team ID",
    decode(GROUPING(carbodytype),
           1,
           'All Car Body Types',
           carbodytype)  AS "Car body type",
    SUM(count_records)   AS "Total number of maintenance",
    to_char(SUM(maintenance_cost),
            '9,999,999') AS "Total maintenance cost"
FROM
    maintenancefact
WHERE
    teamid IN ( 'T002', 'T003' )
GROUP BY
    CUBE(teamid,
         carbodytype);

-- Report 3: Number of accidents

SELECT
    *
FROM
    (
        SELECT
            f.errorcode         AS "Error Code",
            c.registrationno    AS "Registration No.",
            c.carbodytype       AS "Car Body Type",
            COUNT(f.accidentid) AS "Total Number of accidents",
            DENSE_RANK()
            OVER(PARTITION BY f.errorcode
                 ORDER BY
                     COUNT(f.accidentid) DESC
            )                   AS rank
        FROM
            accidentfact      f,
            accidentinfoclean       a,
            caraccidentbridge b,
            cardim            c
        WHERE
                f.accidentid = a.accidentid
            AND b.accidentid = f.accidentid
            AND c.registrationno = b.registrationno
        GROUP BY
            f.errorcode,
            c.registrationno,
            c.carbodytype
        ORDER BY
            f.errorcode
    )
WHERE
    rank <= 3;
-----Report 4: MonCity's booking report

SELECT
    carbodytype              AS "Car body type",
    decode(GROUPING(passenger_age_id),
           1,
           'All Age groups',
           passenger_age_id) AS "Age Group",
    decode(GROUPING(facultyid),
           1,
           'All faculties',
           facultyid)        AS "Faculty ID",
    to_char(SUM(number_of_bookings),
            '99,999,999')    AS "Total number of bookings"
FROM
    bookingfact
WHERE
    carbodytype = 'People Mover'
GROUP BY
    carbodytype,
    CUBE(passenger_age_id,
         facultyid);