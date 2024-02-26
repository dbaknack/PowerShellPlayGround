USE msdb;

SELECT 
    log.job_id,
    job.name AS job_name,
    log.run_status,
    log.run_duration,
    log.run_date,
    log.run_time,
    log.message
FROM 
    msdb.dbo.sysjobhistory log
JOIN 
    msdb.dbo.sysjobs job ON log.job_id = job.job_id
ORDER BY 
    log.run_date DESC, log.run_time DESC;