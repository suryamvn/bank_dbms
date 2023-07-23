CREATE OR REPLACE FUNCTION update_loan_status()
RETURNS trigger
AS $update_loan_status$
DECLARE
    balance NUMERIC(12,2);
    temp_acc_num int;
BEGIN
    SELECT ln_amt INTO balance FROM loan WHERE ln_id = new.ln_id;
    IF (balance<=0) THEN
    BEGIN
        update loan set ln_status=0 where ln_id=new.ln_id;
        select acc_num into temp_acc_num from loan where ln_id=new.ln_id;
        delete from account where acc_num=temp_acc_num;
    end;
    END IF;
    RETURN NEW;
END;
$update_loan_status$ LANGUAGE plpgsql;

CREATE trigger loan_update
after update
ON loan
FOR EACH row
WHEN (OLD.ln_amt IS DISTINCT FROM NEW.ln_amt)
EXECUTE PROCEDURE update_loan_status();

CREATE OR REPLACE FUNCTION tot_trans_user()
RETURNS trigger
AS $tot_trans_user$
DECLARE
    tot_trans numeric(12,2);
BEGIN
    select sum(trans_amt) into tot_trans from transactions where date_part('day',age(now(),trans_date))<1 and s_acc_num=new.s_acc_num and trans_type='transfer' group by (s_acc_num); 
    IF (tot_trans+new.trans_amt>100000) THEN
    BEGIN
        raise exception 'Total transactions per day must not exceed 100000';
    end;
    END IF;
    RETURN NEW;
END;
$tot_trans_user$ LANGUAGE plpgsql;

CREATE trigger tot_trans
before insert
ON transactions
FOR EACH row
EXECUTE PROCEDURE tot_trans_user();

CREATE OR REPLACE FUNCTION check_min_balance()
RETURNS trigger
AS $check_min_balance$
DECLARE
    balance numeric(12,2);
BEGIN
    select acc_balance into balance from account where acc_num=new.s_acc_num;
    IF (balance<3000) THEN
    BEGIN
        raise exception 'Available balance is less than min balance';
    end;
    END IF;
    RETURN NEW;
END;
$check_min_balance$ LANGUAGE plpgsql;

CREATE trigger min_balance
before insert
ON transactions
FOR EACH row
EXECUTE PROCEDURE check_min_balance();