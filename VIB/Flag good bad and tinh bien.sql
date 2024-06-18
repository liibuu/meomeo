

SELECT distinct customer_number
	into ##CUSTOMER_GB
	from MyVIB_Activity
	where ACTIVITY_DATE >= '2019/01/01' and ACTIVITY_DATE <= '2019/03/31'
	and ACTIVITY_NAME not in (	'SET_PASSWORD',
								'LOGIN_FINGER',
								'MB_SET_PIN',
								'LOGIN',
								'MB_CHANGE_PIN',
								'CHANGE_PASSWORD',
								'MB_RESET_PIN',
								'LOGOUT',
								'LOGIN_FACEID')

Alter table ##CUSTOMER_GB
	add	flag_trans_1 float, flag_trans_2 float,
		flag_acti_2 float,
		flag_good_bad varchar(50)

Update ##CUSTOMER_GB
	set flag_trans_1 = 1
	from	(select customer_number from MyVIB_Transaction
			where TRANS_DATE >= '2019/01/01' and TRANS_DATE <= '2019/03/31') a
	where ##CUSTOMER_GB.customer_number = a.customer_number

Update ##CUSTOMER_GB
	set flag_good_bad = 'g'
	where flag_trans_1 = 1

Update ##CUSTOMER_GB
	set flag_good_bad = 'g'
	from	(select customer_number from MyVIB_Activity
			where	ACTIVITY_NAME not like '%TRANSFER%' 
				OR	ACTIVITY_NAME NOT LIKE '%BILLPAY%'
				OR	ACTIVITY_NAME NOT LIKE '%TOPUP%') a
	where ##CUSTOMER_GB.customer_number = a.customer_number
	AND	FLAG_TRANS_1 IS NULL

SELECT customer_number
	INTO #CUSTOMER
	FROM ##CUSTOMER_GB
	WHERE FLAG_GOOD_BAD = 'G'

SELECT * FROM #CUSTOMER

ALTER TABLE #CUSTOMER
	ADD	FLAG_ACTI FLOAT,
		FLAG_TRANS FLOAT,
		FLAG_GOOD_BAD VARCHAR

UPDATE #CUSTOMER	
	SET flag_acti = 1 
	from	(SELECT distinct customer_number
			from MyVIB_Activity
			where ACTIVITY_DATE >= '2019/04/01' and ACTIVITY_DATE <= '2019/06/30'
			and ACTIVITY_NAME not in (	'SET_PASSWORD',
										'LOGIN_FINGER',
										'MB_SET_PIN',
										'LOGIN',
										'MB_CHANGE_PIN',
										'CHANGE_PASSWORD',
										'MB_RESET_PIN',
										'LOGOUT',
										'LOGIN_FACEID') 
			) a
	where #CUSTOMER.customer_number = a.customer_number

Update #CUSTOMER	
	set flag_good_bad = 'b'
	where flag_acti is null

Update #CUSTOMER
	set flag_trans = 1
	from	(select customer_number from MyVIB_Transaction
			where TRANS_DATE >= '2019/04/01' and TRANS_DATE <= '2019/06/30') a
	where #CUSTOMER.customer_number = a.customer_number
	

Update #CUSTOMER
	set flag_good_bad = 'g'
	from	(select customer_number from MyVIB_Activity
			where	ACTIVITY_NAME not like '%TRANSFER%' 
				OR	ACTIVITY_NAME NOT LIKE '%BILLPAY%'
				OR	ACTIVITY_NAME NOT LIKE '%TOPUP%') a
	where #CUSTOMER.customer_number = a.customer_number
	and flag_acti = 1
	and flag_trans is NULL

Update #CUSTOMER
	set flag_good_bad = 'b'
	where flag_good_bad is null

---------------------------------------tinh bien--------------------------------------

ALTER TABLE #CUSTOMER
LOAN_COUNT_2M	FLOAT,
LOAN_COUNT_1M	FLOAT,
DEP_COUNT_CA_ACCT_2M	FLOAT,
DEP_COUNT_CA_ACCT_1M	FLOAT,
DEP_COUNT_TD_ACCT_2M	FLOAT,
DEP_COUNT_TD_ACCT_1M	FLOAT,
DEP_COUNT_CA_TD_1M	FLOAT,
DEP_CA_BALANCE_2M	FLOAT,
DEP_CA_BALANCE_1M	FLOAT,
DEP_TD_BALANCE_2M	FLOAT,
DEP_TD_BALANCE_1M	FLOAT


UPDATE #CUSTOMER	
	SET 	APP_DATEDIFF_CIF_IB = A.AGE
	FROM	(SELECT customer_number, DATEDIFF(DAY, CLIENT_CREATE_DATE, IB_REGISTER_DATE) AS AGE FROM 
			#CUSTOMER) A 
	WHERE #CUSTOMER.customer_number = A.customer_number


select top 20 * from #CUSTOMER
select top 20 * from MyVIB_Transaction
select top 20 * from MyVIB_Activity
select top 20 * from card
select top 20 * from lending
select top 20 * from deposit


select b.customer_number, trans_date, trans_lv1, trans_lv2, day_of_week, trans_hour, trans_no, trans_amount
into ##transaction
from	(select * from myvib_transaction
		where trans_date >= '2019/01/01' and trans_date <= '2019/03/31') a
inner join #CUSTOMER b
on a.customer_number = b.customer_number

alter table ##transaction
add m1 float, m2 float, m3 float

SELECT * FROM ##transaction

update #CUSTOMER
SET TRANS_MAX_NO = TRANS
FROM	(select DISTINCT customer_number, MAX(TRANS_NO) OVER (PARTITION BY customer_number) AS TRANS
		from ##transaction
		) A
WHERE #CUSTOMER.customer_number = A.customer_number



/*Loại trans được giao dịch nhiều nhất của mỗi người*/
select customer_number, trans_lv2, count(*) as total
into ##transaction2
from ##transaction
group by customer_number, trans_lv2
order by customer_number

drop table #A
select customer_number, trans_lv2, total
	into #A
	from	(select customer_number, trans_lv2, total,  dense_rank() over (partition by customer_number order by total desc) as rn
			from ##transaction2
			) a
	where rn = 1
	drop table #B
select customer_number, trans_lv2, total, count(trans_lv2) over (partition by customer_number) as count
	into #B
	from #A

select customer_number, trans_lv2, total, count, lag(trans_lv2, 1) over (partition by customer_number order by total) as lag_trans
	into #C
	from #B

update #CUSTOMER
	set TRANS_TYPE_LIKE_LV2 = a.trans_lv2
	from	(select customer_number, trans_lv2
			from #C
			where count = 1
			) a
	where #CUSTOMER.customer_number = a.customer_number

select * from #C
order by customer_number

update #CUSTOMER
	set TRANS_HOUR_TYPE_LIKE_LV1 = avg
	from	(select customer_number, avg(total) as avg
			from #C
			group by customer_number) a
	where 	#CUSTOMER.customer_number = a.customer_number

ALTER TABLE ##TRANSACTION
ADD MONTH FLOAT

SELECT customer_number, MONTH, SUM(TRANS_NO) AS SUM_TRANS_AMOUNT
			INTO #E
			FROM ##TRANSACTION
			GROUP BY customer_number, MONTH
			ORDER BY customer_number, MONTH

UPDATE #CUSTOMER
	SET TRANs_AVG_NO_MONTH = A.TRANS
	FROM	(
			SELECT DISTINCT customer_number, AVG(SUM_TRANS_AMOUNT) OVER (PARTITION BY customer_number) AS TRANS
			FROM #e
			) A
	WHERE	#CUSTOMER.customer_number = a.customer_number

	
SELECT * FROM #CUSTOMER

SELECT DISTINCT A.customer_number, MIN(A.ACTIVITY_DATE) OVER (PARTITION BY A.customer_number) AS FIRST_ACTI, B.IB_REGISTER_DATE
	--INTO #A1
	FROM ##ACTIVITY A
	INNER JOIN #CUSTOMER B
	ON A.customer_number = B.customer_number

UPDATE #CUSTOMER
	SET ACTI_DATEDIFF_FIRST_ACTI = A.ACTI
	FROM 
	(
	SELECT customer_number, DATEDIFF(DAY, IB_REGISTER_DATE, FIRST_ACTI) AS ACTI
	FROM #a1
	) A
	WHERE	#CUSTOMER.customer_number = a.customer_number

SELECT customer_number, ACTIVITY_DATE, LAG(ACTIVITY_DATE, 1) OVER (PARTITION BY customer_number ORDER BY ACTIVITY_DATE) AS LAG_ACTIVITY_DATE
	--INTO #H
	FROM ##ACTIVITY




UPDATE #CUSTOMER
	SET ACTI_MAX_DATEDIFF = A.MAX_ACTI
	FROM	(SELECT DISTINCT customer_number, MAX(ACTI) OVER (PARTITION BY customer_number) AS MAX_ACTI
			FROM #m) A
	WHERE #CUSTOMER.customer_number = a.customer_number

SELECT COUNT (*) FROM #CUSTOMER
WHERE ACTI_HOUR_3M IS NULL

select b.customer_number, trans_date, trans_lv1, trans_lv2, day_of_week, trans_hour, trans_no, trans_amount
into #G
from	(select * from myvib_transaction
		where trans_date >= '2019/01/01' and trans_date <= '2019/03/31'
		AND TRANS_LV2 NOT LIKE '%REPAYMENT%') a
inner join #CUSTOMER b
on a.customer_number = b.customer_number

UPDATE #CUSTOMER
	SET DEP_TD_BALANCE_2M = DEP
	FROM	(SELECT DISTINCT customer_number, AVG(AVG_TD_BALANCE) OVER (PARTITION BY customer_number) AS DEP
			FROM Deposit
			WHERE MONTH <= '2019/03/31' AND MONTH >= DATEADD (MONTH, -2, '2019/03/31')
			) A
	WHERE #CUSTOMER.customer_number = a.customer_number

SELECT * FROM #CUSTOMER
SELECT customer_number, ACTIVITY_NO, ACTIVITY_DATE, DATEPART(MONTH, ACTIVITY_DATE) AS MONTH
	INTO #Q
	FROM ##ACTIVITY

SELECT customer_number, MONTH, SUM(ACTIVITY_NO) AS ACTI_MONTH
	--INTO #W
	FROM #Q
	GROUP BY customer_number, MONTH
	ORDER BY customer_number, MONTH


SELECT customer_number, ACTI_DATEDIFF_FIRST_ACTI
FROM #CUSTOMER
WHERE ACTI_DATEDIFF_FIRST_ACTI < 0
