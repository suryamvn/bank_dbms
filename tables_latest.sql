CREATE TABLE bank(bank_id SERIAL, bank_name VARCHAR(100) NOT NULL, PRIMARY KEY (bank_id));

CREATE TABLE branch(
    branch_id SERIAL,
    branch_name VARCHAR(100) NOT NULL,
    branch_address TEXT NOT NULL,
    bank_id INT NOT NULL,
    PRIMARY KEY (branch_id),
    FOREIGN KEY (bank_id) REFERENCES bank (bank_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE credentials(
    login_id SERIAL ,
    login_uname VARCHAR(100) UNIQUE NOT NULL,
    login_pwd VARCHAR(50) NOT NULL,
	PRIMARY KEY (login_id)
);

CREATE TABLE employee(
    emp_id SERIAL,
	emp_add TEXT NOT NULL,
    emp_name VARCHAR(100) NOT NULL,
    emp_DOB DATE NOT NULL check(DATE_PART('year', AGE(emp_DOB)) >= 18),
    emp_salary INT NOT NULL check(emp_salary >= 10000 AND emp_salary <= 1000000),
    branch_id INT NOT NULL,
    login_id INT NOT NULL,
    emp_uname varchar(50) not null,
    PRIMARY KEY (emp_id),
    FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (login_id) REFERENCES credentials (login_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE account(
    acc_num SERIAL,
    acc_balance NUMERIC(15, 5) NOT NULL,
    acc_type VARCHAR(25) NOT NULL check(acc_type = 'savings' OR acc_type = 'fixedDeposit' OR acc_type = 'jointAccount' OR acc_type = 'checkings' OR acc_type = 'loan'),
    branch_id INT NOT NULL,
	PRIMARY KEY (acc_num),
    FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE loan(
    ln_id SERIAL PRIMARY KEY,
	acc_num INT NOT NULL,
    ln_type VARCHAR(25) NOT NULL check(ln_type = 'personal' OR ln_type = 'business' OR ln_type = 'education' OR ln_type = 'medical' OR ln_type = 'home' OR ln_type = 'automobile'),
    ln_status INT,
    intrst_rate NUMERIC(5, 3) NOT NULL check(intrst_rate >= 0.5 AND intrst_rate <= 12.5),
    ln_amt NUMERIC(15, 5) NOT NULL check(ln_amt >= 0 AND ln_amt <=10000000.0),
    branch_id INT NOT NULL,
    last_updated date not NULL,
    FOREIGN KEY (branch_id) REFERENCES branch (branch_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE customer(
    cust_id SERIAL unique,
    cust_name VARCHAR(100) NOT NULL,
    cust_address TEXT NOT NULL,
    cust_DOB DATE NOT NULL check(DATE_PART('year', AGE(cust_DOB)) >= 18),
    emp_id INT NOT NULL,
    PRIMARY KEY (cust_id),
    FOREIGN KEY (emp_id) REFERENCES employee (emp_id) ON UPDATE CASCADE ON DELETE RESTRICT
);


CREATE TABLE cust_phoneNum(
    cust_id INT,
    cust_phNum VARCHAR(10) UNIQUE check (cust_phNum ~* '\d\d\d\d\d\d\d\d\d\d'),
    PRIMARY KEY (cust_id, cust_phNum),
    FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE cust_account(
    cust_id INT,
    acc_num INT,
    PRIMARY KEY (cust_id, acc_num),
    FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (acc_num) REFERENCES account (acc_num) ON UPDATE CASCADE ON DELETE CASCADE
);


CREATE TABLE transactions(
       trans_id SERIAL,
       trans_type VARCHAR(50) NOT NULL check(trans_type = 'deposit' OR trans_type = 'withdraw' OR trans_type = 'transfer' OR trans_type = 'loan payment'),
       trans_amt NUMERIC(12, 2) NOT NULL check(trans_amt >= 100.0),
       trans_date TIMESTAMP WITHOUT TIME ZONE NOT NULL,
       s_acc_num INT NOT NULL,
       r_acc_num INT DEFAULT NULL,
       cust_id INT NOT NULL,
       emp_id INT NOT NULL,
       login_id INT NOT NULL,
	   PRIMARY KEY (trans_id),
       FOREIGN KEY (s_acc_num) REFERENCES account (acc_num) ON UPDATE CASCADE ON DELETE CASCADE,
       FOREIGN KEY (r_acc_num) REFERENCES account (acc_num) ON UPDATE CASCADE ON DELETE CASCADE,
	   FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE,
       FOREIGN KEY (emp_id) REFERENCES employee (emp_id) ON UPDATE CASCADE ON DELETE RESTRICT,
       FOREIGN KEY (login_id) REFERENCES credentials (login_id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE credentials_cust(
       login_id INT NOT NULL,
       cust_id INT NOT NULL,
       PRIMARY KEY (login_id, cust_id),
       FOREIGN KEY (login_id) REFERENCES credentials (login_id) ON UPDATE CASCADE ON DELETE RESTRICT,
       FOREIGN KEY (cust_id) REFERENCES customer (cust_id) ON UPDATE CASCADE ON DELETE CASCADE
);