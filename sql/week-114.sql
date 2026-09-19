/*
Professor Frosty - as a scholar and a gentleman - is always very keen to advance learning and there's no better way than to use some artificial intelligence provided by Snowflake!
In this S3 bucket we have a series of open access journals from the Oxford University Press.
Your job is to create a CORTEX Search service that will help our dear users identify the topics of these journals.
A test question could be "Which of these is about economics?" and return:

- The file name
- The title of the document (hint: EXTRACT_ANSWER() might help here)
- A pre-signed URL for the document

In a notebook, it will look something like:

<img src="https://images.squarespace-cdn.com/content/v1/66c70bf53ae7c92c9869acf5/b02e4803-f94b-439f-8b61-e4b597fc2fc7/Screenshot-2024-10-11-at-16.21.54.webp?format=2500w" alt="" width=600 />

---

フロスティ教授は、学者であり紳士でもあるため、常に学問の進歩に熱心に取り組んでおり、スノーフレークが提供する人工知能を活用することほど、その目的に適した方法はありません！
このS3バケットには、オックスフォード大学出版局（Oxford University Press）のオープンアクセスジャーナルが多数収録されています。
あなたの仕事は、愛すべきユーザーたちがこれらのジャーナルのトピックを特定できるよう支援する、CORTEX Search サービスを作成することです。
テスト問題の例として、「これらの中で経済学に関するものはどれか？」という質問に対し、以下を返すようにしてください：

- ファイル名
- ドキュメントのタイトル（ヒント：EXTRACT_ANSWER() が役立つかもしれません）
- ドキュメントへの事前署名済み URL

ノートブック上では、次のような感じになります：

<img src="https://images.squarespace-cdn.com/content/v1/66c70bf53ae7c92c9869acf5/b02e4803-f94b-439f-8b61-e4b597fc2fc7/Screenshot-2024-10-11-at-16.21.54.webp?format=2500w" alt="" width=600 />

*/

------------------------------------------------------------
-- 
-- 準備
-- Frosty_friday 用に環境を作るよ
-- 
------------------------------------------------------------
 
use role SYSADMIN;
use database M_KAJIYA_FROSTY_FRIDAY;
create or replace schema SERVICES;

------------------------------------------------------------
--
-- 解法1. SQLで作っていこう
--
------------------------------------------------------------

-- ドキュメント格納用ステージを作成（GET_PRESIGNED_URLを使うのでディレクトリテーブルを有効化）
create or replace stage  M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage
    directory = (enable = true)
    encryption = (type = 'SNOWFLAKE_SSE');

-- ローカルのダミー論文（sql/week-114/documents_ja/*.pdf）をステージへアップロード
--    SnowCLI使用
/*
snow stage copy "sql/week-114/documents_ja/*.pdf" @M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage \
    --overwrite \
    --connection sandbox
*/
alter stage M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage refresh;

ls @M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage;

-- 論文を格納するテーブルを作成
-- PDFなのでAI_PARSE_DOCUMENTで本文テキストを抽出する
create or replace table M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents as
select
    relative_path as file_name,
    AI_PARSE_DOCUMENT(
        TO_FILE('@M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage', relative_path),
        {'mode': 'OCR'}
    ):content::varchar as content
from directory(@M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_stage);

-- 事前署名済みURLを付与
create or replace table documents_with_url as
select
    file_name,
    content,
    get_presigned_url(@documents_stage, file_name) as presigned_url
from documents;

table M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_with_url;

-- Cortex Search Serviceを作成
create or replace cortex search service M_KAJIYA_FROSTY_FRIDAY.SERVICES.journal_search_service
    on content
    attributes file_name, presigned_url
    warehouse = M_KAJIYA_FROSTY_FRIDAY_WH
    target_lag = '1 day'
    embedding_model = 'voyage-multilingual-2'
    as (
        select
            content,
            file_name,
            presigned_url
        from documents_with_url
    );

-- データを後から更新したときだけ実行
-- ALTER CORTEX SEARCH SERVICE M_KAJIYA_FROSTY_FRIDAY.SERVICES.journal_search_service REFRESH;

-- テスト質問: "Which of these is about economics?"
-- （"経済学についての論文はどれですか？"）
with search_result as (
    select
        r.value:file_name::varchar as file_name,
        r.value:content::varchar as content,
        r.value:presigned_url::varchar as presigned_url
    from table(flatten(
        parse_json(
            snowflake.cortex.search_preview(
                'm_kajiya_frosty_friday.services.journal_search_service',
                '{
                    "query": "経済学についての論文はどれですか？",
                    "columns": ["file_name", "content", "presigned_url"],
                    "limit": 1
                }'
            )
        )['results']
    )) as r
)
select
    -- 検索でヒットした文書のfile_name / presigned_urlはそのまま返す
    file_name, 
    -- タイトルはヒットした本文に対して AI_COMPLETE() で抽出する
    -- （日本語なせいか EXTRACT_ANSWER() ではタイトルを見つけられない...0.00013 と低いスコアが出ていた）
    snowflake.cortex.ai_complete(
        'llama3.1-8b',
        '次の論文のタイトルを答えて。タイトル以外は出力不要\n\n' || content
    ) as title, 
    presigned_url
from search_result;

------------------------------------------------------------
--
-- 解法2. Terraformで作っていこう
-- → terraform/week-114
--
------------------------------------------------------------

------------------------------------------------------------
--
-- あとしまつ
--
------------------------------------------------------------

use role SYSADMIN;

drop cortex search service M_KAJIYA_FROSTY_FRIDAY.SERVICES.journal_search_service;
drop table M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents_with_url;
drop table M_KAJIYA_FROSTY_FRIDAY.SERVICES.documents;
drop schema M_KAJIYA_FROSTY_FRIDAY.SERVICES;

------------------------------------------------------------
-- 
-- 参考
-- 
------------------------------------------------------------ 

-- - https://docs.snowflake.com/ja/user-guide/snowflake-cortex/cortex-search/cortex-search-overview
-- - https://docs.snowflake.com/ja/user-guide/snowflake-cortex/cortex-search/tutorials/cortex-search-tutorial-3-chat-advanced
