CREATE OR REPLACE VIEW cust_details AS (SELECT cust_name, cust_address, cust_dob, cust_phnum, login_uname FROM (customer NATURAL JOIN cust_phoneNum natural join credentials_cust natural join credentials)); -- for customer view

create or replace view view_accounts as (SELECT acc_num,login_uname from cust_account natural join credentials_cust natural join credentials);

create or replace view show_transaction_log as (select trans_type,trans_amt, trans_date, s_acc_num, r_acc_num from transactions);

CREATE OR REPLACE VIEW emp_details AS (SELECT emp_name, emp_add, emp_dob, emp_salary, emp_uname, emp_id FROM employee); -- for employee view

CREATE OR REPLACE VIEW pending_loans AS (SELECT ln_status, cust_phnum FROM loan  NATURAL JOIN cust_account  NATURAL JOIN cust_phonenum ); -- for employee view

