--Inspectin Data
 Select * from [dbo].[sales_data_sample]


 --Checking Unique Values

 Select distinct status from [dbo].[sales_data_sample]
 select distinct year_id from [dbo].[sales_data_sample]
 select distinct PRODUCTLINE from [dbo].[sales_data_sample]
 select distinct COUNTRY from [dbo].[sales_data_sample]
 select distinct DEALSIZE from [dbo].[sales_data_sample]
 select distinct TERRITORY from [dbo].[sales_data_sample]


 select distinct MONTH_ID from [dbo].[sales_data_sample]
 where YEAR_ID = 2003

  --Analysis
 ----Grouping sales by production
 select PRODUCTLINE, sum(sales) Revenue
 from [dbo].[sales_data_sample]
 group by PRODUCTLINE
 order by 2 desc


 --Analysis
 ----Grouping sales by production
 select YEAR_ID, sum(sales) Revenue
 from [dbo].[sales_data_sample]
 group by YEAR_ID
 order by 2 desc


  --Analysis
 ----Grouping sales by production
 select DEALSIZE, sum(sales) Revenue
 from [dbo].[sales_data_sample]
 group by DEALSIZE
 order by 2 desc

--Best month for sales in a specific year? Earning of the month?
 select MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
 from [AdventureWorksLT2019].[dbo].[sales_data_sample]
 Where YEAR_ID = 2004--Rest of the Year
 group by MONTH_ID
 order by 2 desc


 --Seems to be November Month,type of product sell in November
 select MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER)
 from [AdventureWorksLT2019].[dbo].[sales_data_sample]
 Where YEAR_ID = 2003 and MONTH_ID = 11--Rest of the Year
 group by MONTH_ID, PRODUCTLINE
 order by 3 desc

 --Best Customer(answered with RFM)


 DROP TABLE IF EXISTS #rfm
;With rfm as
(
 select
   CUSTOMERNAME,
   sum(sales) MonetaryValue,
   avg(sales) AvgMonetaryValue,
   count(ORDERNUMBER) Frequency,
   max(ORDERDATE) last_order_date,
   (select max(ORDERDATE) from [dbo].[sales_data_sample]) max_order_date,
   DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) Recency
from [AdventureWorksLT2019]. [dbo].[sales_data_sample]
group by CUSTOMERNAME
),
rfm_calc as
(
select r.*,
    NTILE(4) OVER (order by Recency desc) rfm_recency,
	NTILE(4) OVER (order by frequency) rfm_frequency,
	NTILE(4) OVER (order by MonetaryValue) rfm_monetary
from rfm r
)
select 
    c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
    cast(rfm_recency as varchar)+ cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
     case
	     when rfm_cell_string in (111,112,121,122,123,132,211,212,112,141) then 'lost_customers' --lost customers
		 when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away,don not lose' --purchased lately(slipping away)
		 when rfm_cell_string in (311,411,331) then 'new customers'--new customers
		 when rfm_cell_string in (222,223,233,322) then 'potential churners' -- potential churners
		 when rfm_cell_string in (323,333,321,422,332,432) then 'active' -- customers who buy often & recently,but low price points
		 when rfm_cell_string in (433,434,443,444) then 'loyal'
    end rfm_segement

from #rfm


--Products Sold together?
--select * from  [dbo].[sales_data_sample] where ORDERNUMBER = 10411


select distinct OrderNumber,stuff(

(select ','+ PRODUCTCODE
from [dbo].[sales_data_sample] p
where ORDERNUMBER in 
(
select ORDERNUMBER
from(
     select ORDERNUMBER, count(*) rn
	 FROM[AdventureWorksLT2019]. [dbo].[sales_data_sample]
	 where STATUS ='Shipped'
	 group by ORDERNUMBER
)m
Where rn = 3
)
and p.ORDERNUMBER = s.ORDERNUMBER
for xml path(''))
, 1,1, '') ProductCodes
from [dbo].[sales_data_sample] s
order by 2 desc
