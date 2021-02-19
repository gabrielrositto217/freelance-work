SELECT
		bbh.postingdate as snapshot_date,
		bbh.fdiccert,
		bbh.`sum(newbalance)` as bank_aum,
		bbh.fica_wrate as bank_rate,
		rs.fed_funds_rate,
		rs.fica_rate as sc_rate_fica,
		rs.ultra_short_rate,
		ah.asset as total_assets_q_end,
		r.region
		
FROM
		qs_bbh_by_bank bbh

	INNER JOIN
		(
		SELECT
				last_business_date
				
		FROM
			(
			SELECT
					EXTRACT(YEAR FROM postingdate) as period_year,
					EXTRACT(MONTH FROM postingdate) as period_month,
					MAX(postingdate) as last_business_date
					
			FROM
					bankbalanceshistory
					
			GROUP BY
				1, 2
			)	a
		)	lbd
	ON	bbh.postingdate = lbd.last_business_date
	
	LEFT JOIN	qs_aum_rates_summary rs
	ON	bbh.postingdate = rs.date
	
	LEFT JOIN	call_rpt_assets_liabilities ah
	ON	bbh.fdiccert = ah.cert
	AND	bbh.postingdate >= ah.call_report_date
	AND DATE_ADD(DATE_ADD(bbh.postingdate, INTERVAL 1 DAY), INTERVAL -3 MONTH) < ah.call_report_date
	
	-- Get geo data
	LEFT JOIN	bankrates br
	ON	bbh.fdiccert = br.fdic_cert_id
	
	LEFT JOIN	US_Regions r
	ON	br.state = r.state