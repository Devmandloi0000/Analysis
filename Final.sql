use codebasicdb;

select * from customers
select * from spends;

-------------------------------------------
--highest salary from the customer table 

select s.* from customers s order by avg_income desc;

--- 86600
-------------------------------------------
 --second highest avg_income
 
select s.* from customers s where 2-1 = (select count(s1.avg_income) from customers s1 where s1.avg_income > s.avg_income);

-- 86327
-------------------------------------------
-- top 3 highest avg_income based on occupation

select * from 
	   (select 
			customer_id,
			age_group,
			city,
			occupation, 
			avg_income,
			DENSE_RANK() over(partition by occupation order by avg_income desc) as ranking
		from 
			customers) x
where x.ranking <= 3


select distinct(occupation),count(occupation) from customers
group by  cube (occupation);

--Analysis:- By this we get all the top avg_income are belongs to 45+ age group
-- Approx Highest salary for 
/*	Business Owners			 = Above 85000
	Freelancers				 = Above 43000
	Government Employees	 = Above 63000
	Salaried IT Employees	 = Above 75000
	Salaried Other Employees = Above 48000 */

----------------------------------------------------------------------------------
-- Average income of the customer based on city and occupation

create view city_avg_income as 
SELECT 
    age_group,
	occupation,
    AVG(avg_income) AS avg_city_income,
	AVG(CASE WHEN CITY = 'Mumbai' THEN avg_income end) as mumbai_avg_income,
	AVG(CASE WHEN CITY = 'Chennai' THEN avg_income end) as Chennai_avg_income,
	AVG(CASE WHEN CITY = 'Delhi NCR' THEN avg_income end) as Delhi_NCR_avg_income,
	AVG(CASE WHEN CITY = 'Hyderabad' THEN avg_income  end) as Hyderabad_avg_income,
	AVG(CASE WHEN CITY = 'Bengaluru' THEN avg_income end) as Bengaluru_avg_income
FROM 
    customers 

GROUP BY 
    age_group,occupation


select * from city_avg_income;

---------------------------------------------------------------------------------------------

select * from customers
select * from spends

--- we have 6 month of data 
/*		1) avg income * 6 total user income
		2) total user spend
		3) based on cate */


----------------------------------------------------------------------------------------------
-- top 3 customer spend monthly

select * from customers
select * from spends

with avg_cte
		(customer_id,occupation,city,oc_avg_income,ranking_order) as 
		(SELECT 
			customer_id,
			city,
			OCCUPATION,
			AVG(avg_income) over(partition by occupation ) as oc_avg_income,
			row_number() over(partition by occupation order by avg_income desc) ranking_order
		FROM 
			customers s) ,

spend_cte 
		(customer_id , total_spend,month) as
		(select 
			customer_id,
			month,
			sum(spend) over(partition by customer_id,month) as total_spend 
		from spends)

select ac.*,sc.total_spend,sc.month from avg_cte ac
right join spend_cte sc
on ac.customer_id = sc.customer_id
where ranking_order <= 3
order by ranking_order asc

--------------------------------------------------------------------------------------
--- avg salary and spends in all months 

SELECT 
	X.customer_id,
	X.avg_income,
	X.YEARLY_AVG_INCOME,
	SUM(CASE WHEN X.month = 'May' then spend else 0 end) as total_spend_may, 
	SUM(CASE WHEN X.month = 'june' then spend else 0 end) as total_spend_june ,
	SUM(CASE WHEN X.month = 'july' then spend else 0 end) as total_spend_july ,
	SUM(CASE WHEN X.month = 'August' then spend else 0 end) as total_spend_aug ,
	SUM(CASE WHEN X.month = 'September' then spend else 0 end) as total_spend_sep ,
	SUM(CASE WHEN X.month = 'October' then spend else 0 end) as total_spend_oct 
from
	(SELECT 
		C.customer_id,
		C.avg_income,
		S.month,
		S.spend,
		C.avg_income*12 YEARLY_AVG_INCOME
	FROM 
		customers C
		left join spends S
		on C.customer_id = S.customer_id) X
where 
	X.month IN ('August','September','October','May','June','JULY')
group by 
	X.customer_id,X.avg_income,X.YEARLY_AVG_INCOME
order by 
	X.YEARLY_AVG_INCOME desc;


------ as you see here customers are highly invest in the month of aug and september
---- highest salary customer spend highest ATQCUS2990
------------------------------------------------------------------------------------

select * from spends
select * from customers;

with age_20_24(customer_id,city,age_group,occupation,avg_income,total_month_earn) as
	(SELECT
			customer_id,
			city,
			age_group,
			occupation,
			avg_income,
			avg_income*6 as total_month_earn
	FROM
			customers ),

age_spends (customer_id,sum_spend) as 
	(SELECT 
			distinct(customer_id), 
			sum(spend) over(partition by customer_id ) sum_spend
	from 
			spends)
	select 
			distinct(ag.customer_id),
			ag.city,
			ag.occupation,
			ag.avg_income,
			ag.total_month_earn,
			ap.sum_spend 
	from 
			age_20_24 ag
	left join 
			age_spends ap
	on 
			ag.customer_id=ap.customer_id

	group by 
			ag.customer_id,
			ag.city,
			ag.occupation,
			ag.avg_income,
			ag.total_month_earn,
			ap.sum_spend
	order by ag.avg_income desc;

---------------------------------------------------------------------
-- What is the age range of Mitron Bank customers?

select age_group,count(age_group) as total_person from customers group by age_group;

---------------------------------------------------------------------


  WITH age_20_24 (customer_id, city, age_group, occupation, avg_income, total_month_earn) AS
  (SELECT
    customer_id,
    city,
    age_group,
    occupation,
    avg_income,
    avg_income * 6 AS total_month_earn
  FROM
    customers),

age_spends (customer_id, sum_spend) AS
  (SELECT
    distinct(customer_id),   
    SUM(spend) OVER (PARTITION BY customer_id) AS sum_spend
  FROM
    spends)

SELECT
  ag.customer_id,
  ag.city,
  ag.occupation,
  ag.avg_income,
  ag.total_month_earn,
  ap.sum_spend
FROM
  age_20_24 ag
LEFT JOIN
  age_spends ap ON ag.customer_id = ap.customer_id;



--------------------------------------------------------------------
--Percentage of spend
/* Avg income utilisation %: Find the average income utilisation % of customers
(avg_spends/avg_income). This will be your key metric. The higher the average
income utilisation %, the more is their likelihood to use credit cards.*/

with age_20_24(customer_id,city,age_group,occupation,avg_income,total_month_earn) as
	(SELECT
			customer_id,
			city,
			age_group,
			occupation,
			avg_income,
			avg_income*6.0 as total_month_earn
	FROM
			customers ),

age_spends (customer_id,sum_spend) as 
	(SELECT 
			distinct(customer_id), 
			COALESCE(sum(spend) over(partition by customer_id ),0.0) sum_spend
	from 
			spends)
	select 
			distinct(ag.customer_id),
			ag.city,
			ag.occupation,
			ag.avg_income,
			ag.total_month_earn,
			ap.sum_spend ,
			case 
				when ag.total_month_earn <> 0
					then concat(cast((ap.sum_spend/ag.total_month_earn)*100 as int) , '%')
					else null
			end as invest_pre
	from 
			age_20_24 ag
	left join 
			age_spends ap
	on 
			ag.customer_id=ap.customer_id

	group by 
			ag.customer_id,
			ag.city,
			ag.occupation,
			ag.avg_income,
			ag.total_month_earn,
			ap.sum_spend
	order by invest_pre desc;

	
/* analysis 
	1. Mumbai spend more as compare with other city and top 50 are from mumbai and there occupation is IT EMPLOYEERS 
	   As per top 50 details 70% they invest from there avg salary 
	2. At least position chennai where customer spends below 20% from there avg salary and ocuupation is Government Employees
	3. Delhi at middle position 
	4. customer spend 77% of there income within in 6 month highest
	5. 15% spends are least spends
*/

--------------------------------------------------------------------------------------------------------------------------------------------

-- Which age group are spend and avg spend more based on marital status city wise 

select age_group,city,marital_status,customer_id from customers

with Marital_based as
		(select
			age_group,
			city,
			marital_status,
			customer_id 
		from 
			customers),
sum_based as 
		(select 
			customer_id ,
			sum(spend)  as sum_spend
		from 
			spends
		group by customer_id)
select 
	mb.age_group,
	mb.marital_status,
	sum(sb.sum_spend) as total_spend,
	avg(sb.sum_spend)as  avg_spend ,
	sum(case when city = 'Mumbai' then sb.sum_spend else 0 end) as mumbai_spend,
	avg(case when city = 'Mumbai' then sb.sum_spend else 0 end) as avg_mumbai_spend,
	sum(case when city = 'Delhi NCR' then sb.sum_spend else 0 end) as delhi_spend,
	avg(case when city = 'Delhi NCR' then sb.sum_spend else 0 end) as avg_delhi_spend,
	sum(case when city = 'Bengaluru' then sb.sum_spend else 0 end) as Bengaluru_spend,
	avg(case when city = 'Bengaluru' then sb.sum_spend else 0 end) as avg_Bengaluru_spend,
	sum(case when city = 'Hyderabad' then sb.sum_spend else 0 end) as Hyderabad_spend,
	avg(case when city = 'Hyderabad' then sb.sum_spend else 0 end) as avg_Hyderabad_spend,
	sum(case when city = 'Chennai' then sb.sum_spend else 0 end) as Chennai_spend,
	avg(case when city = 'Chennai' then sb.sum_spend else 0 end) as avg_Chennai_spend
from 
	marital_based mb
inner join 
	sum_based sb
on 
	mb.customer_id = sb.customer_id
group by 
	mb.age_group,
	mb.marital_status
order by 
	total_spend desc;

--- Analysis 
/*
	1. 35-45 , married spend more in every city accept bangaluru and 45+ who are single spend alot in mumbai 
	2. there are 0 count in delhi and hydrabad they are not spending there income in any of those categories
	3. 35-45, 25-34 and 45+ those are married they spending hign on each city 
	4. 21-34 and married are spending low in each city 
*/
-----------------------------------------------------
-- Procedure are used for reuse block of code and these procedure is help us to display both table when we call procedure name 

create procedure both_tab
as
begin
select * from customers
select * from spends
end


exec both_tab;
-----------------------------------------------------------------

-- count of payment type montly wise

select  s.payment_type , 
		count(case when month='May' then s.payment_type else NULL end ) may_count,
		count(case when month='June' then s.payment_type else NULL end ) June_count,
		count(case when month='July' then s.payment_type else NULL end ) July_count,
		count(case when month='August' then s.payment_type else NULL end ) Aug_count,
		count(case when month='September' then s.payment_type else NULL end ) Sep_count,
		count(case when month='October' then s.payment_type else NULL end ) Oct_count
from
		spends s
group by 
		s.payment_type

-- There are 36000 data we have for each customer for each month 

select count(payment_type) , payment_type from spends where month='August' group by payment_type 
------------------------------------------------------------------------------------------------
-- Now put some condition cate wise  in every month 

select * from spends;

select  s.payment_type , 
		s.category,
		count(case when s.month='May' then s.category else NULL end ) may_count,
		count(case when month='June' then s.category else NULL end ) June_count,
		count(case when month='July' then s.category else NULL end ) July_count,
		count(case when month='August' then s.category else NULL end ) Aug_count,
		count(case when month='September' then s.category else NULL end ) Sep_count,
		count(case when month='October' then s.category else NULL end ) Oct_count
		
from
		spends s
group by 
		s.payment_type,s.category



-- every month there are 4000 records of payment type and category

---------------------------------------------------------------------------------------------------
-- Which age_groupare mostly preffered payment type 

select  c.age_group,
		s.payment_type , 
		count(case when c.city='Mumbai' then c.age_group else NULL end ) mumbai_count,
		count(case when c.city='Delhi NCR' then c.age_group else NULL end ) Delhi_count,
		count(case when c.city='Bengaluru' then c.age_group else NULL end ) Bengaluru_count,
		count(case when c.city='Chennai' then c.age_group else NULL end ) Chennai_count,
		count(case when c.city='Hyderabad' then c.age_group else NULL end ) Hyderabad_count
				
from
		spends s
inner join 
		customers c
on
		s.customer_id= c.customer_id
group by 
		s.payment_type,c.age_group
order by 
		s.payment_type asc;

--- Mumbaiker are always ahead in each case as comapre with other city 

exec both_tab;


select avg(spend) from spends;

select * from spends
-----------------------------------------------------------------------------------------



exec both_tab;



select s1.customer_id,count(s1.customer_id) as new_count from customers s1
group by s1.customer_id
having count(s1.customer_id) <= 1;

select s1.customer_id,count(s1.customer_id) as new_count from spends s1
group by s1.customer_id
having count(s1.customer_id) > 1;

-- There is no any duplicates in our tables 

select s1.avg_income,count(s1.avg_income) as new_count from customers s1
group by s1.avg_income
having count(s1.avg_income) > 1;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Demographic classification: Classify the customers based on available demography such as age group, gender, occupation etc. and provide insights based on them.*/


SELECT 
	S.category,S.payment_type,
	SUM(S.SPEND) AS TOTAL_SPEND,
	sum(case when s.month='May' then s.spend else NULL end ) may_count,
	count(case when s.month='May'AND S.payment_type ='Credit Card' then S.payment_type else NULL end ) May,
	sum(case when month='June' then s.spend else NULL end ) June_count,
	count(case when s.month='June' then S.payment_type else NULL end ) June,
	sum(case when month='July' then s.spend else NULL end ) July_count,
	count(case when s.month='July' then S.payment_type else NULL end ) July,
	sum(case when month='August' then s.spend else NULL end ) Aug_count,
	count(case when s.month='August' then S.payment_type else NULL end ) August,
	sum(case when month='September' then s.spend else NULL end ) Sep_count,
	count(case when s.month='September' then S.payment_type else NULL end ) September,
	sum(case when month='October' then s.spend else NULL end ) Oct_count,
	count(case when s.month='October' then S.payment_type else NULL end ) Oct_count  
FROM 
	spends S
Where
	S.payment_type='Credit Card'
GROUP BY 
	S.category,S.payment_type
ORDER BY 
	S.category asc;

Customer spend most in Mumbai city 
Hydrabad and chennai are only the city where all the user used credit card only no any other payment 

--let's check 

SELECT 
	S.month,S.category,S.payment_type,SUM(S.SPEND) AS TOTAL_SPEND
FROM 
	spends S
WHERE 
	S.category='Electronics'
GROUP BY 
	S.category,S.month,S.payment_type
ORDER BY 
	TOTAL_SPEND DESC;




WITH from_customer
AS 
	(SELECT 
		C.customer_id,C.city
	FROM 
		customers C),
from_spend AS 
	(SELECT 
		S.month,S.category,S.payment_type,SUM(S.SPEND) AS TOTAL_SPEND,s.customer_id
	FROM 
		spends S
	GROUP BY 
		S.category,S.month,S.payment_type,S.customer_id)

SELECT FC.city,FS.month,FS.category,FS.payment_type,FS.TOTAL_SPEND FROM from_customer FC
left JOIN from_spend FS
ON 
	FC.customer_id=FS.customer_id
WHERE 
	FS.month = 'September' and FS.category='Bills'
GROUP BY 
	FC.city,FS.month,FS.category,FS.payment_type,FS.TOTAL_SPEND
ORDER BY 
		FS.TOTAL_SPEND DESC;

-- In month of Sep , most no of customers are using credit card for Bill category


exec both_tab;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------

