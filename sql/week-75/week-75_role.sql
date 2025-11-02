use role SECURITYADMIN;
create role M_KAJIYA_FROSTY_FRIDAY_WEEK75_ROLE;
grant role M_KAJIYA_FROSTY_FRIDAY_WEEK75_ROLE to role ACCOUNTADMIN;
grant role SYSADMIN to role M_KAJIYA_FROSTY_FRIDAY_WEEK75_ROLE;

use role accountadmin;
grant create application on account to role M_KAJIYA_FROSTY_FRIDAY_WEEK75_ROLE;
grant create application package on account to role M_KAJIYA_FROSTY_FRIDAY_WEEK75_ROLE;


----------------------------------------------------------------------------------------
-- おかたづけ
---------------------------------------------------------------------------------------
use role SECURITYADMIN;
drop role M_KAJIYA_FROSTY_FRIDAY_WEEK75_ROLE;
