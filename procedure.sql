




CREATE OR REPLACE PROCEDURE transfer_amount(sender_acc_num INT, receiver_acc_num INT, amt NUMERIC(12, 2), uname VARCHAR(50), pword VARCHAR(50))
AS $transfer_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
    temp_ln_id int;
    res_pay int;
BEGIN
    if((select acc_type from account where acc_num=receiver_acc_num)<>'loan' and (select acc_type from account where acc_num=sender_acc_num)<>'loan')
    THEN
    BEGIN
        IF EXISTS (SELECT login_id FROM credentials WHERE login_uname = uname AND login_pwd = pword) THEN
        BEGIN
            IF EXISTS (SELECT acc_num FROM credentials_cust natural join credentials natural join cust_account WHERE login_uname = uname AND login_pwd=pword) AND EXISTS (SELECT acc_num FROM account WHERE acc_num = receiver_acc_num) THEN
                SELECT acc_balance INTO temp_amt FROM account WHERE acc_num = sender_acc_num;
                IF (temp_amt >= amt  AND amt <= 10000000) THEN
                BEGIN
                    UPDATE account SET acc_balance = acc_balance - amt WHERE acc_num = sender_acc_num;
                    UPDATE account SET acc_balance = acc_balance + amt WHERE acc_num = receiver_acc_num;
                    SELECT cust_id INTO temp_cid FROM cust_account WHERE acc_num = sender_acc_num;
                    SELECT emp_id INTO temp_eid FROM customer WHERE cust_id = temp_cid;
                    SELECT login_id INTO temp_lid FROM credentials WHERE login_uname = uname;
                    INSERT INTO transactions (trans_type, trans_amt, trans_date, s_acc_num, r_acc_num, cust_id, emp_id, login_id) VALUES
                    ('transfer', amt, now()::timestamp, sender_acc_num, receiver_acc_num, temp_cid, temp_eid, temp_lid);
                    RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt - amt);
                END;
                ELSE
                    RAISE NOTICE 'Unexpected error! Check account balance and withdrawal amount!';
                END IF;
            ELSE
                RAISE NOTICE 'Account numbers not found! Check and try again';
            END IF;
        END;
        ELSE
            RAISE NOTICE 'Cannot find account number! Check username and password!';
        END IF;
    end;
    else 
        if((select acc_type from account where acc_num=receiver_acc_num)='loan' and (select acc_type from account where acc_num=sender_acc_num)<>'loan')
        then
        BEGIN
            IF EXISTS (SELECT login_id FROM credentials WHERE login_uname = uname AND login_pwd = pword) THEN
            BEGIN
                IF EXISTS (SELECT acc_num FROM credentials_cust natural join credentials natural join cust_account WHERE login_uname = uname AND login_pwd=pword) AND EXISTS (SELECT acc_num FROM account WHERE acc_num = receiver_acc_num) THEN
                    SELECT acc_balance INTO temp_amt FROM account WHERE acc_num = sender_acc_num;
                    IF (temp_amt >= amt  AND amt <= 10000000) THEN
                    BEGIN
                        SELECT cust_id INTO temp_cid FROM cust_account WHERE acc_num = sender_acc_num;
                        SELECT emp_id INTO temp_eid FROM customer WHERE cust_id = temp_cid;
                        SELECT login_id INTO temp_lid FROM credentials WHERE login_uname = uname;
                        select ln_id into temp_ln_id from loan where acc_num=receiver_acc_num;
                        select * from pay_loan(receiver_acc_num, temp_eid, temp_ln_id, amt) into res_pay;
                        if(res_pay=1)
                        THEN  
                        BEGIN
                            UPDATE account SET acc_balance = acc_balance - amt WHERE acc_num = sender_acc_num;
                            INSERT INTO transactions (trans_type, trans_amt, trans_date, s_acc_num, r_acc_num, cust_id, emp_id, login_id) VALUES
                            ('transfer', amt, now()::timestamp, sender_acc_num, receiver_acc_num, temp_cid, temp_eid, temp_lid);
                            RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt - amt);
                        END;
                        else
                            RAISE NOTICE 'Unexpected error! Check account balance and withdrawal amount!';
                        end if;
                    END;
                    ELSE
                        RAISE NOTICE 'Unexpected error! Check account balance and withdrawal amount!';
                    END IF;
                ELSE
                    RAISE NOTICE 'Account numbers not found! Check and try again';
                END IF;
            END;
            ELSE
                RAISE NOTICE 'Cannot find account number! Check username and password!';
            END IF;
        end;
        else
            raise notice 'cannot make transfers from a loan account';
        end if;

    end if;
END;
$transfer_amount$ LANGUAGE plpgsql;













-- procedure to add an employee
-- input : name, address, salary, DOB, branch_id
CREATE OR REPLACE PROCEDURE add_employee(
    temp_uname VARCHAR(100),
    temp_pass VARCHAR(50),
    emp_name VARCHAR(100),
    emp_add TEXT,
    emp_salary INT,
    emp_DOB DATE,
    b_id INT
)
AS $add_employee$
DECLARE
    temp_lid INT;
    temp_eid INT;
    
BEGIN
    -- creating username and password
--     SELECT * INTO temp_uname FROM CAST(md5(random()::TEXT) AS VARCHAR(100));
--     SELECT * INTO temp_pass FROM CAST(md5(random()::TEXT) AS VARCHAR(50));
--     BEGIN
      if exists(select * from credentials where login_uname= temp_uname)
      THEN
      BEGIN
            RAISE notice 'user name already exists';
            return;
      END;
      else
            INSERT INTO credentials (login_uname, login_pwd) VALUES (temp_uname, temp_pass) RETURNING login_id INTO temp_lid;
      end if;
      INSERT INTO employee (emp_name, emp_add, emp_salary, emp_dob, branch_id, login_id) VALUES (emp_name, emp_add, emp_salary, emp_DOB, b_id, temp_lid) RETURNING emp_id INTO temp_eid;
      EXECUTE 'CREATE USER "'||temp_lid||'"';
      EXECUTE 'GRANT employee TO "'||temp_lid||'"';
      RAISE NOTICE 'Sucessfully added employee! Please note down the following credentials :
                  Employee ID : %
                  Username : %
                  Password : %',
      temp_eid, temp_uname, temp_pass;
--     END;
END;
$add_employee$ LANGUAGE plpgsql;

-- procedure to withdraw money from account
-- input : account no, amount, username, password
CREATE OR REPLACE PROCEDURE withdraw_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), e_id INT)
AS $withdraw_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
BEGIN
    if((select acc_type from account where acc_num=id)<>'loan')
    THEN
    BEGIN
        IF EXISTS (SELECT * FROM credentials_cust natural join cust_account natural join credentials WHERE login_uname = uname and acc_num = id) THEN
        SELECT acc_balance INTO temp_amt FROM account WHERE acc_num = id;
        IF (amt >= 500 AND amt <= 10000000) THEN
            BEGIN
            UPDATE account SET acc_balance = acc_balance - amt WHERE acc_num = id;
            SELECT cust_id INTO temp_cid FROM cust_account WHERE acc_num = id;
            SELECT login_id INTO temp_lid FROM credentials_cust WHERE cust_id = temp_cid;
            INSERT INTO transactions (trans_type, trans_amt, trans_date, s_acc_num, r_acc_num, cust_id, emp_id, login_id) VALUES
            ('withdraw', amt, now()::timestamp, id, id, temp_cid, e_id, temp_lid);
            RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt - amt);
            END;
            ELSE
            RAISE NOTICE 'Insufficient balance in account! Balance amount : %', temp_amt;
            END IF;
        ELSE
            RAISE NOTICE 'Account doesnot exist. Check input account number!';
        END IF;
    end;
    else
        RAISE NOTICE 'Cannot withdraw money form loan account';
    end if;
END;

$withdraw_amount$ LANGUAGE plpgsql;

-- procedure to deposit money
-- input : accout no, amount, username, password
CREATE OR REPLACE PROCEDURE deposit_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), e_id INT)
AS $deposit_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_cid INT;
    temp_eid INT;
    temp_lid INT;
BEGIN
    if((select acc_type from account where acc_num=id)<>'loan')
    THEN
    BEGIN
        IF EXISTS (SELECT * FROM credentials_cust natural join cust_account natural join credentials WHERE login_uname = uname and acc_num = id) THEN
            SELECT acc_balance INTO temp_amt FROM account WHERE acc_num = id;
            IF (amt >= 500 AND amt <= 10000000) THEN
            BEGIN
                UPDATE account SET acc_balance = acc_balance + amt WHERE acc_num = id;
                SELECT cust_id INTO temp_cid FROM cust_account WHERE acc_num = id;
                SELECT login_id INTO temp_lid FROM credentials_cust natural join cust_account WHERE acc_num = id;
                INSERT INTO transactions (trans_type, trans_amt, trans_date, s_acc_num ,r_acc_num, cust_id, emp_id, login_id) VALUES
                ('deposit', amt, now()::timestamp, id, id, temp_cid, e_id, temp_lid);
                RAISE NOTICE 'Successfull transaction! Balance amount : %', (temp_amt + amt);
            END;
            ELSE
                RAISE NOTICE 'Cannot deposit this amount! Enter amount between 500 and 10000000';
            END IF;
        ELSE
            RAISE NOTICE 'Account doesnot exist. Check input account number!';
        END IF;
    end;
    else
        raise notice 'This is a loan account use pay loan for the transaction';
    end if;
END;
$deposit_amount$ LANGUAGE plpgsql;

-- procedure to create a loan account
-- input : name, add .... loan amt, loan type, loan interest 
--  - ---------------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE create_loan_account(
   c_name VARCHAR(100),
   c_add TEXT,
   c_dob DATE,
   c_phone VARCHAR(10),
   a_type VARCHAR(25),
   e_id INT,
   b_id INT,
   l_amt INT,
   l_type VARCHAR(25),
   l_int NUMERIC(4,2),
   l_validity_date DATE,
   temp_uname VARCHAR(100),
   temp_pass VARCHAR(50),
   new_cust int 
)

AS $create_loan_account$
DECLARE
    temp_lid INT;
    temp_ano INT;   -- acc number
    temp_cid INT;   -- cust num
    temp_len INT;               -- to store how many phone numbers are there
    temp_loanid INT;
    temp_ano1 INT;
BEGIN
    IF (l_amt >=1000.0 AND l_amt <= 10000000.0) THEN
       BEGIN
        -- this part is for account and customer table
        -- select acc_num into temp_ano1 from credentials natural join credentials_cust natural join cust_account WHERE login_uname=temp_uname;
        select * from create_account(c_name, c_add, c_dob, c_phone, a_type, e_id, b_id, temp_uname, temp_pass, new_cust) into temp_ano;
        IF temp_ano > 0 then
        BEGIN
            update account set acc_balance=-l_amt where acc_num=temp_ano;
            INSERT INTO loan (ln_type, ln_status, ln_amt, intrst_rate, branch_id, ln_valid_date, acc_num) VALUES (l_type, 1, l_amt, l_int, b_id, l_validity_date,temp_ano ) RETURNING ln_id INTO temp_loanid;
            SELECT cust_name INTO c_name FROM customer WHERE cust_id = temp_cid;
            RAISE NOTICE 'Sucessfully create account! Please note down the following credentials :
            Account number : %
            Customer ID : %
            Username : %
            Password : %
            Account type : %
            Loan ID : %',
            temp_ano, temp_cid, temp_uname, temp_pass, a_type, temp_loanid;
       END;
        ELSE
            raise notice 'invalid credentials!';
        END IF;
       END;
    END IF;
END;
$create_loan_account$ LANGUAGE plpgsql;



-- procedure to update login and password
-- input : account no, prev uname, prev pass, new uname, new pass
CREATE OR REPLACE PROCEDURE update_pwd(uname VARCHAR(100), prev_pass VARCHAR(50), new_pass VARCHAR(50))
AS $update_pwd$
DECLARE
    temp_lid INT;
BEGIN
      if exists(select * from credentials where login_uname= uname)
      THEN
      BEGIN
            -- RAISE notice 'user name already exists';
            UPDATE credentials SET login_pwd = new_pass WHERE login_uname = uname;
            EXECUTE format('ALTER USER %I WITH PASSWORD %L', uname, new_pass);
            return;
      END;
      else
            RAISE NOTICE 'user name does not exists';
      end if;
END;
$update_pwd$ LANGUAGE plpgsql
SECURITY DEFINER;

-- procedure to update customer info
-- input : customer id, add, phone no
CREATE OR REPLACE PROCEDURE update_customer(uname VARCHAR(50), address TEXT = NULL, phone_no VARCHAR(10) = NULL)
AS $update_customer$
DECLARE
    temp_cid INT;
    temp_name varchar(50);
BEGIN
--     SELECT * INTO temp_len FROM array_length(phone_no, 1);
      select cust_id into temp_cid from credentials_cust natural join credentials where login_uname = uname;
      select cust_name into temp_name from customer natural join credentials natural join credentials_cust where login_uname = uname;
    IF (address IS NOT NULL) THEN
       UPDATE customer SET cust_address = address WHERE cust_name = temp_name;
    END IF;
--     IF temp_len = 1 OR temp_len = 2 THEN
   IF (phone_no IS NOT NULL) THEN
       UPDATE cust_phonenum SET cust_phNum = phone_no WHERE cust_id = temp_cid;
   end if;
      --  INSERT INTO customer_phoneno(cust_id, cust_phoneno) SELECT id, UNNEST(phone_no);
--     ELSE
      --   RAISE NOTICE 'Only 1 or 2 phone numbers are allowed!';
--     END IF;
END;
$update_customer$ LANGUAGE plpgsql;

-- procedure to update employee info
-- input : emp id, add, salary
CREATE OR REPLACE PROCEDURE update_employee(uname varchar(50), address TEXT = NULL, salary INT = NULL)
AS $update_employee$
BEGIN
    
    IF (address IS NOT NULL) THEN
       UPDATE employee SET emp_add = address WHERE emp_uname = uname;
    END IF;
    IF (salary IS NOT NULL) THEN
       UPDATE employee SET emp_salary = salary WHERE emp_uname = uname;
    END IF;
END;
$update_employee$ LANGUAGE plpgsql;

create or replace procedure update_loan_accounts_monthly()
AS $update_loan_accounts_monthly$
declare
    temp_arr1 integer array;
    temp_arr3 numeric(4,2) array;
    temp_arr2 numeric(12,2) array;
    count int;
    cnt1 int;
    row loan%rowtype;
BEGIN
    cnt1=0;
    for row in (select *  from loan where date_part('month',age(now(),last_updated)) = 1 and ln_status=1) loop
        temp_arr1[cnt1] = row.acc_num;
        temp_arr2[cnt1] = row.ln_amt;
        temp_arr3[cnt1] = row.intrst_rate;
        cnt1=cnt1+1;
    end loop;
    select count(ln_id) into count from loan where date_part('month',age(now(),last_updated)) = 1 and ln_status=1;
    for cnt in 0..count-1 loop
        raise notice '% arr1 : % arr2:% value:% count:%', temp_arr1[cnt],temp_arr2[cnt], temp_arr3[cnt],((temp_arr2[cnt]*temp_arr3[cnt])/100),count;
        update account set acc_balance = acc_balance - ((temp_arr2[cnt]*temp_arr3[cnt])/100) where acc_num = temp_arr1[cnt];
    end loop;
    update loan set last_updated = now() where date_part('month',age(now(),last_updated)) = 1 and ln_status=1;
END;
$update_loan_accounts_monthly$ LANGUAGE plpgsql;

CREATE OR REPLACE procedure create_account2(
      c_name VARCHAR(100),
      c_address TEXT,
      c_dob DATE,
      c_ph VARCHAR(10),
      a_type VARCHAR(25),
      e_id INT,
      b_id INT,
      temp_uname VARCHAR(100),
      temp_pass VARCHAR(50),
      new_cust int
)
AS $create_account2$
DECLARE
      temp_ano INT;
      temp_cid INT;
      temp_lid INT;
      temp_len INT;
BEGIN
      -- SELECT * INTO temp_len FROM array_length(c_ph, 1);
      -- 
      IF ( a_type <> 'jointAccount' ) THEN
            -- IF (temp_len = 1 OR temp_len = 2) THEN
            BEGIN
                  IF (new_cust=1)
                  THEN
                  BEGIN
                        if exists(select * from credentials where login_uname= temp_uname)
                        THEN
                        BEGIN
                              RAISE notice 'user name already exists';
                        END;
                        else
                              INSERT INTO credentials (login_uname, login_pwd) VALUES (temp_uname, temp_pass) RETURNING login_id INTO temp_lid;
                        end if;
                        SELECT add_customer(c_name ,c_address,c_dob, c_ph, temp_uname, temp_pass , e_id, temp_lid ,new_cust) INTO temp_cid;
                        INSERT INTO credentials_cust (login_id, cust_id) VALUES (temp_lid, temp_cid);
                  end;
                  ELSE
                  BEGIN
                        SELECT add_customer(c_name ,c_address,c_dob, c_ph , temp_uname, temp_pass, e_id, temp_lid ,new_cust) INTO temp_cid;
                        IF EXISTS(select login_id from credentials_cust join credentials using(login_id) where cust_id=temp_cid AND login_uname=temp_uname AND login_pwd=temp_pass)
                        THEN
                              RAISE NOTICE 'authentication successful';
                        ELSE
                        BEGIN
                              RAISE NOTICE 'credentials doesnot match';
                        end;
                        end if;
                  END;
                  END if;
                  INSERT INTO account (acc_type, acc_balance, branch_id) VALUES (a_type, 3000, b_id) RETURNING acc_num INTO temp_ano;
                  INSERT INTO cust_account (cust_id, acc_num) VALUES (temp_cid, temp_ano);
                  RAISE NOTICE 'Sucessfully created the account! Credentials are as follows:
                  Account number : %
                  Customer ID : %
                  Username : %
                  Password : %',
                  temp_ano, temp_cid, temp_uname, temp_pass;
            END;
      ELSE
            RAISE NOTICE 'NOTICE: This procedure doesnot allow the creation of joint accounts!';
      END IF;
END;
$create_account2$ LANGUAGE plpgsql;