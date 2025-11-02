import streamlit as st
from snowflake.snowpark.context import get_active_session
import snowflake.permissions as permission
from sys import exit

st.set_page_config(layout="wide")

try:
    session = get_active_session()
except Exception as e:
    st.error(f"❌ Snowflake セッションの取得に失敗しました: {e}")
    exit(1)

if not hasattr(st.session_state, "permission_granted"):
    try:
        permission.request_reference("frosty_table")
        st.session_state.permission_granted = True
    except Exception as e:
        st.error(f"❌ テーブル参照のリクエストに失敗しました: {e}")

if not permission.get_held_account_privileges(["CREATE DATABASE"]):
    try:
        permission.request_account_privileges(["CREATE DATABASE"])
    except Exception as e:
        st.error(f"❌ CREATE DATABASE 権限のリクエストに失敗しました: {e}")

st.title("🔐 Frosty 権限チェック")

check = st.button('✅ 必要な権限が揃っているか確認しますか？')
if check:
    if permission.get_held_account_privileges(["CREATE DATABASE"]) and len(permission.get_reference_associations("frosty_table")) > 0:
        st.success('✅ 問題ありません！必要な権限はすべて揃っています')
    else:
        st.warning('⚠️ 一部の権限が不足しています。リクエストされた権限を付与してください。')
