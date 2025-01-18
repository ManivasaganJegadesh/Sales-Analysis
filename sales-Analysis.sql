select * from fact_sales_monthly;
select * from dim_customer;
select * from dim_product;

-- Generate a report of individual sales(aggregated on a monthly basis at the product code level) for croma india custoer for FY-2021

select fs.date,fs.product_code,dp.product,dp.variant,fs.sold_quantity,
fg.gross_price, sum(fs.sold_quantity)*fg.gross_price
from fact_sales_monthly fs
join dim_product dp
on fs.product_code = dp.product_code
join fact_gross_price fg
on fs.product_code = fg.product_code and fg.fiscal_year = year(date_add(fs.date, interval 4 month))
where fs.customer_code = '90002002' and year(date_add(fs.date, interval 4 month)) = '2021'
group by fs.date,fs.product_code,dp.product,dp.variant,fs.sold_quantity,
fg.gross_price;

-- Create funcion to find fiscal year
-- CREATE FUNCTION `get_fiscal_year`
-- (
-- 	calender_year date
-- ) RETURNS int
--     DETERMINISTIC
-- BEGIN
-- 	Declare fiscal_year int;
--     set fiscal_year = year(date_add(calender_year, interval 4 month));
-- Return fiscal_year;
-- END

-- Using fuction to calculate fiscal_year
select fs.date,fs.product_code,dp.product,dp.variant,fs.sold_quantity,
fg.gross_price, sum(fs.sold_quantity)*fg.gross_price
from fact_sales_monthly fs
join dim_product dp
on fs.product_code = dp.product_code
join fact_gross_price fg
on fs.product_code = fg.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
where fs.customer_code = '90002002' and get_fiscal_year(fs.date) = '2021' 
group by fs.date,fs.product_code,dp.product,dp.variant,fs.sold_quantity,
fg.gross_price;

-- Generate a report of individual sales(aggregated on a monthly basis at the product code level) for croma india custoer for FY-2021 and Q4
-- using CTE (common table expression)
with cte_1 as
(
select fs.date,fs.product_code,dp.product,dp.variant,fs.sold_quantity,
fg.gross_price, round(sum(fs.sold_quantity)*fg.gross_price,2) as gross_price_total
from fact_sales_monthly fs
join dim_product dp
on fs.product_code = dp.product_code
join fact_gross_price fg
on fs.product_code = fg.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
where fs.customer_code = '90002002' and get_fiscal_year(fs.date) = '2021'
group by fs.date,fs.product_code,dp.product,dp.variant,fs.sold_quantity,
fg.gross_price
),
cte_2 as
(
select date,product_code, get_quarter(date) as quarter
from fact_sales_monthly
)
select cte_1.date,cte_1.product_code,product,variant,sold_quantity,gross_price,gross_price_total
from cte_1
join cte_2
on cte_1.product_code = cte_2.product_code and get_fiscal_year(cte_1.date) = get_fiscal_year(cte_2.date)
where quarter = 'Q4';

-- Function to find quater
-- CREATE FUNCTION `get_quarter`(
-- 	calender_date date
-- ) RETURNS varchar(2) 
--     DETERMINISTIC
-- BEGIN
-- declare quarter varchar(2);
-- 	case
-- 		when month(calender_date) in('9','10','11') then 
-- 			set quarter = 'Q1';
--         when month(calender_date) in('12','1','2') then 
-- 			set quarter = 'Q2';
--         when month(calender_date) in('3','4','5') then 
-- 			set quarter = 'Q3';
--         else 
-- 			set quarter = 'Q4';
-- 	end case;
-- RETURN quarter;
-- END


-- Aggregate monthly gross sales report for croma india
select fs.date,round(sum(sold_quantity*gross_price),2) as gross_price_total
from fact_sales_monthly fs
join fact_gross_price fg
on fs.product_code = fg.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
where customer_code = '90002002'
group by fs.date
order by fs.date;

-- Generate a yearly report for Croma India where there are two columns
select fg.fiscal_year as year,round(sum(sold_quantity*gross_price),2) as gross_price_total
from fact_sales_monthly fs
join fact_gross_price fg
on fg.product_code = fs.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
where customer_code = '90002002'
group by year
order by year desc;


-- create stored proc that can determine market badge based on the following logic.
select dm.market,sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly fs
join dim_customer dm
on fs.customer_code = dm.customer_code
join fact_gross_price fg
on fs.product_code = fg.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
where get_fiscal_year(fs.date) = 2021
group by dm.market;

-- stored proc to get_market_badge
-- CREATE PROCEDURE `get_market_badge`(
-- 	IN in_market varchar(45),
--     IN in_fiscal_year year,
--     OUT out_market_badge varchar(10)
-- )
-- BEGIN
-- 	declare qty int default 0;
--     
--     -- set default value
--     if in_market =  "" then
-- 		set out_market_badge = 'india';
--     end if;    
--     
--    select sum(sold_quantity) into qty
-- 	from fact_sales_monthly fs
-- 	join dim_customer dm
-- 	on fs.customer_code = dm.customer_code
-- 	where market = in_market and get_fiscal_year(fs.date) = in_fiscal_year
--     group by dm.market;
-- 	
--     if qty > 5000000 then
-- 		set out_market_badge = 'Gold';
-- 	else 	
-- 		set out_market_badge = 'Silver';
--     end if;    
-- END

-- Include pre-invoice deductions in Croma detailed report

select fs.date,fs.product_code,dp.product,dp.variant, fs.sold_quantity,fg.gross_price as gross_price_per_item,
round(fs.sold_quantity*fg.gross_price,2) as gross_price_total,pre.pre_invoice_discount_pct
from fact_sales_monthly fs
join dim_product dp
on dp.product_code = fs.product_code
join fact_gross_price fg
on fg.product_code = fs.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
join fact_pre_invoice_deductions pre 
on pre.customer_code = fs.customer_code and pre.fiscal_year = get_fiscal_year(fs.date)
WHERE fs.customer_code=90002002 AND get_fiscal_year(fs.date)=2021;

-- Same report but all the customers
select fs.date,fs.product_code,dp.product,dp.variant, fs.sold_quantity,fg.gross_price as gross_price_per_item,
round(fs.sold_quantity*fg.gross_price,2) as gross_price_total,pre.pre_invoice_discount_pct
from fact_sales_monthly fs
join dim_product dp
on dp.product_code = fs.product_code
join fact_gross_price fg
on fg.product_code = fs.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
join fact_pre_invoice_deductions pre 
on pre.customer_code = fs.customer_code and pre.fiscal_year = get_fiscal_year(fs.date)
WHERE get_fiscal_year(fs.date)=2021;

-- -- Get the net_invoice_sales amount using the CTE's
with cte_1 as
(
select fs.date,fs.product_code,dp.product,dp.variant, fs.sold_quantity,fg.gross_price as gross_price_per_item,
round(fs.sold_quantity*fg.gross_price,2) as gross_price_total,pre.pre_invoice_discount_pct
from fact_sales_monthly fs
join dim_product dp
on dp.product_code = fs.product_code
join fact_gross_price fg
on fg.product_code = fs.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
join fact_pre_invoice_deductions pre 
on pre.customer_code = fs.customer_code and pre.fiscal_year = get_fiscal_year(fs.date)
WHERE get_fiscal_year(fs.date)=2021
)

select *,
(1-pre_invoice_discount_pct)*gross_price_total as net_invoice_sales
from cte_1
limit 1500000;


-- Creating the view `sales_preinv_discount` and store all the data in like a virtual table
Create view sales_preinvoice_discount as
select fs.date,fs.customer_code,dm.market,fs.product_code,dp.product,dp.variant, fs.sold_quantity,fg.gross_price as gross_price_per_item,
round(fs.sold_quantity*fg.gross_price,2) as gross_price_total,pre.pre_invoice_discount_pct
from fact_sales_monthly fs
join dim_customer dm
on dm.customer_code = fs.customer_code
join dim_product dp
on dp.product_code = fs.product_code
join fact_gross_price fg
on fg.product_code = fs.product_code and fg.fiscal_year = get_fiscal_year(fs.date)
join fact_pre_invoice_deductions pre 
on pre.customer_code = fs.customer_code and pre.fiscal_year = get_fiscal_year(fs.date);

-- Now generate net_invoice_sales using the above created view "sales_preinv_discount"
select *,
(1-pre_invoice_discount_pct)*gross_price_total as net_invoice_sales
from sales_preinvoice_discount
limit 1500000;

-- Creating the view `sales_postinv_discount` and store all the data in like a virtual table
create view sales_postinv_discount as
select s.date,s.customer_code,s.market,s.product_code,s.product,s.variant, s.sold_quantity,
s.gross_price_per_item, s.gross_price_total,s.pre_invoice_discount_pct,(1-s.pre_invoice_discount_pct)*
s.gross_price_total as net_invoice_sales,pos.discounts_pct+pos.other_deductions_pct as post_invoice_discount_pct
from sales_preinv_discount s
join fact_post_invoice_deductions pos
on pos.customer_code = s.customer_code and pos.product_code = s.product_code and pos.date = s.date;

-- -- Create a report for net sales
select *,
(1-post_invoice_discount_pct)*net_invoice_sales
from sales_postinv_discount;

-- Finally creating the view `net_sales` which inbuiltly use/include all the previous created view and gives the final result

create or replace view net_sales as
select *,
(1-post_invoice_discount_pct)*net_invoice_sales as net_sales
from sales_postinv_discount;


-- Get top 5 market by net sales in fiscal year 2021
SELECT market,
sum(net_sales)/1000000 as net_sales_mln
FROM net_sales
where get_fiscal_year(date) = 2021
group by market
order by net_sales_mln desc
limit 5;


-- Stored proc to get top n markets by net sales for a given year

-- CREATE DEFINER=`root`@`localhost` PROCEDURE `top_n_market`(
-- 	in_fiscal_year int,
--     in_limit int
-- )
-- BEGIN
-- 	SELECT market,
-- 	sum(net_sales)/1000000 as net_sales_mln
-- 	FROM net_sales
--     where get_fiscal_year(date) = in_fiscal_year
-- 	group by market
-- 	order by net_sales_mln desc
-- 	limit in_limit;
-- END

-- Get top 5 customer by net sales in fiscal year 2021
SELECT c.customer,
sum(net_sales)/1000000 as net_sales_mln
FROM net_sales s
join dim_customer c 
on c.customer_code = s.customer_code 
where get_fiscal_year(date) = 2021 and s.market = 'india'
group by c.customer
order by net_sales_mln desc
limit 5;

-- stored procedure that takes market, fiscal_year and top n as an input and returns top n customers by net sales in that given fiscal year and market

-- CREATE  PROCEDURE `get_top_n_customers_by_net_sales`(
-- 	in_market varchar(45),
--     in_fiscal_year int,
--     in_top_n int
-- )
-- BEGIN
-- 	SELECT c.customer,
-- 	sum(net_sales)/1000000 as net_sales_mln
-- 	FROM net_sales s
-- 	join dim_customer c 
-- 	on c.customer_code = s.customer_code 
-- 	where get_fiscal_year(date) = in_fiscal_year and s.market = in_market
-- 	group by c.customer
-- 	order by net_sales_mln desc
-- 	limit in_top_n;
-- END





