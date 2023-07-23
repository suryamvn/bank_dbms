CREATE ROLE customer password 'customer'; -- customer group role

CREATE ROLE employee password 'employee'; -- employee group role

CREATE ROLE branch_manager password 'branch_manager'; -- branch_manager group role

GRANT EXECUTE ON FUNCTION view_balance TO customer;
GRANT EXECUTE ON procedure transfer_amount, update_pwd, update_customer(uname VARCHAR(50), address TEXT, phone_no VARCHAR(10)) TO customer;
GRANT SELECT on cust_details, show_transaction_log, view_accounts to customer;

GRANT EXECUTE ON FUNCTION view_balance,  add_customer(c_name VARCHAR(100),c_address TEXT,c_dob DATE,c_ph VARCHAR(10),c_uname varchar(50),c_pwd varchar(50),emp_id INT,temp_lid INT,new_cust INT), create_account(c_name VARCHAR(100),c_address TEXT,c_dob DATE,c_ph VARCHAR(10),a_type VARCHAR(25),e_id INT,b_id INT,temp_uname VARCHAR(100),temp_pass VARCHAR(50),new_cust int) TO employee;
GRANT EXECUTE ON PROCEDURE deposit_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), e_id INT), withdraw_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), e_id INT), transfer_amount(sender_acc_num INT, receiver_acc_num INT, amt NUMERIC(12, 2), uname VARCHAR(50), pword VARCHAR(50)), update_pwd(uname VARCHAR(100), prev_pass VARCHAR(50), new_pass VARCHAR(50)), update_customer(uname VARCHAR(50), address TEXT, phone_no VARCHAR(10)) TO employee;
GRANT SELECT on cust_details, show_transaction_log, view_accounts, pending_loans, emp_details to employee;


GRANT ALL ON ALL TABLES IN SCHEMA public TO branch_manager;
GRANT all on all functions in schema public to branch_manager;
GRANT all on all procedures in schema public to branch_manager;
GRANT SELECT on cust_details, show_transaction_log, view_accounts, pending_loans, emp_details to employee;
