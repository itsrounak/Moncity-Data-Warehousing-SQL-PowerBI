---- Report 5 Rollup

SELECT
    decode(GROUPING(facultyname),
           1,
           'All Faculty',
           facultyname)          AS "Faculty Name",
    decode(GROUPING(p.passenger_age_desc),
           1,
           'All Age Groups',
           p.passenger_age_desc) AS "Age Group",
    decode(GROUPING(month_desc),
           1,
           'All Months',
           month_desc)           AS "Months",
    lpad(to_char(SUM(number_of_bookings),
                 '99,999'),
         20,
         ' ')                    AS "Total number of bookings"
FROM
    bookingfact  b,
    timedim      t,
    passengerdim p,
    facultydim   f
WHERE
        b.monthid = t.month_id
    AND b.facultyid = f.facultyid
    AND p.passenger_age_id = b.passenger_age_id
GROUP BY
    ROLLUP(facultyname,
           p.passenger_age_desc,
           t.month_desc);

----Report 6 Rollup

SELECT
    decode(GROUPING(p.passenger_age_desc),
           1,
           'All Age Groups',
           p.passenger_age_desc) AS "Age Group",
    decode(GROUPING(facultyname),
           1,
           'All Faculty',
           facultyname)          AS "Faculty Name",
    decode(GROUPING(month_desc),
           1,
           'All Months',
           month_desc)           AS "Months",
    lpad(to_char(SUM(number_of_bookings),
                 '99,999'),
         20,
         ' ')                    AS "Total number of bookings"
FROM
    bookingfact  b,
    timedim      t,
    passengerdim p,
    facultydim   f
WHERE
        b.monthid = t.month_id
    AND b.facultyid = f.facultyid
    AND p.passenger_age_id = b.passenger_age_id
GROUP BY
    p.passenger_age_desc,
    ROLLUP(t.month_desc,
           facultyname);

---Report 7 

SELECT
    monthid,
    carbodytype,
    SUM(number_of_bookings) AS "Number of bookings",
    to_char(AVG(SUM(number_of_bookings))
            OVER(
        ORDER BY
            monthid
        ROWS 2 PRECEDING
            ),
            '9,999,999.99') AS "Two Months Moving Average"
FROM
    bookingfact
GROUP BY
    monthid,
    carbodytype;

---Report 8

SELECT
    maintenancetype,
    carbodytype,
    SUM(count_records)       AS "Total number of maintenance Record",
    to_char(SUM(maintenance_cost),
            '9,999,999,999') AS "Total maintenance cost",
    to_char(SUM(SUM(maintenance_cost))
            OVER(
        ORDER BY
            maintenancetype,
            carbodytype
        ROWS UNBOUNDED PRECEDING
            ),
            '9,999,999,999') AS "Cummulative total maintenance cost"
FROM
    maintenancefact
GROUP BY
    maintenancetype,
    carbodytype;