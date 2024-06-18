----------------1. lấy sample--------------------------
--1.1 Meaningful activity
select distinct CUSTOMER_NUMBER
into #get_sample
from Data_MyVIB_Activity
where ACTIVITY_DATE >= '2019/07/01' and ACTIVITY_DATE <= '2019/09/30'
and ACTIVITY_NAME not in (	'SET_PASSWORD',
							'LOGIN_FINGER',
							'MB_SET_PIN',
							'LOGIN',
							'MB_CHANGE_PIN',
							'CHANGE_PASSWORD',
							'MB_RESET_PIN',
							'LOGOUT',
							'LOGIN_FACEID' 
						)

--1.2 flag noise (trans w/o activity like TRANS)
alter table #get_sample add flag_trans float, flag_only_acti_trans float,
							flag_noise float

update #get_sample set flag_trans = 1
from	(select CUSTOMER_NUMBER from Data_MyVIB_Transaction
		where TRANS_DATE >= '2019/07/01' and TRANS_DATE <= '2019/09/30') a
where #get_sample.CUSTOMER_NUMBER = a.CUSTOMER_NUMBER

update #get_sample set flag_only_acti_trans = 0
from	(select CUSTOMER_NUMBER
		from Data_MyVIB_Activity
		where ACTIVITY_DATE >= '2019/07/01' and ACTIVITY_DATE <= '2019/09/30'
		and ACTIVITY_NAME not in (	'SET_PASSWORD',
									'LOGIN_FINGER',
									'MB_SET_PIN',
									'LOGIN',
									'MB_CHANGE_PIN',
									'CHANGE_PASSWORD',
									'MB_RESET_PIN',
									'LOGOUT',
									'LOGIN_FACEID' )
		and ACTIVITY_NAME not like '%TRANSFER%'
		and ACTIVITY_NAME not like '%BILLPAY%'
		and ACTIVITY_NAME not like '%TOPUP%'
		) a
where #get_sample.CUSTOMER_NUMBER = a.CUSTOMER_NUMBER

update #get_sample set flag_only_acti_trans = 1 where flag_only_acti_trans is null

update #get_sample set flag_noise = case when flag_trans is null and flag_only_acti_trans = 1 then 1 else null end

--1.3 Get sample

select CUSTOMER_NUMBER
into VIB_SAMPLE_OOT
from #get_sample 
where flag_noise is null 
and flag_trans = 1

----------------2. flag good bad--------------------------

--2.1 flag meaning activity 
alter table VIB_SAMPLE_OOT add flag_activity float

update VIB_SAMPLE_OOT set flag_activity = 1
from (select CUSTOMER_NUMBER from Data_MyVIB_Activity
		where ACTIVITY_DATE >= '2019/10/01' and ACTIVITY_DATE <= '2019/12/31'
		and ACTIVITY_NAME not in (	'SET_PASSWORD',
									'LOGIN_FINGER',
									'MB_SET_PIN',
									'LOGIN',
									'MB_CHANGE_PIN',
									'CHANGE_PASSWORD',
									'MB_RESET_PIN',
									'LOGOUT',
									'LOGIN_FACEID' 
								)
		) a
where VIB_SAMPLE_OOT.CUSTOMER_NUMBER = a.CUSTOMER_NUMBER

--2.2 flag noise
alter table VIB_SAMPLE_OOT add	flag_trans float, flag_only_acti_trans float,
								flag_noise float

update VIB_SAMPLE_OOT set flag_trans = 1
from	(select CUSTOMER_NUMBER from Data_MyVIB_Transaction
		where TRANS_DATE >= '2019/10/01' and TRANS_DATE <= '2019/12/31') a
where VIB_SAMPLE_OOT.CUSTOMER_NUMBER = a.CUSTOMER_NUMBER

update VIB_SAMPLE_OOT set flag_only_acti_trans = 0
from	(select CUSTOMER_NUMBER
		from Data_MyVIB_Activity
		where ACTIVITY_DATE >= '2019/10/01' and ACTIVITY_DATE <= '2019/12/31'
		and ACTIVITY_NAME not in (	'SET_PASSWORD',
									'LOGIN_FINGER',
									'MB_SET_PIN',
									'LOGIN',
									'MB_CHANGE_PIN',
									'CHANGE_PASSWORD',
									'MB_RESET_PIN',
									'LOGOUT',
									'LOGIN_FACEID' )
		and ACTIVITY_NAME not like '%TRANSFER%'
		and ACTIVITY_NAME not like '%BILLPAY%'
		and ACTIVITY_NAME not like '%TOPUP%'
		) a
where VIB_SAMPLE_OOT.CUSTOMER_NUMBER = a.CUSTOMER_NUMBER

update VIB_SAMPLE_OOT set flag_only_acti_trans = 1 where flag_only_acti_trans is null

update VIB_SAMPLE_OOT set flag_noise = case when flag_trans is null and flag_only_acti_trans = 1 then 1 else null end

--2.3 flag good bad
alter table VIB_SAMPLE_OOT add flag_bad float

update VIB_SAMPLE_OOT set flag_bad = case when flag_activity = 1 and flag_noise is null then 0 else 1 end 









