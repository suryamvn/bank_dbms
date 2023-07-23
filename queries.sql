-- role: customer
select * from view_balance(id INT, uname VARCHAR(50), pword VARCHAR(50));

call update_customer(uname VARCHAR(50), address TEXT, phone_no VARCHAR(10));

call transfer_amount(sender_acc_num INT, receiver_acc_num INT, amt NUMERIC(12, 2), uname VARCHAR(50), pword VARCHAR(50));

-- role: employee

call deposit_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), e_id INT);

call withdraw_amount(id INT, amt NUMERIC(12, 2), uname VARCHAR(50), e_id INT);