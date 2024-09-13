-- Forbes
-- Find the 3 most profitable companies in the entire world. Output the result along with the corresponding company name. Sort the result based on profits in descending order.


select top 3 company, sum(profits) as total_profits 
from forbes_global_2010_2014
group by company
order by sum(profits) desc;


-- Amazon, DoorDash
-- You have been asked to find the job titles of the highest-paid employees. Your output should include the highest-paid title or multiple titles with the same salary.

select t.worker_title
from worker w
join title t on w.worker_id = t.worker_ref_id
where w.salary in (select max(salary) from worker);

-- Meta
-- Calculate each user's average session time. A session is defined as the time difference between a page_load and page_exit. For simplicity, assume a user has only 1 session per day and if there are multiple of the same events on that day, consider only the latest page_load and earliest page_exit, with an obvious restriction that load time event should happen before exit time event . Output the user_id and their average session time.


WITH session_pairs AS (
    SELECT
        user_id,
        timestamp AS load_time,
        LEAD(timestamp) OVER (PARTITION BY user_id ORDER BY timestamp) AS exit_time,
        action,
        LEAD(action) OVER (PARTITION BY user_id ORDER BY timestamp) AS next_action
    FROM facebook_web_log
    WHERE action IN ('page_load', 'page_exit')
), 
valid_sessions AS (
    SELECT
        user_id,
        load_time,
        exit_time,
        DATEDIFF(second, load_time, exit_time) AS session_time
    FROM session_pairs
    WHERE action = 'page_load' AND next_action = 'page_exit'
)
SELECT
    user_id,
    ROUND(AVG(session_time * 1.0), 1) AS avg_session_time
FROM valid_sessions
GROUP BY user_id
HAVING AVG(session_time) IS NOT NULL;


-- Tesla, Salesforce
-- You are given a table of product launches by company by year. Write a query to count the net difference between the number of products companies launched in 2020 with the number of products companies launched in the previous year. Output the name of the companies and a net difference of net products released for 2020 compared to the previous year.


SELECT a.company_name, (count(DISTINCT a.product_name)-count(DISTINCT b.product_name)) AS net_products
FROM (SELECT company_name, product_name 
FROM car_launches WHERE year = 2020) a
FULL OUTER JOIN (SELECT company_name, product_name FROM car_launches WHERE year = 2019) b 
ON a.company_name = b.company_name
GROUP BY a.company_name
ORDER BY company_name

-- Spotify
-- Find songs that have ranked in the top position. Output the track name and the number of times it ranked at the top. Sort your records by the number of times the song was in the top position in descending order.


select trackname, count(position) as toprank
from spotify_worldwide_daily_song_ranking
where position=1
group by trackname
order by count(position) desc


-- Google
-- Find the email activity rank for each user. Email activity rank is defined by the total number of emails sent. The user with the highest number of emails sent will have a rank of 1, and so on. Output the user, total emails, and their activity rank. Order records by the total emails in descending order. Sort users with the same number of emails in alphabetical order. In your rankings, return a unique value (i.e., a unique rank) even if multiple users have the same number of emails. For tie breaker use alphabetical order of the user usernames.


SELECT from_user, count(*) as total_emails, ROW_NUMBER() OVER (ORDER BY count(*) DESC, from_user ASC) AS row_number
FROM google_gmail_emails
GROUP BY from_user
ORDER BY total_emails DESC, from_user ASC


-- Amazon
-- Write a query that'll identify returning active users. A returning active user is a user that has made a second purchase within 7 days of any other of their purchases. Output a list of user_ids of these returning active users.

SELECT DISTINCT a1.user_id
FROM amazon_transactions a1
JOIN amazon_transactions a2 ON a1.user_id = a2.user_id
AND a1.id <> a2.id
AND DATEDIFF(day, a1.created_at, a2.created_at) BETWEEN 0 AND 7
ORDER BY a1.user_id



-- Airbnb
-- Rank guests based on the total number of messages they've exchanged with any of the hosts. Guests with the same number of messages as other guests should have the same rank. Do not skip rankings if the preceding rankings are identical. Output the rank, guest id, and number of total messages they've sent. Order by the highest number of total messages first.

SELECT 
    DENSE_RANK() OVER(ORDER BY SUM(n_messages) DESC) as ranking, 
    id_guest, 
    SUM(n_messages) as sum_n_messages
FROM airbnb_contacts
GROUP BY id_guest
ORDER BY sum_n_messages DESC

-- Spotify
-- What were the top 10 ranked songs in 2010? Output the rank, group name, and song name but do not show the same song twice. Sort the result based on the year_rank in ascending order.


SELECT
    year_rank as rank, 
    group_name,
    song_name
FROM
    billboard_top_100_year_end
WHERE 
    year = 2010 AND 
    year_rank BETWEEN 1 AND 10
GROUP BY 
    year_rank,
    group_name, 
    song_name
ORDER BY 
    year_rank ASC



-- Google
-- Which user flagged the most distinct videos that ended up approved by YouTube? Output, in one column, their full name or names in case of a tie. In the user's full name, include a space between the first and the last name.



SELECT username
FROM 
  (SELECT CONCAT(uf.user_firstname, ' ', uf.user_lastname) AS username,
          DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT video_id) DESC) AS rnk
   FROM user_flags AS uf
   INNER JOIN flag_review AS fr ON uf.flag_id = fr.flag_id
   WHERE LOWER(fr.reviewed_outcome) = 'approved'
   GROUP BY CONCAT(uf.user_firstname, ' ', uf.user_lastname)
  ) AS inner_query
WHERE rnk = 1

-- Netflix, Google
-- For each video, find how many unique users flagged it. A unique user can be identified using the combination of their first name and last name. Do not consider rows in which there is no flag ID.

select video_id, count(distinct concat(user_firstname,' ',user_lastname)) as user_cnt 
from user_flags
where flag_id IS NOT NULL
group by video_id;

-- Google, Deloitte
-- The election is conducted in a city and everyone can vote for one or more candidates, or choose not to vote at all. Each person has 1 vote so if they vote for multiple candidates, their vote gets equally split across these candidates. For example, if a person votes for 2 candidates, these candidates receive an equivalent of 0.5 vote each. Find out who got the most votes and won the election. Output the name of the candidate or multiple names in case of a tie. To avoid issues with a floating-point error you can round the number of votes received by a candidate to 3 decimal places.

WITH vote_weights AS (
     SELECT voter,
            candidate,
            1.0 / COUNT(*) OVER (PARTITION BY voter) AS vote_weight
       FROM voting_results
      WHERE candidate IS NOT NULL),
      
     voting_results_summary AS (
     SELECT candidate,
            DENSE_RANK() OVER (ORDER BY ROUND(SUM(vote_weight), 3) DESC) AS place
       FROM vote_weights
      GROUP BY candidate)
     
SELECT candidate
  FROM voting_results_summary
 WHERE place = 1;

 -- Meta
 -- Output share of US users that are active. Active users are the ones with an "open" status in the table.

 select cast(sum(case when country='USA' and status = 'open' then 1 else NULL end) as float)/cast(count(*) as float) as usa_users
from fb_active_users;

-- City of SF
-- You're given a dataset of health inspections. Count the number of violation in an inspection in 'Roxanne Cafe' for each year. If an inspection resulted in a violation, there will be a value in the 'violation_id' column. Output the number of violations by year in ascending order.

select YEAR(inspection_date) as inspection_year, count(*) as number_inspections 
from sf_restaurant_health_violations
where violation_id IS NOT NULL and business_name = 'Roxanne Cafe'
group by YEAR(inspection_date)
order by count(*) asc;

-- City of SF
-- Classify each business as either a restaurant, cafe, school, or other. •	A restaurant should have the word 'restaurant' in the business name. •	A cafe should have either 'cafe', 'café', or 'coffee' in the business name. •	A school should have the word 'school' in the business name. •	All other businesses should be classified as 'other'. Output the business name and their classification.

select distinct business_name,
case
when lower(business_name) like '%cafe%' or lower(business_name) like '%café%' or lower(business_name) like '%coffee%' then 'cafe'
when lower(business_name) like '%school%' then 'school'
when lower(business_name) like '%restaurant%' then 'restaurant'
else 'other' end as business_class
from sf_restaurant_health_violations;

-- AirBnb
-- Find the number of apartments per nationality that are owned by people under 30 years old. Output the nationality along with the number of apartments. Sort records by the apartments count in descending order.

select h.nationality, count(distinct u.unit_id) unit_cnt
from airbnb_hosts h
join airbnb_units u on h.host_id=u.host_id
where h.age < 30 and unit_type='Apartment'
group by h.nationality
order by count(distinct u.unit_id) desc;


-- Meta
-- Calculate the percentage of spam posts in all viewed posts by day. A post is considered a spam if a string "spam" is inside keywords of the post. Note that the facebook_posts table stores all posts posted by users. The facebook_post_views table is an action table denoting if a user has viewed a post.

select post_date, sum(case when lower(post_keywords) like '%spam%' then 1 else NULL end)*100/count(*) as spam_share 
from facebook_posts p 
join facebook_post_views v on p.post_id=v.post_id
group by post_date;

-- AirBnb
-- Find matching hosts and guests pairs in a way that they are both of the same gender and nationality. Output the host id and the guest id of matched pair.

select distinct host_id, guest_id 
from airbnb_hosts h 
left join airbnb_guests g on h.nationality=g.nationality and h.gender=g.gender;

-- City of SF
-- Find the average total compensation based on employee titles and gender. Total compensation is calculated by adding both the salary and bonus of each employee. However, not every employee receives a bonus so disregard employees without bonuses in your calculation. Employee can receive more than one bonus. Output the employee title, gender (i.e., sex), along with the average total compensation.

select e.employee_title, e.sex, avg(e.salary+b.ttl_bonus) as total_compensation 
from sf_employee e
join   (SELECT worker_ref_id,
          SUM(bonus) AS ttl_bonus
   FROM sf_bonus
   GROUP BY worker_ref_id) 
b on e.id=b.worker_ref_id
group by e.employee_title, e.sex;


-- Meta
-- Find the rate of processed tickets for each type.

select c.type, 
cast(sum(case when c.processed='TRUE' then 1 else NULL END) as float)/count(complaint_id)
from facebook_complaints c
group by type;

-- Amazon, Dropbox
-- Find the second highest salary of employees.

select distinct salary from 
(SELECT salary, DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk FROM employee) as a
where rnk=2;


-- ESPN
-- Find the Olympics with the highest number of athletes. The Olympics game is a combination of the year and the season, and is found in the 'games' column. Output the Olympics along with the corresponding number of athletes.

with cte as
(
    select count(distinct id) as athletes_count, games
    from olympics_athletes_events
    group by games
)
select games, athletes_count
from cte
where athletes_count = (select max(athletes_count) from cte)

-- Salesforce
-- Find the highest target achieved by the employee or employees who works under the manager id 13. Output the first name of the employee and target achieved. The solution should show the highest target achieved under manager_id=13 and which employee(s) achieved it.

SELECT first_name, target
FROM salesforce_employees
WHERE target IN (SELECT MAX(target) FROM salesforce_employees WHERE manager_id = 13) AND manager_id = 13;


-- Amazon
-- Calculate the total revenue from each customer in March 2019. Include only customers who were active in March 2019. Output the revenue along with the customer id and sort the results based on the revenue in descending order.

SELECT cust_id, SUM(total_order_cost) AS revenue
FROM orders
WHERE MONTH(order_date) = 3  AND YEAR(order_date) = 2019 
GROUP BY cust_id
ORDER BY revenue DESC;

-- Wine Magazine
-- Find all wineries which produce wines by possessing aromas of plum, cherry, rose, or hazelnut. To make it more simple, look only for singular form of the mentioned aromas. HINT: if one of the specified words is just a substring of another word, this should not be a hit, but a miss.

SELECT DISTINCT winery 
FROM winemag_p1 
WHERE description LIKE '%[^a-z]plum[^a-z]%' OR 
description LIKE '%[^a-z]cherry[^a-z]%' OR 
description LIKE '%[^a-z]rose[^a-z]%' OR 
description LIKE '%[^a-z]hazelnut[^a-z]%' 
ORDER BY 1;

-- Meta
-- Find the date with the highest total energy consumption from the Meta/Facebook data centers. Output the date along with the total energy consumption across all data centers.

with temp_list as (
  select date, consumption from fb_eu_energy e 
  union
  select date, consumption from fb_asia_energy a 
  union
  select date, consumption from fb_na_energy n
),
temp_sum as (
  select date, sum(consumption) as total from temp_list  
  group by date
)
select * 
from temp_sum
where total = (select max(total) as total_energy from temp_sum)

-- Yelp
-- Find the review_text that received the highest number of  'cool' votes. Output the business name along with the review text with the highest numbef of 'cool' votes.

SELECT business_name, review_text
FROM yelp_reviews
WHERE cool = 
    (SELECT max(cool)
     FROM yelp_reviews)

-- Yelp
-- Find the top business categories based on the total number of reviews. Output the category along with the total number of reviews. Order by total reviews in descending order.

select value as category, sum(review_count) as total_reviews 
from yelp_business CROSS APPLY STRING_SPLIT(categories, ';')
group by value
order by sum(review_count) desc;

-- Yelp
-- Find the top 5 businesses with most reviews. Assume that each row has a unique business_id such that the total reviews for each business is listed on each row. Output the business name along with the total number of reviews and order your results by the total reviews in descending order.

select top 5 name, sum(review_count) total_reviews
from yelp_business
group by name
order by sum(review_count) desc;


-- Meta
-- What is the overall friend acceptance rate by date? Your output should have the rate of acceptances by the date the request was sent. Order by the earliest date to latest. Assume that each friend request starts by a user sending (i.e., user_id_sender) a friend request to another user (i.e., user_id_receiver) that's logged in the table with action = 'sent'. If the request is accepted, the table logs action = 'accepted'. If the request is not accepted, no record of action = 'accepted' is logged.

with requests as (
select  
user_id_sender,
user_id_receiver,
min(case when action = 'sent' then date else null end) as date,
max(case when action = 'accepted' then date else null end) as accept_date
from fb_friend_requests
group by user_id_sender,user_id_receiver
)
select 
date,
1.0*sum(case when accept_date is not null then 1 else 0 end)/ count(*) as acceptance_rate
from requests
group by date


-- Asana
-- Find the employee with the highest salary per department. Output the department name, employee's first name along with the corresponding salary.

select department, first_name, rnk 
from (
select department, first_name, salary,
MAX(salary) OVER(PARTITION BY department) as rnk
from employee) as e
where salary=rnk;


-- Apple, Google
-- Find the number of Apple product users and the number of total users with a device and group the counts by language. Assume Apple products are only MacBook-Pro, iPhone 5s, and iPad-air. Output the language along with the total number of Apple users and users with any device. Order your results based on the number of total users in descending order.

select u.language, 
count(distinct case when lower(device) like '%iphone 5s%' or lower(device) like '%ipad air%' or lower(device) like '%macbook pro%' then u.user_id else NULL end) as apple_users,
count(distinct u.user_id) as total_users
from playbook_events e
join playbook_users u on e.user_id=u.user_id
group by u.language
order by count(distinct u.user_id) desc;


-- Google
-- Find the number of times each word appears in drafts. Output the word along with the corresponding number of occurrences.

SELECT VALUE, COUNT(*) as no_Occurrences
FROM google_file_store
CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(contents , ',', '') , '.' , '') , ' ')
WHERE filename in ('draft1.txt', 'draft2.txt')
GROUP BY VALUE;

-- Walmart, Dropbox
-- Find employees who are earning more than their managers. Output the employee's first name along with the corresponding salary.

select e.first_name as employee_name, e.salary as employee_salary 
from employee e
join employee mng on e.manager_id=mng.id
where e.salary>mng.salary;

-- Google, Kaplan
-- Output ids of students with a median score from the writing SAT.

select student_id
from sat_scores
where sat_writing = (
    select top 1 percentile_disc(0.5) within group (order by sat_writing) over() as median_sat_score
    from sat_scores
);


-- Google, Amazon
-- Find the percentage of shipable orders. Consider an order is shipable if the customer's address is known.

select 100.0*cast(sum(case when c.address is not null then 1 else null end)as float)/cast(count(o.id) as float) as shippable_orders_share
from customers c 
right join orders o
on c.id=o.cust_id;


-- Tesla, Google
-- Make a report showing the number of survivors and non-survivors by passenger class.
-- Classes are categorized based on the pclass value as:
-- pclass = 1: first_class
-- pclass = 2: second_classs
-- pclass = 3: third_class
-- Output the number of survivors and non-survivors by each class.


SELECT
    survived,
    SUM(CASE WHEN pclass = 1 THEN 1 ELSE 0 END) AS first_class,
    SUM(CASE WHEN pclass = 2 THEN 1 ELSE 0 END) AS second_class,
    SUM(CASE WHEN pclass = 3 THEN 1 ELSE 0 END) AS third_class
FROM titanic
group by survived


-- Amazon, Shopify
-- Find the customer with the highest daily total order cost between 2019-02-01 to 2019-05-01. If customer had more than one order on a certain day, sum the order costs on daily basis. Output customer's first name, total cost of their items, and the date.
-- For simplicity, you can assume that every first name in the dataset is unique.

select first_name, order_date, order_cost
from (
select c.first_name, o.order_date, sum(o.total_order_cost) as order_cost,
RANK() over (order by sum(o.total_order_cost) desc) as rnk
from customers c
right join orders o on c.id=o.cust_id
where o.order_date between '2019-02-01' and '2019-05-01'
group by c.first_name, o.order_date) a
where rnk=1;


-- Linkedin
-- Identify projects that are at risk for going overbudget. A project is considered to be overbudget if the cost of all employees assigned to the project is greater than the budget of the project.
-- You'll need to prorate the cost of the employees to the duration of the project. For example, if the budget for a project that takes half a year to complete is $10K, then the total half-year salary of all employees assigned to the project should not exceed $10K. Salary is defined on a yearly basis, so be careful how to calculate salaries for the projects that last less or more than one year.
-- Output a list of projects that are overbudget with their project name, project budget, and prorated total employee expense (rounded to the next dollar amount).
-- HINT: to make it simpler, consider that all years have 365 days. You don't need to think about the leap years.

with cte as (
    select 
        lp.title, lp.budget, sum(le.salary) as total_cost, DATEDIFF(day, start_date, end_date) as duration, 
        ceiling(sum(le.salary) * ((DATEDIFF(day, start_date, end_date) * 1.0) / 365)) as prorated_employee_expense
    from 
        linkedin_projects lp join 
        linkedin_emp_projects lep on lp.id = lep.project_id
    join linkedin_employees le on le.id = lep.emp_id
    group by lp.title, lp.budget, start_date, end_date
)
select 
    title, budget, prorated_employee_expense
from cte
where prorated_employee_expense > budget

-- Meta, Asana
-- You are given a dataset that provides the number of active users per day per premium account. A premium account will have an entry for every day that it’s premium. However, a premium account may be temporarily discounted and considered not paid, this is indicated by a value of 0 in the final_price column for a certain day. Find out how many premium accounts that are paid on any given day are still premium and paid 7 days later. Output the date, the number of premium and paid accounts on that day, and the number of how many of these accounts are still premium and paid 7 days later. Since you are only given data for a 14 days period, only include the first 7 available dates in your output.

SELECT TOP 7 a.entry_date,
       count(a.account_id) as premium_paid_accounts,
       count(b.account_id) as premium_paid_accounts_after_7d
FROM premium_accounts_by_day a
LEFT JOIN premium_accounts_by_day b ON a.account_id = b.account_id 
AND datediff(day, a.entry_date, b.entry_date) = 7 AND b.final_price > 0
WHERE a.final_price > 0
GROUP BY a.entry_date
ORDER BY a.entry_date

