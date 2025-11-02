create application role if not exists app_role;
create or alter versioned schema app_schema;
grant usage on schema app_schema to application role app_role;
create or replace streamlit app_schema.streamlit from '/streamlit' main_file='streamlit.py';

create or replace procedure app_schema.update_reference(ref_name string, operation string, ref_or_alias string)
  returns string
  language sql
  as $$
    begin
      case (operation)
        when 'ADD' then
          select system$set_reference(:ref_name, :ref_or_alias);
        when 'REMOVE' then
          select system$remove_reference(:ref_name);
        when 'CLEAR' then
          select system$remove_reference(:ref_name);
        else
          return '❌ 不明な操作: ' || operation;
      end case;
      return 'Success';
    end;
  $$;

grant usage on streamlit app_schema.streamlit to application role app_role;
grant usage on procedure app_schema.update_reference(string, string, string) to application role app_role;
