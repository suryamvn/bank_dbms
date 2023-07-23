# installing required packages
# !pip install sqlalchemy
# !pip install psycopg2
# !pip install streamlit-authenticator
# !pip install streamlit-extras
# pip install streamlit-option-menu

# importing required packages
from streamlit_option_menu import option_menu
import time
import psycopg2
import pickle
from pathlib import Path
import streamlit as st
import sqlalchemy
#Database Utility Class
from sqlalchemy.engine import create_engine
# Provides executable SQL expression construct
from sqlalchemy.sql import text
sqlalchemy.__version__ 
from streamlit_extras.switch_page_button import switch_page
import numpy as np
import pandas as pd
import streamlit_authenticator as stauth

# import roles


# ---------------------------------------------------------------------------------

class PostgresqlDB:
    def __init__(self,user_name,password,host,port,db_name):
        """
        class to implement DDL, DQL and DML commands,
        user_name:- username
        password:- password of the user
        host
        port:- port number
        db_name:- database name
        """
        self.user_name = user_name
        self.password = password
        self.host = host
        self.port = port
        self.db_name = db_name
        self.engine = self.create_db_engine()

    def create_db_engine(self):
        """
        Method to establish a connection to the database, will return an instance of Engine
        which can used to communicate with the database
        """
        try:
            db_uri = f"postgresql+psycopg2://{self.user_name}:{self.password}@{self.host}:{self.port}/{self.db_name}"
            return create_engine(db_uri)
        except Exception as err:
            raise RuntimeError(f'Failed to establish connection -- {err}') from err

    def execute_dql_commands(self,stmnt,values=None):
        """
        DQL - Data Query Language
        SQLAlchemy execute query by default as 

        BEGIN
        ....
        ROLLBACK 

        BEGIN will be added implicitly everytime but if we don't mention commit or rollback explicitly 
        then rollback will be appended at the end.
        We can execute only retrieval query with above transaction block.If we try to insert or update data 
        it will be rolled back.That's why it is necessary to use commit when we are executing 
        Data Manipulation Langiage(DML) or Data Definition Language(DDL) Query.
        """
        try:
            with self.engine.connect() as conn:
                if values is not None:
                    result = conn.execute(text(stmnt),values)
                else:
                    result = conn.execute(text(stmnt))
            return result
        except Exception as err:
            print(f'Failed to execute dql commands -- {err}')
    
    def execute_ddl_and_dml_commands(self,stmnt,values=None):
        """
        Method to execute DDL and DML commands
        here we have followed another approach without using the "with" clause
        """
        connection = self.engine.connect()
        trans = connection.begin()
        try:
            if values is not None:

                result = connection.execute(text(stmnt),values)
            else:
                result = connection.execute(text(stmnt))
            # row = result.fetchmany()
            # print(row)
            trans.commit()
            return 1
            connection.close()
            # print('Command executed successfully.')
        except Exception as err:
            trans.rollback()
            return 0
            print(f'Failed to execute ddl and dml commands -- {err}')

def db_credentials(username, password):

    #Defining Db Credentials
    USER_NAME = username
    PASSWORD = password
    PORT = 5432
    # company is the database which we are connecting to
    DATABASE_NAME = 'bank' 
    HOST = 'localhost'
    #Note - Database should be created before executing below operation
    #Initializing SqlAlchemy Postgresql Db Instance
    db = PostgresqlDB(user_name=USER_NAME,
                        password=PASSWORD,
                        host=HOST,port=PORT,
                        db_name=DATABASE_NAME)
    engine = db.engine
    return db, engine






# ---------------------------------------------------------------------------------
# init session_state
if 'active_page' not in st.session_state:
    st.session_state.active_page = 'cust_or_emp'
    st.session_state.check_customer = 0
    st.session_state.check_employee = 0
    st.session_state.c_uname = ''
    st.session_state.e_uname = ''
    st.session_state.c_pwd = ''
    st.session_state.e_pwd = ''
    st.session_state.rerun = 0


st.session_state.update(st.session_state)

def cb_customer_home():
    st.session_state.active_page = 'customer_home'
def cb_employee_home():
    st.session_state.active_page = 'employee_home'
def cb_authentication():
    st.session_state.active_page = 'authentication'
def cb_customer_login():
    st.session_state.check_customer=1
    st.session_state.check_employee=0
    st.session_state.active_page = 'authentication'
def cb_employee_login():
    st.session_state.check_employee=1
    st.session_state.check_customer=0
    st.session_state.active_page = 'authentication'
def cb_cust_or_emp():
    st.session_state.active_page = 'cust_or_emp'

def authentication():

    db, engine = db_credentials('surya','surya')
    if(st.session_state.check_customer):
        st.markdown(f"""<p style="font-size:30px;text-align:center;"><b>Customer Login</b></p>""", unsafe_allow_html = True)

        userId1 = st.text_input("Customer username")
        password1 = st.text_input("Password", type="password")
        # here, there should be a link between frontend and db

        # if 'db' not in st.session_state:
        #     st.session_state.db = db_

        if(userId1 and password1):
            userId = (userId1)
            password = password1

            values = {'userId': userId,'password': password}
            login_cust_stmt = "SELECT * FROM login_cust(:userId, :password)"
            res_rows = db.execute_dql_commands(login_cust_stmt, values)
            for row in res_rows:
                login_auth_cust=row.login_cust
                print(f'login_success : {row.login_cust}')

            if(login_auth_cust==1):
                st.success(f"Logged in as {userId}")
                col1,col2 = st.columns(2)
                st.session_state.c_uname = userId
                st.session_state.c_pwd = password
                col1.button("Login",  on_click=cb_customer_home)
                col21,col22,col23 = col2.columns(3)
                col23.button("Go Back", on_click=cb_cust_or_emp)
            else:
                st.error("UserId/Password is incorrect!")
                st.button("Go Back", on_click=cb_cust_or_emp)



    elif(st.session_state.check_employee):
        st.markdown(f"""<p style="font-size:30px;text-align:center;"><b>Employee Login</b></p>""", unsafe_allow_html = True)
        userId1 = st.text_input("Employee username")
        password1 = st.text_input("Password", type="password")
        if(userId1 and password1):
            userId = (userId1)
            password = password1

            values = {'userId': userId,'password': password}
            login_cust_stmt = "SELECT * FROM login_emp(:userId, :password)"
            res_rows = db.execute_dql_commands(login_cust_stmt, values)
            for row in res_rows:
                login_auth_cust=row.login_emp
                print(f'login_success : {row.login_emp}')

            if(login_auth_cust==1):
                st.success(f"Logged in as {userId}")
                col1,col2 = st.columns(2)
                st.session_state.e_uname = userId
                st.session_state.e_pwd = password
                col1.button("Login", on_click=cb_employee_home)
                col21,col22,col23 = col2.columns(3)
                col23.button("Go Back", on_click=cb_cust_or_emp)

            else:
                st.error("UserId/Password is incorrect!")
                st.button("Go Back", on_click=cb_cust_or_emp)
  
        


def customer_home():
    # st.write("Hello customer!, home sweet home")

    print(st.session_state)
    userId = st.session_state.c_uname
    password = st.session_state.c_pwd
    db, engine = db_credentials(userId,password)
    values = {'userId': userId,'password': password}

    # print(userId)
    # greeting
    stmnt_c = "select * from cust_details where login_uname = :userId;"
    res_name = db.execute_dql_commands(stmnt_c, values)
    for row in res_name:
        # print(row)
        st.sidebar.write(f"Welcome {row.cust_name}")

        # /////////////////////////////////////////////////////////////////////////////////////////////////////////// #
    stmnt_c = "select *  from view_accounts where login_uname = :userId"
    res_c = db.execute_dql_commands(stmnt_c, values)
    c_accounts = []
    col1,col2 = st.sidebar.columns(2)
    for row in res_c:
        c_accounts.append({'acc_num': row.acc_num, 'login_uname': row.login_uname})
        print(f'acc_num: {row.acc_num}, login_uname: {row.login_uname}')
    with col1:
        st.header("acc num")
        for acc in c_accounts:
            st.write(f"{acc['acc_num']}")
    with col2:
        st.header("username")
        for acc in c_accounts:
            st.write(f"{acc['login_uname']}")
    # with st.sidebar:
    selected = option_menu(None, ["Profile", "Account"], icons = ["person", "coin"],menu_icon="cast", default_index=0, orientation="horizontal")

    if selected == "Account":
        
        listTabs = ["View Balance", "Transaction Log", "Payment Log"]
        tab1, tab2, tab3 = st.tabs([s.center(22, "\u2001") for s in listTabs])

        with tab1:
                st.write("balance")
                bal_acc_num1 = st.text_input("Account number", key = 1)
                bal_acc_pwd = st.text_input("Password", type="password")

                if(bal_acc_num1 and bal_acc_pwd):
                    bal_acc_num = int(bal_acc_num1)
                    values = {"bal_acc_num": bal_acc_num, "userId":userId, "bal_acc_pwd":bal_acc_pwd}
                    balance_stmnt = "select * from view_balance(:bal_acc_num,:userId, :bal_acc_pwd)"
                    res_balance = db.execute_dql_commands(balance_stmnt, values)
                    if res_balance is not None:
                        button_bal = st.button("Check Balance")
                        st.divider()
                        if button_bal:
                            for row in res_balance:
                                st.write(f"available balance: {row.view_balance}")
                    else:
                        st.error("Invalid Credentials!")
        acc_nums = [r["acc_num"] for r in c_accounts]

        with tab2:
                s_acc_num1 = st.text_input("Sender Account Number")
                r_acc_num1 = st.text_input("Receiver Account Number")
                amnt_transfer = st.number_input('Amount')
                s_pwd = st.text_input("Sender password", type="password")

                # st.write(acc_nums)
                if(s_acc_num1 and r_acc_num1 and amnt_transfer and s_pwd):
                    s_acc_num = int(s_acc_num1)
                    r_acc_num = int(r_acc_num1)
                    if st.button("Transfer money"):
                        if s_acc_num in acc_nums:
                            values = {"s_acc_num":s_acc_num, "r_acc_num": r_acc_num, "amnt_transfer":amnt_transfer,"s_uname":userId, "s_pwd":s_pwd }
                            transfer_stmnt = "call transfer_amount(:s_acc_num, :r_acc_num, :amnt_transfer, :s_uname, :s_pwd);"
                            db.execute_ddl_and_dml_commands(transfer_stmnt, values)
                            res_transfer = db.execute_dql_commands("select * from show_transaction_log where s_acc_num = :s_acc_num;", values)
                            if res_transfer:
                                st.success("Transaction successful")
                        else:
                            st.error("Invalid account number!") 
        
        with tab3:
            
            trans_type = []
            trans_amt = []
            trans_date = []
            s_acc_num = []
            r_acc_num = []
            pay_acc_num1 = st.text_input("Account number", key = 3)
            if pay_acc_num1:
                pay_acc_num = int(pay_acc_num1)
                # print(acc_nums)
            
                if  st.button("Show Payment Log"):
                    if pay_acc_num in acc_nums:
                            values = {'acc_num': pay_acc_num}
                            # print(pay_acc_num)
                            res_transfer = db.execute_dql_commands("select * from transactions where s_acc_num = :acc_num or r_acc_num = :acc_num;", values)
                            count=0
                            if res_transfer:

                                for r in res_transfer:
                                    count=count+1
                                    trans_type.append(r.trans_type)
                                    trans_amt.append(r.trans_amt)
                                    trans_date.append(r.trans_date)
                                    s_acc_num.append(r.s_acc_num)
                                    r_acc_num.append(r.r_acc_num)
                                    # st.write(f"transaction type:{row.trans_type}, amount: {row.trans_amt}, transaction date: {row.trans_date}, sender acc num: {row.s_acc_num}, receiver acc num: {row.r_acc_num}")
                                if count==0:
                                    st.write("No Payments yet!")
                                else:
                                    print(trans_type)
                                    print(count)
                                    data = {'trans_type':trans_type, 'trans_amt': trans_amt, 'trans_date': trans_date, 's_acc_num': s_acc_num, 'r_acc_num': r_acc_num}
                                    df = pd.DataFrame(data)
                                    st.table(df)

                    else:
                        st.error("Invalid account number!")

    elif selected == "Profile":
        # view for profile
        print(userId)
        stmnt_profile = "select * from cust_details where login_uname = '" + userId + "';"
        res_profile = db.execute_dql_commands(stmnt_profile)
        st.write(" ")
        # st.write(" ")
        col1,col2 = st.columns(2)

        address1 = ''
        name1 = ''
        for row in res_profile:
            address1 = row.cust_address
            name1 = row.cust_name
            col1.write(" ")
            col2.write(" ")
            col1.markdown('<div style="text-align:center"><img src="https://filestore.community.support.microsoft.com/api/images/8a86b79d-4e94-4c61-ace1-837ffd763978?upload=true&fud_access=wJJIheezUklbAN2ppeDns8cDNpYs3nCYjgitr%2bfFBh2dqlqMuW7np3F6Utp%2fKMltnRRYFtVjOMO5tpbpW9UyRAwvLeec5emAPixgq9ta07Dgnp2aq5eJbnfd%2fU3qhn5498QChOTHl3NpYS7xR7zASsaF20jo4ICSz2XTm%2b3GDR4XitSm7nHRR843ku7uXQ4oF6innoBxMaSe9UfrAdMi7owFKjdP9m1UP2W5KAtfQLMLSmPiAERG6018NyFjkv9RcFHu9O6KllurYDUsXaeUxYQXm%2fHJEL5CEdOQFaT%2bw0DWSi9SgYLd8HcOteeSztROdS4r9d%2fBOkhgldwjGpnuWoamOxEdeBGmbTX2%2ffDoyyaIGkYplY89qY8W6oCXi93iuf8DBgdqg3XirjVI0A58E7GWzmrtiXxThCAMFlqjnZI%3d" /></div>', unsafe_allow_html=True)
            html_str  = f"""
            <style>
            div.a {{
            # text-align: center;
            display:flex;
            font-size: 24px;
            justify-content: center;
            align-items:center;
            # border: 3px solid green; 
            # height:197;
            }}
            </style>
            <div class="a">Name: {row.cust_name} <br>
            Username: {row.login_uname}<br>
            Address: {row.cust_address}<br>
            Date of Birth: {row.cust_dob}<br>
            Phone Number: {row.cust_phnum}<br></div>
            """
            col2.markdown(html_str, unsafe_allow_html=True)
            # col2.write(f"Name: {row.cust_name}")
            # col2.write(f"Username: {row.login_uname}")
            # col2.write(f"Address: {row.cust_address}")
            # col2.write(f"Date of Birth: {row.cust_dob}")
        # st.write(" ")
        st.write(" ")
        st.divider()
        col1,col2 = st.columns(2)
        container1 = col1.container()
        container2 = col2.container()
        container3 = col1.container()

        with container1:
            st.subheader("Update Address")
            new_add = st.text_input("New Address")
            if(new_add):
                button_add = st.button("Update Address")
                if(button_add):
                    values = {'userId':userId, 'address':new_add}
                    # print(userId,address1)
                    res_update_add = db.execute_ddl_and_dml_commands("call update_customer(:userId,:address);", values)

                    if(res_update_add == 1):
                        st.success("Updated address successfully!")
                        time.sleep(5/10)
                        st.experimental_rerun()
                    else:
                        st.error("Updation of address went wrong!")
        with container2:
            st.subheader("Update Phone number")
            new_phnum = st.text_input("New phone number")
            if(new_phnum):
                button_add = st.button("Update phone number")
                if(button_add):
                    values = {'userId':userId, 'phonenum':new_phnum}
                    # print(userId,address1)
                    res_update_phnum = db.execute_ddl_and_dml_commands("call update_customer(:userId,NULL,:phonenum);", values)
                    if(res_update_phnum == 1):
                        st.success("Updated phone number successfully!")
                        time.sleep(5/10)
                        st.experimental_rerun()
                    else:
                        st.error("Updation of phone number went wrong!")
        with container3:
            st.subheader("Update password")
            present_pwd = st.text_input("Current password", type="password")
            new_pwd = st.text_input("New password", type="password")
            if(present_pwd and new_pwd):
                if(present_pwd == password):
                    # print(userId, present_pwd, new_pwd)
                    values = {'userId': userId, 'present_pwd': present_pwd, 'new_pwd':new_pwd}
                    stmnt_update_pwd = "call update_pwd(:userId, :present_pwd, :new_pwd);"
                    res_update_pwd = db.execute_ddl_and_dml_commands(stmnt_update_pwd,values)
                    # for row in res_update_pwd:
                    if(res_update_pwd == 1):
                        st.session_state.c_pwd = new_pwd
                        st.success("Password updated successfully!")
                    else:
                        st.error("Password updation went wrong!")
                else:
                    st.error("Current password incorrect!")



    st.sidebar.button("Logout", on_click=cb_cust_or_emp)

def employee_home():
    db, engine = db_credentials('surya','surya')

    st.sidebar.button("Logout", on_click=cb_cust_or_emp)

    userId = st.session_state.e_uname
    password = st.session_state.e_pwd
    html_string = f"""
    <p style="text-align:center; font-size: 30px;">Welcome {userId}</p>
    """
    st.markdown(html_string, unsafe_allow_html = True)
    listTabs = ["Create Account for customers", "Transaction Log", "Withdraw Amount", "Deposit Amount","Create Loan Account"]
    tab1, tab2, tab3, tab4, tab5 = st.tabs([s.center(18, "\u2001") for s in listTabs])

    with tab5:
        st.write("")
        st.subheader("Create Loan Account")
        col1,col2 = st.columns(2)
        name = col1.text_input("Name",key = "name")
        address = col2.text_input("Address",key = "add")
        dob = col2.date_input("Date of Birth",key = "dob")
        phone_num = col1.text_input("Phone Number",key = "ph")
        ln_type = col1.text_input("loan Type",key = "lnty")
        e_id = col2.text_input("Employer id",key = "e")
        b_id = col2.text_input("Branch Id",key = "b")
        username = col1.text_input("Username",key = "u")
        new_cust1 = col1.text_input("new customer?",key = "n")
        ln_amnt1 = col2.text_input("Loan amount")
        ln_intrst = col1.number_input("Loan interest")
        ln_valid = col2.date_input("Validity Date")

        # loan amount = 
        # col1,col2 = st.columns(2)
        password = col1.text_input("Password", type="password", key="p")
        again_password = col2.text_input("Verify Password", type="password",key="p1")

        
        if e_id!="" and b_id!="" and new_cust1!="":
            # customer_id=int(customer_id)
            new_cust=int(new_cust1)
            ln_amnt = int(ln_amnt1)
            e_id = int(e_id)
            b_id = int(b_id)
            if st.button("Register1"):
                if password != again_password:
                    st.error("Password does not match!")

                # connection between frontend and database should be there below
                # db, engine = db_credentials('surya','surya')
                else:
                    values = {'name': name, 'address':address, 'dob':dob, 'phone_num': phone_num, 'ln_type':ln_type, 'e_id':e_id, 'b_id':b_id, 'username':username, 'password':password, 'ln_amnt':ln_amnt,'ln_intrst':ln_intrst, 'ln_valid':ln_valid,'new_cust':new_cust}
                    create_account_stmt = "CALL create_loan_account(:name,  :address, :dob, :phone_num, 'loan', :e_id, :b_id,:ln_amnt,:ln_type ,:ln_intrst,:ln_valid,:username, :password, :new_cust)"
                    res_emp=db.execute_ddl_and_dml_commands(create_account_stmt, values)
                    print(f"----------------{res_emp}")


                    if len(phone_num) != 10 and len(phone_num)!=0:
                        st.error("Please give a valid phone number")
                    st.divider()
                    st.write(f"Account for {name} has been created")
    
    with tab1:
        st.write("")
        st.subheader("Create Account")
        col1,col2 = st.columns(2)
        name = col1.text_input("Name")
        address = col2.text_input("Address")
        dob = col2.date_input("Date of Birth")
        phone_num = col1.text_input("Phone Number")
        account_type = col1.text_input("Account Type")
        e_id = col2.text_input("Employer id")
        b_id = col2.text_input("Branch Id")
        username = col1.text_input("Username")
        new_cust1 = col1.text_input("new customer?")
        # col1,col2 = st.columns(2)
        password = col1.text_input("Password", type="password")
        again_password = col2.text_input("Verify Password", type="password")

        
        if e_id!="" and b_id!="" and new_cust1!="":
            # customer_id=int(customer_id)
            new_cust = int(new_cust1)
            e_id = int(e_id)
            b_id = int(b_id)
            if st.button("Register"):
                if password != again_password:
                    st.error("Password does not match!")

                # connection between frontend and database should be there below
                # db, engine = db_credentials('surya','surya')
                else:
                    values = {'name': name, 'address':address, 'dob':dob, 'phone_num': phone_num, 'account_type':account_type, 'e_id':e_id, 'b_id':b_id, 'username':username, 'password':password, 'new_cust':new_cust}
                    create_account_stmt = "call create_account2(:name,  :address, :dob, :phone_num, :account_type, :e_id, :b_id, :username, :password, :new_cust);"
                    # create_account_stmt = "select * from create_account('name',  'address', '2000-01-01', '1238907651', 'savings', 1, 1, 'qqqqqqqqqqqqqqq', '2', 1)"
                    res_create_acc = db.execute_ddl_and_dml_commands(create_account_stmt, values)
                    print(values)
                    # for row in res_create_acc:
                    #     print(row.create_account)
                    #     if(row.create_account > 0):
                    #         st.success(f"Successfully created a new account for {name}")
                    #     else:
                    #         st.error("Please check credentials and phone number!")
                    if res_create_acc:
                        st.success(f"Account for {name} has been created")
                    else:
                        st.error("Something went wrong!")
                    st.divider()
    with tab2:
        # st.write("")
        acc_specific = st.radio("",('All accounts', 'Account specific'))
        filtered = st.checkbox("Filter transactions according to date")
        if filtered:
            col1,col2 = st.columns(2)
            d1 = col1.date_input("From", help="Filters from 12:00 am of the date you have chosen")
            # col2.write(" ")
            # col2.write(" ")
            # col2.write(" ")
            # col2.markdown('<p style="text-align:center;font-size:24px;"<img> </img>' , unsafe_allow_html=True)
            # col2.write("to")
            d2 = col2.date_input("To", help="Filters till 12:00 am of the date you have chosen")
            print(d1,d2)
        st.divider()

        trans_type = []
        trans_amt = []
        trans_date = []
        s_acc_num = []
        r_acc_num = []
        if acc_specific == 'Account specific':
            pay_acc_num1 = st.text_input("Account number", key = 3)
            if pay_acc_num1:
                pay_acc_num = int(pay_acc_num1)
                # print(acc_nums)
                # if pay_acc_num in acc_nums:
                # print(pay_acc_num)
                if filtered:
                    values = {'acc_num': pay_acc_num, 'd1':d1, 'd2':d2}
                    res_transfer = db.execute_dql_commands("select * from show_transaction_log where (s_acc_num = :acc_num or r_acc_num = :acc_num) and trans_date between :d1 and :d2;", values)
                else:
                    values = {'acc_num': pay_acc_num}
                    res_transfer = db.execute_dql_commands("select * from show_transaction_log where (s_acc_num = :acc_num or r_acc_num = :acc_num);", values)
                count=0
                if res_transfer:

                    for r in res_transfer:
                        count=count+1
                        trans_type.append(r.trans_type)
                        trans_amt.append(r.trans_amt)
                        trans_date.append(r.trans_date)
                        s_acc_num.append(r.s_acc_num)
                        r_acc_num.append(r.r_acc_num)
                        # st.write(f"transaction type:{row.trans_type}, amount: {row.trans_amt}, transaction date: {row.trans_date}, sender acc num: {row.s_acc_num}, receiver acc num: {row.r_acc_num}")
                    if count==0:
                        st.write("No Payments yet or Invalid Account!")
                    else:
                        print(trans_type)
                        print(count)
                        data = {'trans_type':trans_type, 'trans_amt': trans_amt, 'trans_date': trans_date, 's_acc_num': s_acc_num, 'r_acc_num': r_acc_num}
                        df = pd.DataFrame(data)
                        st.table(df)

            # else:
            #     st.error("Invalid account number!")
        else:
            # st.write("All accounts!")
            if filtered:
                values = {'d1':d1, 'd2':d2}
                res_transfer = db.execute_dql_commands("select * from show_transaction_log where trans_date between :d1 and :d2;", values)
            else:
                res_transfer = db.execute_dql_commands("select * from show_transaction_log;")
            if(res_transfer):
                count=0
                if res_transfer:
                    for r in res_transfer:
                        count=count+1
                        trans_type.append(r.trans_type)
                        trans_amt.append(r.trans_amt)
                        trans_date.append(r.trans_date)
                        s_acc_num.append(r.s_acc_num)
                        r_acc_num.append(r.r_acc_num)
                        # print(r.r_acc_num)
                        # st.write(f"transaction type:{row.trans_type}, amount: {row.trans_amt}, transaction date: {row.trans_date}, sender acc num: {row.s_acc_num}, receiver acc num: {row.r_acc_num}")
                    if count==0:
                        st.write("No Payments yet or Invalid Account!")
                    else:
                        # print(trans_type)
                        # print(count)
                        # print(r_acc_num)
                        data = {'trans_type':trans_type, 'trans_amt': trans_amt, 'trans_date': trans_date, 's_acc_num': s_acc_num, 'r_acc_num': r_acc_num}
                        df = pd.DataFrame(data)
                        st.table(df)
    with tab3:
        e_id = 0
        res_eid = db.execute_dql_commands("select emp_id from employee where emp_uname = '"+userId+"';")
        for r in res_eid:
            e_id = r.emp_id
        print(e_id)
        st.write("")
        col1,col2 = st.columns(2)
        s_acc_num1 = col1.text_input("Account Number")
        s_uname = col1.text_input("User Name")
        amnt_transfer = col2.number_input('Amount')

        if(s_acc_num1  and amnt_transfer):
            s_acc_num = int(s_acc_num1)
            values = {'s_acc_num': s_acc_num} 
            if st.button("Withdraw"):
                values = {"s_acc_num":s_acc_num, "s_uname":s_uname ,"amnt_transfer":amnt_transfer,"userId":e_id}
                transfer_stmnt = "call withdraw_amount(:s_acc_num, :amnt_transfer, :s_uname, :userId);"
                res_withdraw_check = db.execute_ddl_and_dml_commands(transfer_stmnt, values)
                if(res_withdraw_check==1):
                    st.success("Withdrawal successfull!")
                else:
                    st.error("Something went wrong!")
    with tab4:
        e_id = 0
        res_eid = db.execute_dql_commands("select emp_id from emp_details where emp_uname = '"+userId+"';")
        for r in res_eid:
            e_id = r.emp_id
        print(e_id)
        st.write("")
        col1,col2 = st.columns(2)
        s_acc_num1 = col1.text_input("Account Number",key=41)
        s_uname = col1.text_input("User Name",key=43)
        amnt_transfer = col2.number_input('Amount',key=42)

        if(s_acc_num1  and amnt_transfer):
            s_acc_num = int(s_acc_num1)
            values = {'s_acc_num': s_acc_num}
 
            if st.button("Deposit"):
                values = {"s_acc_num":s_acc_num, "s_uname":s_uname ,"amnt_transfer":amnt_transfer,"userId":e_id}
                transfer_stmnt = "call deposit_amount(:s_acc_num, :amnt_transfer, :s_uname, :userId);"
                res_withdraw_check = db.execute_ddl_and_dml_commands(transfer_stmnt, values)
                if(res_withdraw_check==1):
                    st.success("Deposit successfull!")
                else:
                    st.error("Something went wrong!")


def cust_or_emp():
    st.subheader("")
    st.markdown(f"""<div style="text-align:center;font-size:30px;"><b>Are you a customer or an employee?</b></div>""", unsafe_allow_html = True)
    st.write(" ")
    st.write(" ")
    c1, c2 = st.columns(2)
    c11,c12,c13 = c1.columns(3)
    c21,c22,c23 = c2.columns(3)
    with c12:
        st.button("Customer", on_click=cb_customer_login)
    with c22:
        st.button("Employee", on_click=cb_employee_login)

if st.session_state.active_page == 'customer_home':
    customer_home()

elif st.session_state.active_page == 'employee_home':
    employee_home()

elif st.session_state.active_page == 'authentication':
    authentication()

elif st.session_state.active_page == 'cust_or_emp':
    cust_or_emp()


