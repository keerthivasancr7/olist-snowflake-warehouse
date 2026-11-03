{{ config(materialized='table', schema='CORE') }}

with dates as (
    select
        dateadd(
            day,
            row_number() over (order by seq4()) - 1,
            '2016-01-01'::date
        )::date as date_day
    from table(generator(rowcount => 5479))
)

select
    to_number(to_char(date_day, 'YYYYMMDD')) as date_key,
    date_day,
    year(date_day) as calendar_year,
    quarter(date_day) as calendar_quarter,
    month(date_day) as month_number,
    monthname(date_day) as month_name,
    date_trunc('month', date_day)::date as month_start,
    day(date_day) as day_of_month,
    dayofweekiso(date_day) as weekday_number,
    dayofweekiso(date_day) in (6, 7) as is_weekend
from dates
