#Composite data of a business organisation, confined to ‘sales and delivery’ domain is given for the period of last decade. From the given data retrieve solutions for the given scenario.
create database miniproject2;
use mini_project_2;
show tables;
#1.	Join all the tables and create a new table called combined_table.
#(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
create table combined_table as
(SELECT mf.*, cd.Customer_Name, cd.Province, cd.Region, cd.Customer_Segment, od.Order_ID, od.Order_Date, od.Order_Priority,
pd.Product_Category, pd.Product_Sub_Category, sd.Ship_Mode, sd.Ship_Date from market_fact mf, cust_dimen cd, orders_dimen od, prod_dimen pd, shipping_dimen sd where 
cd.cust_id=mf.cust_id and mf.ord_id=od.ord_id and mf.prod_id=pd.prod_id and mf.ship_id=sd.ship_id);
select * from combined_table;
#2.	Find the top 3 customers who have the maximum number of orders
select cust_id,customer_name,count(distinct ord_id)no_of_orders from combined_table 
group by cust_id,customer_name order by no_of_orders desc limit 3;
#3.	Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
update  combined_table set order_date=str_to_date(order_date,'%d-%m-%Y'),ship_date=str_to_date(ship_date,'%d-%m-%Y');
alter table combined_table add column DaysTakenForDelivery  int; 

update combined_table set  DaysTakenForDelivery  = datediff(ship_date,order_Date);
#4.	Find the customer whose order took the maximum time to get delivered.
select customer_name, max(DaysTakenForDelivery) from combined_table;
#5.	Retrieve total sales made by each product from the data (use Windows function)
select distinct prod_id,sum(sales) over(partition by prod_id)total_sales from combined_table ;
#6.	Retrieve total profit made from each product from the data (use windows function)
select distinct prod_id,sum(profit) over(partition by prod_id)total_profit from combined_table ;
#7.	Count the total number of unique customers in January and how many of them came back every month over the entire year in 2011
select 
(select count(distinct cust_id) total_unique_customer_jan from combined_table where monthname(order_Date)='January' and year(order_Date)=2011)total_unique_customer_jan ,
(select count(*)comeback_customers from 
(select cust_id,count(*)from 
(select distinct cust_id,monthname(order_Date)mn from combined_table where  year(order_Date)=2011 and cust_id in 
(select distinct cust_id total_unique_customer_jan from combined_table where monthname(order_Date)='January' and year(order_Date)=2011)
)u
group by cust_id having count(*)>1)m)comeback_customers from dual ; 

#8.	Retrieve month-by-month customer retention rate since the start of the business.(using views)

#Tips: 
#1: Create a view where each user’s visits are logged by month, allowing for the possibility that these will have occurred over multiple # years since whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
# 5: calculate the retention month wise
create or replace view v1 as 
select cust_id,customer_name,order_date,month(order_Date)abc from combined_table;

select abc Month,100-per Retention_rate from(
select * from (
select *,max(c1) over(partition by abc),c1/max(c1) over(partition by abc)*100 per 
from (select abc,category,count(*)c1 
from(select  cust_id,customer_name,abc, case when dd<=1 then 'retained' when dd>1 then 'irregular' else 'churned' end category
from (select a-month(order_date)dd,cust_id,customer_name,month(order_date)abc 
from (select cust_id,customer_name,monthname(order_date),month(order_date)abc,year(order_date),order_date,
lead(month(order_date))over(partition by cust_id,year(order_date) order by month(order_date))a
from v1)t)t1 order by abc)uff group by abc,category with rollup order by abc)uff2)uff3 where category='churned')uff4;
