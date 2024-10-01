-- Yelp
-- Find the top 5 states with the most 5 star businesses. Output the state name along with the number of 5-star businesses and order records by the number of 5-star businesses in descending order. In case there are ties in the number of businesses, return all the unique states. If two states have the same result, sort them in alphabetical order.

select state, businesses_ranked
from
(select state, count(business_id) as businesses_ranked,
rank() over (order by count(business_id) desc) as rank_business
from yelp_business
where stars = 5
group by state) as a
where rank_business <= 5
order by businesses_ranked desc, state asc;


-- AirBnb
-- You’re given a table of rental property searches by users. The table consists of search results and outputs host information for searchers. Find the minimum, average, maximum rental prices for each host’s popularity rating. The host’s popularity rating is defined as below:
-- 0 reviews: New
-- 1 to 5 reviews: Rising
-- 6 to 15 reviews: Trending Up
-- 16 to 40 reviews: Popular
-- more than 40 reviews: Hot
-- Tip: The id column in the table refers to the search ID. You'll need to create your own host_id by concating price, room_type, host_since, zipcode, and number_of_reviews.
-- Output host popularity rating and their minimum, average and maximum rental prices.

WITH host_price_cte AS(
SELECT 
    CONCAT(price, room_type, host_since, number_of_reviews) AS host_id,
    price,
    number_of_reviews
FROM airbnb_host_searches),
final_cte AS(
SELECT
    host_id,
    price,
    SUM(number_of_reviews) AS total_reviews,
    CASE WHEN SUM(number_of_reviews) = 0 THEN 'New'
         WHEN SUM(number_of_reviews) BETWEEN 1 AND 5 THEN 'Rising'
         WHEN SUM(number_of_reviews) BETWEEN 6 AND 15 THEN 'Trending Up'
         WHEN SUM(number_of_reviews) BETWEEN 16 AND 40 THEN 'Popular'
         ELSE 'Hot' END AS host_pop_rating
FROM host_price_cte
GROUP BY  host_id,price)

SELECT
    host_pop_rating,
    MIN(price) AS min_price,
    AVG(price) AS avg_price,
    MAX(price) AS max_price
FROM final_cte
GROUP BY host_pop_rating;


-- Microsoft
-- Find the total number of downloads for paying and non-paying users by date. Include only records where non-paying customers have more downloads than paying customers. The output should be sorted by earliest date first and contain 3 columns date, non-paying downloads, paying downloads.

with cte as ( 
    select 
    a.date,
    sum(case when c.paying_customer = 'no' then a.downloads end) as non_paying,
    sum(case when c.paying_customer = 'yes' then a.downloads end) as paying
    from ms_download_facts a 
    join ms_user_dimension b  on a.user_id = b.user_id
    join ms_acc_dimension c  on b.acc_id = c.acc_id
    group by a.date
)
select date, non_paying, paying from cte where non_paying > paying;



-- Airbnb
-- You're given a dataset of searches for properties on Airbnb. For simplicity, let's say that each search result (i.e., each row) represents a unique host. Find the city with the most amenities across all their host's properties. Output the name of the city.

with cte as (select 
  city,
  replace(replace(replace(amenities,'{', '' ), '}', ''), '"','') as amenities
from airbnb_search_details)

select top 1 city
from cte
cross apply string_split(amenities, ',')
group by city
order by count(*) desc;

-- Meta
-- Find the popularity percentage for each user on Meta/Facebook. The popularity percentage is defined as the total number of friends the user has divided by the total number of users on the platform, then converted into a percentage by multiplying by 100. Output each user along with their popularity percentage. Order records in ascending order by user id. The 'user1' and 'user2' column are pairs of friends.

WITH usersunion AS
  (SELECT user1,
          user2
   FROM facebook_friends
   UNION 
   SELECT user2 AS user1,
                user1 AS user2
   FROM facebook_friends)
SELECT user1,
       CAST(count(*) AS FLOAT) /  (SELECT CAST(count(DISTINCT user1) AS FLOAT) FROM usersunion)*100 AS popularity_percent
FROM usersunion
GROUP BY user1
ORDER BY user1;


-- Amazon
-- Given a table of purchases by date, calculate the month-over-month percentage change in revenue. The output should include the year-month date (YYYY-MM) and percentage change, rounded to the 2nd decimal point, and sorted from the beginning of the year to the end of the year. The percentage change column will be populated from the 2nd month forward and can be calculated as ((this month's revenue - last month's revenue) / last month's revenue)*100.

with cte as (
    select Format(cast(created_at as date), 'yyyy-MM') as month, 
    SUM(value) as total, 
    LAG(SUM(value)) OVER(ORDER BY Format(cast(created_at as date), 'yyyy-MM')) prevRevenue 
    from sf_transactions
    group by Format(cast(created_at as date), 'yyyy-MM')
)
select month, round(cast((total - prevRevenue) as float)/cast(prevRevenue as float)*100, 2) from cte

-- Google, Netflix
-- ABC Corp is a mid-sized insurer in the US and in the recent past their fraudulent claims have increased significantly for their personal auto insurance portfolio. They have developed a ML based predictive model to identify propensity of fraudulent claims. Now, they assign highly experienced claim adjusters for top 5 percentile of claims identified by the model. Your objective is to identify the top 5 percentile of claims from each state. Your output should be policy number, state, claim cost, and fraud score.

WITH fs AS (
    SELECT
    *,
    PERCENT_RANK() OVER(PARTITION BY state ORDER BY fraud_score) AS ptile
    FROM fraud_score
)
SELECT
    policy_num,
    state,
    claim_cost,
    fraud_score
FROM fs
WHERE ptile >= 0.95;

-- Google
-- Find the number of times the words 'bull' and 'bear' occur in the contents. We're counting the number of times the words occur so words like 'bullish' should not be included in our count. Output the word 'bull' and 'bear' along with the corresponding number of occurrences.

select 'bull', COUNT(g.contents)
from google_file_store g
where g.contents like '% bull%'
union all
select 'bear', COUNT(g.contents)
from google_file_store g
where g.contents like '% bear%'

-- Apple, MSFT
-- Select the most popular client_id based on a count of the number of users who have at least 50% of their events from the following list: 'video call received', 'video call sent', 'voice call received', 'voice call sent'.

with temp as (
    select client_id, count(user_id) as count_event_type
    from fact_events
    where event_type in ('video call received', 'video call sent', 'voice call received', 'voice call sent')
    group by client_id
)
select top 1 client_id
from temp
where count_event_type > (select sum(count_event_type)*0.5 from temp)
order by count_event_type desc

-- Amazon
-- You have a table of in-app purchases by user. Users that make their first in-app purchase are placed in a marketing campaign where they see call-to-actions for more in-app purchases. Find the number of users that made additional in-app purchases due to the success of the marketing campaign. The marketing campaign doesn't start until one day after the initial in-app purchase so users that only made one or multiple purchases on the first day do not count, nor do we count users that over time purchase only the products they purchased on the first day.

select count(distinct user_id) cnt
from (
    select user_id, created_at, product_id, rank() over(partition by user_id order by created_at) date_rank, rank() over(partition by user_id, product_id order by created_at) prod_rank
    from marketing_campaign
) a
where a.date_rank > 1 and a.prod_rank < 2

-- Meta, Salesforce
-- Find the monthly retention rate of users for each account separately for Dec 2020 and Jan 2021. Retention rate is the percentage of active users an account retains over a given period of time. In this case, assume the user is retained if he/she stays with the app in any future months. For example, if a user was active in Dec 2020 and has activity in any future month, consider them retained for Dec. You can assume all accounts are present in Dec 2020 and Jan 2021. Your output should have the account ID and the Jan 2021 retention rate divided by Dec 2020 retention rate. Hint: In Oracle you should use "date" when referring to date column (reserved keyword).

select t1.account_id, t1.jan/t2.dec as retention
from
    (select account_id, count(user_id) as jan from sf_events 
    where user_id in (select user_id from sf_events where year(date)='2021' and month(date)='1') 
    group by account_id) as t1 
left join 
    (select account_id, count(user_id) as dec from sf_events 
    where user_id in (select user_id from sf_events where year(date)='2020' and month(date)='12')
     group by account_id) as t2
on t1.account_id = t2.account_id;

-- Ebay
-- You are given the table with titles of recipes from a cookbook and their page numbers. You are asked to represent how the recipes will be distributed in the book. Produce a table consisting of three columns: left_page_number, left_title and right_title. The k-th row (counting from 0), should contain the number and the title of the page with the number 2×k2×k in the first and second columns respectively, and the title of the page with the number 2×k+12×k+1 in the third column. Each page contains at most 1 recipe. If the page does not contain a recipe, the appropriate cell should remain empty (NULL value). Page 0 (the internal side of the front cover) is guaranteed to be empty.

WITH cte_cookbook AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY page_number) * 2 - 2 AS left_page_number,
        ROW_NUMBER() OVER (ORDER BY page_number) * 2 - 1 AS right_page_number
    FROM cookbook_titles
)

SELECT 
    cte.left_page_number,
    l.title AS left_title,
    r.title AS right_title
FROM cte_cookbook AS cte
LEFT JOIN cookbook_titles AS r ON cte.right_page_number = r.page_number
LEFT JOIN cookbook_titles AS l ON cte.left_page_number = l.page_number;