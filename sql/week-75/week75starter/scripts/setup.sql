create application role if not exists app_role;
create or alter versioned schema app_schema;
grant usage on schema app_schema to application role app_role;
create or replace streamlit app_schema.streamlit from '/streamlit' main_file='streamlit.py';

-- create the update reference callback here

grant usage on streamlit app_schema.streamlit to application role app_role;
grant usage on procedure app_schema.update_reference(string, string, string) to application role app_role;
