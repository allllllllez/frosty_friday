/*
This week we’ll be looking at a feature that has just hit Preview Feature – Open : Sending Email Notifications.

We’re asking you to use this feature in conjunction with linked tasks to create a very small chain while tackling 2 different subjects.

# The Challenge
The assignment for this week is two-fold :

- Create a scheduled task (task #1) that inserts the current timestamp into a table every 5 minutes
- Create a linked task (task #2) that sends an email that confirms the running of task #1 that contains the following information:
  Task has successfully finished on <Account> which is deployed on <region> region at <timestamp>

---

今週は、プレビュー機能として公開されたばかりの機能「オープン：電子メール通知の送信」について見ていきます。
※この問題は 2022-12-09 に公開されました。
　Sending Email Notifications 機能は 2022/11 プレビュー開始、2023/08 にGAとなっています

この機能をリンクされたタスクと組み合わせて、2つの異なるテーマに取り組みながら、非常に小さな連鎖を作り出してください。

# チャレンジ
今週の課題は2つ：

- 5分ごとに、現在のタイムスタンプをテーブルに挿入するスケジュールタスク(タスク#1)を作成する。
- タスク#1の実行を確認するメールを送信するリンクタスク(タスク#2)を作成する。メールは以下の情報を含む：
  タスクは、<region>リージョンに配置された<Account>で、<timestamp>に正常に終了しました。

*/

------------------------------------------------------------
-- 
-- 準備
-- 
------------------------------------------------------------ 

use role SYSADMIN;
create or replace database M_KAJIYA_FROSTY_FRIDAY;
use schema M_KAJIYA_FROSTY_FRIDAY.PUBLIC;

-- タイムスタンプを記録するテーブル
create table M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_TIMESTAMP (
    ts TIMESTAMP_LTZ
)
comment = 'タイムスタンプを記録するテーブル'
;


------------------------------------------------------------
-- 
-- 課題1. 
-- 5分ごとに、現在のタイムスタンプをテーブルに挿入するスケジュールタスク(タスク#1)を作成する
-- 
------------------------------------------------------------ 

create task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK
  schedule = '5 minute'
  user_task_managed_initial_warehouse_size = 'XSMALL' -- サーバレスタスクの初期サイズ。サーバレスタスクは数回実行ののちに自動的に理想的なサイズを設定するが、この内容なら最初っから最小でいいでしょう。指定しない場合のサイズは MEDIUM
  AS
    INSERT INTO M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_TIMESTAMP(ts) VALUES(CURRENT_TIMESTAMP);

-- 開始（忘れがち）
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK resume;

-- 待ってもいいけど、Owner なので手動実行しちゃう
-- （以前は ACCOUNTADMIN 持ってないと EXECUTE TASK できなかったような？？）
execute task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK;

call system$wait(30);

-- 実行履歴を見てみましょ
select
    query_id
    , database_name || '.' || schema_name || '.' || name as name
    , state
    , scheduled_time
    , query_start_time
    , completed_time
    , scheduled_from
from 
    table(
        information_schema.task_history(
            scheduled_time_range_start => dateadd('hour',-1,current_timestamp()),
            result_limit => 10,
            task_name => 'CHALLENGE_26_1_TASK'
        )
    )
order by
    query_start_time desc -- scheduled が入っちゃうから
limit
    1
;

-- テーブルにinsertされているかを確認しましょ
table M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_TIMESTAMP;


------------------------------------------------------------
-- 
-- 課題2. 
-- タスク#1の実行を確認するメールを送信するリンクタスク(タスク#2)を作成する。メールは以下の情報を含む：
--   タスクは、<region>リージョンに配置された<Account>で、<timestamp>に正常に終了しました。
-- 
------------------------------------------------------------ 

-- 通知を飛ばすために notification integration を作成
create or replace notification integration m_kajiya_frosty_friday_mail_notif_integration
  type = email
  enabled = true
  allowed_recipients = (
    'test@example.com'
);

-- 課題1タスクの最新終了時刻を取るUDF
create or replace function M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_GET_TASK_COMPLETED_TIME(task_name varchar)
    returns varchar not null
    language sql
as
$$
    select max(completed_time)::string
        from table(information_schema.task_history(
            scheduled_time_range_start=>dateadd('hour', -1, current_timestamp()),
            result_limit => 10,
            task_name => task_name
        )
    )
$$
;

select CHALLENGE_26_GET_TASK_COMPLETED_TIME('CHALLENGE_26_1_TASK');



-- 
-- パターン1
-- （普通に）子タスクを付けよう
-- 

-- 子タスクを設定する際、親タスクを止める必要があります（n敗）
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK suspend;

create or replace task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_1_TASK
    after M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK
as
    call system$send_email(
        'm_kajiya_frosty_friday_mail_notif_integration',
        'test@example.com',
        'frosty_friday #26 challenge',
        concat(
            'Task has successfully finished on ',
            current_account(),
            ' which is deployed on ',
            current_region(),
            ' region at ',
            CHALLENGE_26_GET_TASK_COMPLETED_TIME('CHALLENGE_26_1_TASK')
        )
    )
;

-- 開始
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_1_TASK resume;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK resume;

-- 待ってもいいけど、Owner なので手動実行しちゃう
execute task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK;
call system$wait(30);

-- 実行履歴を見てみましょ
select
    query_id
    , database_name || '.' || schema_name || '.' || name as name
    , state
    , scheduled_time
    , query_start_time
    , completed_time
    , scheduled_from
from 
    table(
        information_schema.task_history(
            scheduled_time_range_start => dateadd('hour', -1, current_timestamp()),
            result_limit => 10,
            task_name => 'CHALLENGE_26_2_1_TASK'
        )
    )
;

-- メールボックスを確認しましょう

-- Snowsight でタスクグラフも見ておくといいかも

-- 
-- パターン2
-- ファイナライザータスクを使ってみよう
-- ファイナライザータスクは、タスクグラフが実行された場合に必ず実行されるタスク。
-- 実行が保証されているので、タスクグラフが途中で失敗した場合に問題が発生しないようにクリーンアップを行うとか、タスクグラフ終了時に通知を飛ばす...などの用途で使います。
-- https://docs.snowflake.com/ja/user-guide/tasks-intro#finalizer-task

-- 子タスクを設定するので、親タスクを止める必要があります
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK suspend;

create or replace task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_2_TASK
    finalize = M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK
as
    call system$send_email(
        'm_kajiya_frosty_friday_mail_notif_integration',
        'test@example.com',
        'frosty_friday #26 challenge',
        concat(
            'Task has successfully finished on ',
            current_account(),
            ' which is deployed on ',
            current_region(),
            ' region at ',
            CHALLENGE_26_GET_TASK_COMPLETED_TIME('CHALLENGE_26_1_TASK')
        )
    )
;

-- 開始
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_2_TASK resume;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK resume;

execute task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK;
call system$wait(30);

-- 実行履歴を見てみましょ
select
    query_id
    , database_name || '.' || schema_name || '.' || name as name
    , state
    , scheduled_time
    , query_start_time
    , completed_time
    , scheduled_from
from 
    table(
        information_schema.task_history(
            scheduled_time_range_start=>dateadd('hour', -1, current_timestamp()),
            result_limit => 10,
            task_name => 'CHALLENGE_26_2_2_TASK'
        )
    )
;


-- メールボックスを確認しましょう

-- Snowsight でタスクグラフも見ておきましょう。ファイナライザータスクはどのように表示されているかな？




-- 
-- パターン3
-- SYSTEM$SEND_SNOWFLAKE_NOTIFICATION を使ってみよう
-- 構文が数パターンあります。今回はシンプルに メッセ―ジ＋通知統合

-- 子タスクを設定するので、親タスクを止める必要があります
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK suspend;

create or replace task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_3_TASK
    after M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK
as
    call system$send_snowflake_notification(
        snowflake.notification.text_plain(
            concat(
                'Task has successfully finished on ',
                current_account(),
                ' which is deployed on ',
                current_region(),
                ' region at ',
                CHALLENGE_26_GET_TASK_COMPLETED_TIME('CHALLENGE_26_1_TASK')
            )
        ),
        snowflake.notification.email_integration_config(
            'm_kajiya_frosty_friday_mail_notif_integration',
            'frosty_friday #26 challenge',
            array_construct('test@example.com')
        )
    )
;

-- 開始
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_3_TASK resume;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK resume;

execute task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK;
call system$wait(30);

-- 実行履歴を見てみましょ
select
    query_id
    , database_name || '.' || schema_name || '.' || name as name
    , state
    , scheduled_time
    , query_start_time
    , completed_time
    , scheduled_from
from 
    table(
        information_schema.task_history(
            scheduled_time_range_start=>dateadd('hour', -1, current_timestamp()),
            result_limit => 10,
            task_name => 'CHALLENGE_26_2_3_TASK'
        )
    )
;





-- 
-- パターン4(おまけ)
-- SYSTEM$SEND_SNOWFLAKE_NOTIFICATION を使って Slack に投げよう
-- 問題が「メールで通知して」だから題意に沿わない気もするけど！まいっか！！
-- 

-- Slack notification integration を作成
-- まず Slack Webhook URL の services/ 以降をシークレットに登録
create or replace secret M_KAJIYA_FROSTY_FRIDAY.PUBLIC.m_kajiya_frosty_friday_slack_secret
    type = generic_string
    secret_string = 'TXXXXXXX/BXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXX';

-- SNOWFLAKE_WEBHOOK_MESSAGE プレースホルダーを入れて、メッセージを置き換えられるようにしておく
create or replace notification integration m_kajiya_frosty_friday_slack_notif_integration
    type=webhook
    enabled=true
    webhook_url='https://hooks.slack.com/services/SNOWFLAKE_WEBHOOK_SECRET'
    webhook_secret=M_KAJIYA_FROSTY_FRIDAY.PUBLIC.m_kajiya_frosty_friday_slack_secret
    webhook_body_template= '{
        "channel": "snowflake-notification",
        "attachments":[
            {
                "fallback":"info",
                "pretext":"frosty_friday live challenge",
                "color":"good",
                "fields":[{
                    "title":"frosty_friday #26",
                    "value":"SNOWFLAKE_WEBHOOK_MESSAGE"
                }]
            }
        ]
    }'
    webhook_headers=('content-type' = 'application/json');


-- 子タスクを設定するので、親タスクを止める必要があります
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK suspend;

create or replace task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_4_TASK
    after M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK
as
    call system$send_snowflake_notification(
        snowflake.notification.text_plain(
            concat(
                'Task has successfully finished on ',
                current_account(),
                ' which is deployed on ',
                current_region(),
                ' region at ',
                CHALLENGE_26_GET_TASK_COMPLETED_TIME('CHALLENGE_26_1_TASK')
            )
        ),
        snowflake.notification.integration(
            'm_kajiya_frosty_friday_slack_notif_integration'
        )
    )
;

-- 開始
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_4_TASK resume;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK resume;

execute task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_1_TASK;
call system$wait(30);

-- 実行履歴を見てみましょ
select
    query_id
    , database_name || '.' || schema_name || '.' || name as name
    , state
    , scheduled_time
    , query_start_time
    , completed_time
    , scheduled_from
from 
    table(
        information_schema.task_history(
            scheduled_time_range_start=>dateadd('hour', -1, current_timestamp()),
            result_limit => 10,
            task_name => 'CHALLENGE_26_2_4_TASK'
        )
    )
;

------------------------------------------------------------
-- 
-- あとしまつ
-- 
------------------------------------------------------------ 

use role SYSADMIN;

-- インターバルの短いタスクを無意味に放置するのは止めようね！
alter task CHALLENGE_26_1_TASK suspend;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_1_TASK suspend;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_2_TASK suspend;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_3_TASK suspend;
alter task M_KAJIYA_FROSTY_FRIDAY.PUBLIC.CHALLENGE_26_2_4_TASK suspend;

drop  notification integration m_kajiya_frosty_friday_mail_notif_integration;
drop  notification integration m_kajiya_frosty_friday_slack_notif_integration;

------------------------------------------------------------
-- 
-- 参考
-- 
------------------------------------------------------------ 

-- https://docs.snowflake.com/en/release-notes/2022-11#new-system-stored-procedure-for-sending-email-notifications-preview
-- https://docs.snowflake.com/en/release-notes/2023/7_27

-- https://docs.snowflake.com/en/sql-reference/stored-procedures/system_send_email
-- https://docs.snowflake.com/en/user-guide/notifications/snowflake-notifications

-- https://zenn.dev/dataheroes/articles/slack-notification
-- https://zenn.dev/churadata/articles/3754ad36ccf023
-- https://dev.classmethod.jp/articles/systemsend-email-and-systemsend-snowflake-notification-snowflakedb/
