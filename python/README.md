# Python 実行環境

このディレクトリでは、Python で課題を解くための環境を用意しています。
次のツールを含みます：

- Snowflake Python API
- Snowflake CLI

## ディレクトリ構成

```
python/
├── Dockerfile
├── docker compose.yml
├── requirements.txt
├── Makefile
├── .env.example
├── connection_example.py
├── generate_snowflake_config.py
└── README.md
```

## セットアップ

1. 環境変数の設定
   ```bash
   cp .env.example ../.env
   # ../.env ファイルを編集して、Snowflakeの接続情報を設定
   ```
   - ここではキーペア認証を使用します：
      - 秘密鍵: `../.ssh/rsa_key.p8` に配置してください
      - パスフレーズ: 環境変数 `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` で設定しています

2. Docker イメージのビルド
   ```bash
   make build
   ```

## 使用方法

### インタラクティブシェル
```bash
make run
# または
docker compose run --rm snowflake-python
```

<details>
<summary>Snowflake CLI を使う</summary>

```bash
# ~/.snowflale/config.toml を生成
python ./generate_snowflake_config.py
# 接続確認
snow connection test

+-------------------------------------------------------+
| key             | value                               |
|-----------------+-------------------------------------|
| Connection name | sandbox                             |
| Status          | OK                                  |
| Host            | your-account.snowflakecomputing.com |
| Account         | your-account                        |
| User            | your-name                           |
| Role            | your-role                           |
| Database        | your-database                       |
| Warehouse       | your-warehouse                      |
+-------------------------------------------------------+
```

</details>

### Jupyter Notebook
```bash
make jupyter
# ブラウザで http://localhost:8888 を開く
```

### Python スクリプトの実行
```bash
docker compose run --rm snowflake-python python connection_example.py
```
