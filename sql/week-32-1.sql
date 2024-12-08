/*

https://frostyfriday.org/blog/2023/02/03/week-32-basic/

---

This week we’re looking into some new security features that Snowflake has recently released

As you might know, the default idle time for Snowflake sessions is 4 hours BUT that was recently adjusted; you can now change this value on certain levels.
Because we can finetune these numbers, Management has asked us to enforce it for some of our new colleagues :

The challenge for this week :
– Create 2 users
– User 1 should have a max idle time of 8 minutes in the old Snowflake UI
– User 2 should have a max idle time of 10 minutes in SnowSQL and in their communication with Snowflake from tools like Tableau

One of the things we’d be looking for looks like this :

> Select CURRENT_TIMESTAMP();
390111: 390111: Session no longer exists. New login required to access the service.
Password:

---

今週は、Snowflakeが最近リリースした新しいセキュリティ機能について見ていきます。
ご存知かもしれませんが、Snowflakeセッションのデフォルトのアイドル時間は4時間です。
私たちはこの数値を微調整することができるので、経営陣は私たちに新しい同僚の何人かにこの数値を強制するように依頼してきました：

今週の課題

- ユーザーを2人作る
- ユーザー1は旧Snowflake UIで最大アイドル時間を8分とする。
- ユーザー2は、SnowSQLとTableauのようなツールからのSnowflakeとのコミュニケーションで、最大アイドル時間を10分とする。

こういうことです：

> Select CURRENT_TIMESTAMP();
390111: 390111: Session no longer exists. New login required to access the service.
Password:

*/

------------------------------------------------------------
-- 
-- 準備
-- 
------------------------------------------------------------ 

use role SYSADMIN;
create database if not exists M_KAJIYA_FROSTY_FRIDAY;
use schema M_KAJIYA_FROSTY_FRIDAY.PUBLIC;

use role SECURITYADMIN;


-- ユーザー1は旧 Snowflake UI で最大アイドル時間を8分とする。
create user challenge_32_user_1
    password = '<password_1>'
    TYPE = 'LEGACY_SERVICE' -- 人間にあたるユーザーは PERSON で作るのが正しいけど、今回はアカウントに MFA 必須ポリシーを設定しており、MFA 設定が面倒なのでスキップ...よくない使い方である
;

-- ユーザー2は、SnowSQLとTableauのようなツールからのSnowflakeとのコミュニケーションで、最大アイドル時間を10分とする。
create user challenge_32_user_2
    password = '<password_2>'
    TYPE = 'LEGACY_SERVICE'
;

------------------------------------------------------------
-- 
-- 課題
-- 
------------------------------------------------------------ 

use role ACCOUNTADMIN;

-- セッションポリシーを作ろう
-- 「ユーザー1は旧 Snowflake UI で最大アイドル時間を8分とする」のポリシー
create or replace session policy challenge_32_ui_idle_timeout_8min
    session_ui_idle_timeout_mins = 8
    comment = 'max idle time of 8 minutes in the old Snowflake UI'
;

alter user challenge_32_user_1 set session policy challenge_32_ui_idle_timeout_8min;

-- Snowsight も巻き込まれちゃう気がするけど。。。

-- 「ユーザー2は、SnowSQLとTableauのようなツールからのSnowflakeとのコミュニケーションで、最大アイドル時間を10分とする」のポリシー
create or replace session policy challenge_32_client_idle_timeout_10min
    session_idle_timeout_mins = 10
    comment = 'max idle time of 10 minutes in the client'
;
alter user challenge_32_user_2 set session policy challenge_32_client_idle_timeout_10min;

-- 余談：セッションポリシーは create user でユーザーセットできない。作成時に付けられるポリシーはネットワークポリシーだけ（2024年12月5日時点）
-- https://docs.snowflake.com/en/sql-reference/sql/create-user


-- 
-- 動作確認
-- ユーザー1、ユーザー2 でクエリを実行しよう
-- 
-- ユーザー1 → ブラウザへ
-- ユーザー2 → SnowCLIで
-- 

------------------------------------------------------------
-- 
-- あとしまつ
-- 
------------------------------------------------------------ 

use role ACCOUNTADMIN;
use schema M_KAJIYA_FROSTY_FRIDAY.PUBLIC;

drop user challenge_32_user_1;
drop user challenge_32_user_2;
show users like 'challenge_32_%';

drop session policy challenge_32_ui_idle_timeout_8min;
drop session policy challenge_32_client_idle_timeout_10min;
show session policies like 'challenge_32_%';

-- 
-- ところで、手動で後始末するのちょっと面倒ですよね？？
-- ということで、別解をご用意いたしました
-- ここで突然の Terraform 編に突入したいと思います
-- 

------------------------------------------------------------
-- 
-- 参考
-- 
------------------------------------------------------------ 

-- Session policy は 2021/11にパブリックプレビュー開始、2022/12 にGA。
-- SaaSサービス導入時のセキュリティ要件で、セッションタイムアウトまでの時間が要求されることはそう珍しくなく、ここが制御できないことを気にしていた人たちは歓喜したはず。
-- https://docs.snowflake.com/en/release-notes/2022-12#session-policies-generally-available

-- https://docs.snowflake.com/en/user-guide/session-policies
-- https://docs.snowflake.com/en/sql-reference/sql/create-session-policy
