CREATE INDEX ON credentials USING hash(login_uname);
CREATE INDEX ON transactions USING BTREE(trans_date);
CREATE INDEX ON transactions USING BTREE(s_acc_num, r_acc_num, trans_amt, trans_type);
CREATE INDEX ON Customer USING BTREE(cust_name, cust_address, cust_DOB);
CREATE INDEX ON cust_phonenum using hash(cust_phnum);
CREATE INDEX ON employee USING BTREE(emp_name, emp_salary, emp_uname, emp_DOB);
CREATE INDEX ON account USING hash(acc_num);