-- function to login
CREATE OR REPLACE function login_cust(c_uname VARCHAR(50), c_pwd VARCHAR(50))
RETURNS INT
AS $check_auth$
DECLARE
      check_auth INT;
      ac_num INT;
BEGIN
      RAISE NOTICE 'Didnt even go!!!!!!!!!!';
      IF EXISTS (SELECT login_id FROM credentials WHERE login_uname=c_uname AND login_pwd=c_pwd) THEN
      BEGIN
            RAISE NOTICE 'Working!!!!!!!!!!';
            SELECT 1 INTO check_auth;
      END;
      ELSE
            RAISE NOTICE 'Nope Working!!!!!!!!!!';
            SELECT 0 INTO check_auth;
      END IF;
      RETURN check_auth;
END;
$check_auth$ LANGUAGE plpgsql;

CREATE OR REPLACE function login_emp(e_uname VARCHAR(50), e_pwd VARCHAR(50))
RETURNS INT
AS $check_auth$
DECLARE
      check_auth INT;
      ac_num INT;
BEGIN
      RAISE NOTICE 'Didnt even go!!!!!!!!!!';
      IF EXISTS (SELECT login_id FROM credentials WHERE login_uname=e_uname AND login_pwd=e_pwd) THEN
      BEGIN
            RAISE NOTICE 'Working!!!!!!!!!!';
            SELECT 1 INTO check_auth;
      END;
      ELSE
            RAISE NOTICE 'Nope Working!!!!!!!!!!';
            SELECT 0 INTO check_auth;
      END IF;
      RETURN check_auth;
END;
$check_auth$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_balance(id INT, uname VARCHAR(50), pword VARCHAR(50))
RETURNS NUMERIC(12, 2)
AS $view_balance$
DECLARE
    temp_balance NUMERIC(12, 2);
BEGIN
    IF EXISTS (SELECT acc_num FROM credentials join credentials_cust using(login_id) join cust_account using(cust_id) WHERE login_uname = uname AND login_pwd = pword AND acc_num=id) THEN
    BEGIN
          SELECT acc_balance INTO temp_balance FROM account WHERE acc_num = id;
          RAISE NOTICE 'Balance amount in the account : %', temp_balance;
          return temp_balance;
    END;
    ELSE
        RAISE NOTICE 'Cannot find account number. Check username and password!';
        return 0;
    END IF;
END;
$view_balance$ LANGUAGE plpgsql;

-- function to add customer. it will check if the customer exists or not, if not a new customer will be added and a user created for him.

CREATE OR REPLACE FUNCTION add_customer(
      c_name VARCHAR(100),
      c_address TEXT,
      c_dob DATE,
      c_ph VARCHAR(10),
      c_uname varchar(50),
      c_pwd varchar(50),
      emp_id INT,
      temp_lid INT,
      new_cust INT
      )
RETURNS INT
AS $temp_cid$
DECLARE
      temp_cid INT;
      temp_uname varchar(50);
      temp_pwd varchar(50);
BEGIN
      IF ( new_cust = 1) THEN
      BEGIN
            INSERT INTO customer (cust_name, cust_address, cust_DOB, emp_id) VALUES (c_name, c_address, c_dob, emp_id) RETURNING cust_id INTO temp_cid;
            INSERT INTO cust_phoneNum (cust_id, cust_phNum) VALUES(temp_cid, c_ph);
            -- SELECT temp_cid, UNNEST(c_ph);
            -- CREATE USER c_uname with password c_pwd;
            EXECUTE format('CREATE USER %I PASSWORD %L', c_uname, c_pwd);
            EXECUTE 'GRANT customer TO "'||c_uname||'"';
            
      END;
      ELSE
            SELECT cust_id  INTO temp_cid from customer natural join credentials_cust natural join credentials where login_uname=c_uname;
      END IF;
      RETURN temp_cid;
END;
$temp_cid$ LANGUAGE plpgsql;

-- procedure to PAY LOANS
-- input : account_no, loan_id and amount
CREATE OR REPLACE function pay_loan(acc_no INT, emp_id int, lo_id INT, amt NUMERIC(12, 2))
returns int
AS $deposit_amount$
DECLARE
    temp_amt NUMERIC(12, 2);
    temp_lamt NUMERIC(12, 2);
    temp_interest NUMERIC(4, 2);
    temp_cid INT;
    temp_lo_id INT;
    temp_lid INT;
    temp_aid INT;
    temp_l_status INT;
    temp_diff NUMERIC(12, 2);
BEGIN
    IF EXISTS (SELECT * FROM loan WHERE ln_id = lo_id AND acc_num = acc_no) THEN
        SELECT acc_balance INTO temp_amt FROM account WHERE acc_num = acc_no;
        SELECT ln_status INTO temp_l_status FROM loan WHERE ln_id = lo_id;
        SELECT ln_amt INTO temp_lamt FROM loan WHERE ln_id = lo_id;
        SELECT intrst_rate INTO temp_interest FROM loan WHERE ln_id = lo_id;
        -- SELECT loan_amt INTO tempFROM loan WHERE loan_id = lo_id
        IF (temp_l_status = 1) THEN
        BEGIN
            IF (amt>=1000.0 AND amt <= 10000000.0 AND -1*temp_amt >= amt) THEN
               BEGIN
                if(amt<=(-temp_amt-temp_lamt))
                THEN
                    UPDATE account SET acc_balance = acc_balance + amt WHERE acc_num = acc_no;
                    SELECT cust_id INTO temp_cid FROM cust_account WHERE acc_num = acc_no;
                    SELECT login_id INTO temp_lid FROM credentials_cust WHERE cust_id = temp_cid;
                    INSERT INTO transactions (trans_type, trans_amt, trans_date, s_acc_num, r_acc_num, cust_id, emp_id, login_id) VALUES
                    ('loan payment', amt, now()::timestamp, acc_no, acc_no, temp_cid, emp_id, temp_lid);
                else
                BEGIN
                    temp_diff=amt-(-temp_amt-temp_lamt);
                    RAISE NOTICE 'temp_diff : % temp_lamt: %', temp_diff, temp_lamt;
                    UPDATE account SET acc_balance = acc_balance + amt WHERE acc_num = acc_no;
                    SELECT cust_id INTO temp_cid FROM cust_account WHERE acc_num = acc_no;
                    SELECT login_id INTO temp_lid FROM credentials_cust WHERE cust_id = temp_cid;
                    INSERT INTO transactions (trans_type, trans_amt, trans_date, s_acc_num, r_acc_num, cust_id, emp_id, login_id) VALUES
                    ('loan payment', amt, now()::timestamp, acc_no, acc_no, temp_cid, emp_id, temp_lid);
                    UPDATE loan SET ln_amt=ln_amt-temp_diff where acc_num=acc_no;
                end;
                end if;
                RAISE NOTICE 'Successfull Loan Payment! Amount left to pay : %', -1 * (temp_amt + amt);
                IF(temp_amt + amt >=0) THEN
                    UPDATE loan set ln_status = 0 where ln_id = lo_id;
                END IF;
                return 1;
               END;
            ELSE
                if(amt<1000.0)
                then
                    raise notice 'minimum loan payment should be 1000 rupees';
                else
                    RAISE NOTICE 'Exceeding loan amount to be paid!';
                end if;
                return 0;
            END IF;
        END;
        ELSE
            RAISE NOTICE 'This loan is no longer active!';
            return 0;
        END IF;
    ELSE
        RAISE NOTICE 'Given account number and loan id do not share a loan. Check input account number and loan id!';
        return 0;
    END IF;
END;
$deposit_amount$ LANGUAGE plpgsql;

CREATE OR REPLACE function create_account(
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
returns int
AS $create_account$
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
                              return -2;
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
                              return -1;
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
                  return temp_ano;
            END;
      ELSE
            RAISE NOTICE 'NOTICE: This procedure doesnot allow the creation of joint accounts!';
            return 0;
      END IF;
END;
$create_account$ LANGUAGE plpgsql;