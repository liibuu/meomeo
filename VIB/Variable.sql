------- Tao DANH SACH TIME ID -----------------------

select CUSTOMER_NUMBER, TIME_ID,	case when flag_bad = 1 then 1 else 0 end as BAD,
									case when flag_bad = 1 then 0 else 1 end as GOOD,
									case when flag_bad = 1 then 'B' else 'G' end as GB
into VIB_Tinhbien_Activity
--into VIB_Tinhbien_Transaction
from (		select CUSTOMER_NUMBER, 1 as TIME_ID, flag_bad from VIB_SAMPLE_DEV
		union all
			select CUSTOMER_NUMBER, 2 as TIME_ID, flag_bad from VIB_SAMPLE_DEV
		union all
			select CUSTOMER_NUMBER, 3 as TIME_ID, flag_bad from VIB_SAMPLE_DEV
	) a

alter table VIB_Tinhbien_Activity 
add		ACTIVITY_M_NO float, ACTIVITY_M_DATE float, ACTIVITY_M_WDAY float, ACTIVITY_M_HOUR float, ACTIVITY_M_NAME float,
		ACTIVITY_NO float, ACTIVITY_DATE float, ACTIVITY_WDAY float, ACTIVITY_HOUR float, ACTIVITY_NAME float

alter table VIB_Tinhbien_Transaction 
add 	TRANS_NO float, TRANS_AMT_MAX float, TRANS_AMT_MIN float, TRANS_AMT_SUM float, TRANS_AMT_AVG float, 
		TRANS_DATE float, TRANS_WDAY float, TRANS_HOUR float, TRANS_LV1_TYPE float, TRANS_LV2_TYPE float


---******bien MEANINGFUL Activity******---

update VIB_Tinhbien_Activity set	ACTIVITY_M_NO = isnull(c.ACTIVITY_M_NO,0),
									ACTIVITY_M_DATE = isnull(c.ACTIVITY_M_DATE,0),
									ACTIVITY_M_WDAY = isnull(c.ACTIVITY_M_WDAY,0),
									ACTIVITY_M_HOUR = isnull(c.ACTIVITY_M_HOUR,0),
									ACTIVITY_M_NAME = isnull(c.ACTIVITY_M_NAME,0)
from (select a.CUSTOMER_NUMBER, a.TIME_ID,	sum(b.ACTIVITY_NO)											as ACTIVITY_M_NO, 
											count(distinct b.ACTIVITY_DATE)								as ACTIVITY_M_DATE,
											count(distinct b.DAY_OF_WEEK)								as ACTIVITY_M_WDAY,
											count(distinct concat(b.ACTIVITY_DATE, b.ACTIVITY_HOUR))	as ACTIVITY_M_HOUR,
											count(distinct b.ACTIVITY_NAME)								as ACTIVITY_M_NAME
		from VIB_Tinhbien_Activity a
		left join (select * from Data_MyVIB_Activity
					where ACTIVITY_NAME not in (	
												'SET_PASSWORD',
												'LOGIN_FINGER',
												'MB_SET_PIN',
												'LOGIN',
												'MB_CHANGE_PIN',
												'CHANGE_PASSWORD',
												'MB_RESET_PIN',
												'LOGOUT',
												'LOGIN_FACEID' 
												)
					) b
		on a.CUSTOMER_NUMBER = b.CUSTOMER_NUMBER
		and b.ACTIVITY_DATE <= dateadd(month,cast(-1 as float)*a.TIME_ID + 1,'2019/03/31')
		and b.ACTIVITY_DATE > dateadd(month,cast(-1 as float)*a.TIME_ID,'2019/03/31')
		group by a.CUSTOMER_NUMBER, a.TIME_ID
		) c
where VIB_Tinhbien_Activity.CUSTOMER_NUMBER = c.CUSTOMER_NUMBER
and VIB_Tinhbien_Activity.TIME_ID = c.TIME_ID



---******bien Activity******---

update VIB_Tinhbien_Activity set	ACTIVITY_NO = isnull(c.ACTIVITY_NO,0),
									ACTIVITY_DATE = isnull(c.ACTIVITY_DATE,0),
									ACTIVITY_WDAY = isnull(c.ACTIVITY_WDAY,0),
									ACTIVITY_HOUR = isnull(c.ACTIVITY_HOUR,0),
									ACTIVITY_NAME = isnull(c.ACTIVITY_NAME,0)
from (select a.CUSTOMER_NUMBER, a.TIME_ID,	sum(b.ACTIVITY_NO)											as ACTIVITY_NO, 
											count(distinct b.ACTIVITY_DATE)								as ACTIVITY_DATE,
											count(distinct b.DAY_OF_WEEK)								as ACTIVITY_WDAY,
											count(distinct concat(b.ACTIVITY_DATE, b.ACTIVITY_HOUR))	as ACTIVITY_HOUR,
											count(distinct b.ACTIVITY_NAME)								as ACTIVITY_NAME
		from VIB_Tinhbien_Activity a
		left join Data_MyVIB_Activity b
		on a.CUSTOMER_NUMBER = b.CUSTOMER_NUMBER
		and b.ACTIVITY_DATE <= dateadd(month,cast(-1 as float)*a.TIME_ID + 1,'2019/03/31')
		and b.ACTIVITY_DATE > dateadd(month,cast(-1 as float)*a.TIME_ID,'2019/03/31')
		group by a.CUSTOMER_NUMBER, a.TIME_ID
		) c
where VIB_Tinhbien_Activity.CUSTOMER_NUMBER = c.CUSTOMER_NUMBER
and VIB_Tinhbien_Activity.TIME_ID = c.TIME_ID



---******bien Transaction******---

update VIB_Tinhbien_Transaction set	TRANS_NO = isnull(c.TRANS_NO,0),
									TRANS_AMT_MAX = isnull(c.TRANS_AMT_MAX,0),
									TRANS_AMT_MIN = isnull(c.TRANS_AMT_MIN,0),
									TRANS_AMT_SUM = isnull(c.TRANS_AMT_SUM,0),
									TRANS_AMT_AVG = isnull(c.TRANS_AMT_AVG,0),
									TRANS_DATE = isnull(c.TRANS_DATE,0),
									TRANS_WDAY = isnull(c.TRANS_WDAY,0),
									TRANS_HOUR = isnull(c.TRANS_HOUR,0),
									TRANS_LV1_TYPE = isnull(c.TRANS_LV1_TYPE,0),
									TRANS_LV2_TYPE = isnull(c.TRANS_LV2_TYPE,0)
from (select a.CUSTOMER_NUMBER, a.TIME_ID,	sum(b.TRANS_NO)										as TRANS_NO, 
											max(b.TRANS_AMOUNT/b.TRANS_NO)						as TRANS_AMT_MAX,
											min(b.TRANS_AMOUNT/b.TRANS_NO)						as TRANS_AMT_MIN,
											sum(b.TRANS_AMOUNT)									as TRANS_AMT_SUM,
											avg(b.TRANS_AMOUNT/b.TRANS_NO)						as TRANS_AMT_AVG,
											count(distinct b.TRANS_DATE)						as TRANS_DATE,
											count(distinct b.DAY_OF_WEEK)						as TRANS_WDAY,
											count(distinct concat(b.TRANS_DATE, b.TRANS_HOUR))	as TRANS_HOUR,
											count(distinct b.TRANS_LV1)							as TRANS_LV1_TYPE,
											count(distinct b.TRANS_LV2)							as TRANS_LV2_TYPE
		from VIB_Tinhbien_Transaction a
		left join Data_MyVIB_Transaction b
		on a.CUSTOMER_NUMBER = b.CUSTOMER_NUMBER
		and b.TRANS_DATE <= dateadd(month,cast(-1 as float)*a.TIME_ID + 1,'2019/03/31')
		and b.TRANS_DATE > dateadd(month,cast(-1 as float)*a.TIME_ID,'2019/03/31')
		group by a.CUSTOMER_NUMBER, a.TIME_ID
		) c
where VIB_Tinhbien_Transaction.CUSTOMER_NUMBER = c.CUSTOMER_NUMBER
and VIB_Tinhbien_Transaction.TIME_ID = c.TIME_ID



