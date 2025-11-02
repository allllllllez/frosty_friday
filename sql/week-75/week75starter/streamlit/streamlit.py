import streamlit as st
from snowflake.snowpark.context import get_active_session
import snowflake.permissions as permission
from sys import exit

st.set_page_config(layout="wide")
session = get_active_session()

if hasattr(st.session_state, "permission_granted"):
    pass
else:
    # If not, trigger the table referencing process

    # And add a variable in the session to mark that this is done


if not # check for database permission:
    # otherwise, request it

st.title("FrostyPermissions!")

check = st.button('Shall we check we have what we need?')
if check:
    if  and : # check for permissions again
        st.success('Yup! Looks like we\'ve got all the permissions we need')