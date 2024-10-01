-- Metlife, CreditCarma
-- Write a query that returns the user ID of all users that have created at least one ‘Refinance’ submission and at least one ‘InSchool’ submission.


select distinct(user_id) 
from loans
where type ='Refinance'
INTERSECT
select distinct(user_id) 
from loans
where type ='InSchool';


-- Meta
-- Return the total number of comments received for each user in the 30 or less days before 2020-02-10. Don't output users who haven't received any comment in the defined time period.

select user_id, sum(number_of_comments) as total_comments 
from fb_comments_count
where created_at >= dateadd(day, -30, '2020-02-10') and created_at <= '2020-02-10'
group by user_id;

-- Meta
-- Return a distribution of users activity per day of the month. By distribution we mean the number of posts per day of the month.


select right(convert(DATE, post_date),1) as posted_date, count(distinct post_id) daily_posts
from facebook_posts
group by convert(DATE, post_date);


SELECT DATEPART(day, post_date) as day,
       COUNT(*) as counter
FROM facebook_posts
GROUP BY DATEPART(day, post_date)

-- Twitch
-- Find users who are both a viewer and streamer.

select user_id 
from twitch_sessions
where session_type='streamer'
INTERSECT
select user_id 
from twitch_sessions
where session_type='viewer';

SELECT user_id
FROM twitch_sessions
GROUP BY user_id
HAVING COUNT(DISTINCT session_type) = 2;

---------------------------------------------------------------------------------------------------------------- FREE ---------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Amazon
-- Write a query that will calculate the number of shipments per month. The unique key for one shipment is a combination of shipment_id and sub_id. Output the year_month in format YYYY-MM and the number of shipments in that month.

select CONVERT(varchar(7), shipment_date, 120) as shipment_month, 
count(distinct concat(shipment_id, sub_id)) as shipment_number
from amazon_shipment
group by CONVERT(varchar(7), shipment_date, 120);

-- Meta
-- You have been asked to find the 5 most lucrative products in terms of total revenue for the first half of 2022 (from January to June inclusive). Output their IDs and the total revenue.

WITH cte AS
(
  SELECT product_id,
         SUM(cost_in_dollars * units_sold) AS revenue,
         RANK() OVER (ORDER BY SUM(cost_in_dollars * units_sold) DESC) AS rnk
  FROM online_orders
  WHERE MONTH(date) BETWEEN 1 AND 6
  GROUP BY product_id
)
select product_id, revenue
from cte
where rnk <= 5;

-- AirBnB
-- Find the average number of bathrooms and bedrooms for each city’s property types. Output the result along with the city name and the property type.


select city, 
property_type,
avg(cast(bathrooms as float)),
avg(cast(bedrooms as float))
from airbnb_search_details
group by city, property_type;

-- Apple
-- Count the number of user events performed by MacBookPro users. Output the result along with the event name. Sort the result based on the event count in the descending order.

select event_name, count(*) as event_count
from playbook_events
where device = 'macbook pro'
group by event_name
order by event_count desc;

-- Forbes
-- Find the most profitable company from the financial sector. Output the result along with the continent.

select top 1 continent, company
from forbes_global_2010_2014
where sector = 'Financials';

-- City of LA
-- Find the activity date and the pe_description of facilities with the name 'STREET CHURROS' and with a score of less than 95 points.

select activity_date, pe_description
from los_angeles_restaurant_health_inspections
where facility_name = 'STREET CHURROS' and score < 95;

-- Dell, Apple, Microsoft
-- Write a query that returns the number of unique users per client per month

select client_id,month(time_id) as month, count(distinct user_id) as users_num
from fact_events
group by client_id,month(time_id);

-- Amazon, MSFT
-- Find the number of employees working in the Admin department that joined in April or later.

select count(worker_id)
from worker
where department = 'Admin' and month(joining_date) >= 4;

-- Amazon 
-- Find the number of workers by department who joined in or after April. Output the department name along with the corresponding number of workers. Sort records based on the number of workers in descending order.


select department, count(worker_id)
from worker
where month(joining_date) >= 4
group by department
order by count(worker_id) desc;


-- Apple, Amazon
-- Find the details of each customer regardless of whether the customer made an order. Output the customer's first name, last name, and the city along with the order details. Sort records based on the customer's first name and the order details in ascending order.

select c.first_name, c.last_name, c.city, o.order_details
from customers c
left join orders o on c.id=o.cust_id
order by c.first_name, o.order_details desc;

-- Amazon, Shopify
-- Find order details made by Jill and Eva. Consider the Jill and Eva as first names of customers. Output the order date, details and cost along with the first name. Order records based on the customer id in ascending order.

select c.first_name, o.order_date, o.order_details, o.total_order_cost
from customers c right join orders o on c.id = o.cust_id
where first_name = 'Jill' OR first_name = 'Eva';

-- SalesForce, Glassdoor
-- Compare each employee's salary with the average salary of the corresponding department. Output the department, first name, and salary of employees along with the average salary of that department.

SELECT department, first_name, salary, 
AVG(CAST(salary as float)) OVER (PARTITION BY department) as dept_avg_sal
FROM employee;

-- City of SF
-- Find libraries who haven't provided the email address in circulation year 2016 but their notice preference definition is set to email. Output the library code.


select DISTINCT home_library_code
from library_usage
where circulation_active_year = '2016' and notice_preference_definition = 'email' and provided_email_address = 'FALSE';

-- City of SF
-- Find the base pay for Police Captains. Output the employee name along with the corresponding base pay.

select employeename, basepay 
from sf_public_salaries
where jobtitle = 'CAPTAIN III (POLICE DEPARTMENT)';

-- Spotify
-- Find how many times each artist appeared on the Spotify ranking list Output the artist name along with the corresponding number of occurrences. Order records by the number of occurrences in descending order.


select artist, count(trackname) as occurences
from spotify_worldwide_daily_song_ranking
group by artist
order by count(trackname) desc;


-- Lyft
-- Find all Lyft drivers who earn either equal to or less than 30k USD or equal to or more than 70k USD. Output all details related to retrieved records.

select * 
from lyft_drivers
where yearly_salary < 30000 or yearly_salary >= 70000;

-- Meta
-- Meta/Facebook has developed a new programing language called Hack.To measure the popularity of Hack they ran a survey with their employees. The survey included data on previous programing familiarity as well as the number of years of experience, age, gender and most importantly satisfaction with Hack. Due to an error location data was not collected, but your supervisor demands a report showing average popularity of Hack by office location. Luckily the user IDs of employees completing the surveys were stored. Based on the above, find the average popularity of the Hack per office location. Output the location along with the average popularity.


select empl.location, avg(cast(surv.popularity as float)) as hack_popularity
from facebook_employees empl
join facebook_hack_survey surv
on empl.id = surv.employee_id
group by empl.location;


-- Meta
-- Find all posts which were reacted to with a heart. For such posts output all columns from facebook_posts table.

select distinct p.* 
from facebook_reactions r
join facebook_posts p on r.post_id=p.post_id
where r.reaction = 'heart';

-- Google, Netflix
-- Count the number of movies that Abigail Breslin was nominated for an oscar.


select count(*) 
from oscar_nominees
where nominee = 'Abigail Breslin';

-- AirBnB, Expedia
-- Find the number of rows for each review score earned by 'Hotel Arena'. Output the hotel name (which should be 'Hotel Arena'), review score along with the corresponding number of rows with that score for the specified hotel.
SELECT hotel_name,
       reviewer_score,
       count(*)
FROM hotel_reviews
WHERE hotel_name = 'Hotel Arena'
GROUP BY hotel_name,
         reviewer_score


-- Lyft, DoorDash
-- Find the last time each bike was in use. Output both the bike number and the date-timestamp of the bike's last use (i.e., the date-time the bike was returned). Order the results by bikes that were most recently used.


select bike_number, max(end_time) as bike_last_used
from dc_bikeshare_q1_2012
group by bike_number
order by max(end_time) desc;

-- MSFT
-- We have a table with employees and their salaries, however, some of the records are old and contain outdated salary information. Find the current salary of each employee assuming that salaries increase each year. Output their id, first name, last name, department ID, and current salary. Order your list by employee ID in ascending order.


select id, first_name, last_name, department_id, max(salary) as curr_salary 
from ms_employee_salary
group by first_name, last_name, department_id, id
order by id asc;


-- Linkedin, Dropbox
-- Write a query that calculates the difference between the highest salaries found in the marketing and engineering departments. Output just the absolute difference in salaries.

SELECT ABS((SELECT MAX(salary) FROM db_employee emp JOIN db_dept dept ON emp.department_id = dept.id WHERE department = 'marketing') -
 (SELECT MAX(salary) FROM db_employee emp JOIN db_dept dept ON emp.department_id = dept.id WHERE department = 'engineering')) AS salary_difference;

