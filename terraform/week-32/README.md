# Week-32 <!-- omit in toc -->
## 概要
ここは「[Week 32 – Basic | Session Security](https://frostyfriday.org/blog/2023/02/03/week-32-basic/)」の Terraform 版解法置き場です。

⚠️ Snowflake provider v0.99.0 の時点では Session policy リソースが無いため、代わりに**危険なリソース**を使っています。よほどのことがない限り参考にしないでください ⚠️

## 目次 <!-- omit in toc -->

- [概要](#概要)
- [フォルダ構成](#フォルダ構成)


## フォルダ構成

| フォルダ | 内容 |
|:--|:--|
| [environments/common](./environments/common) | 実際の環境にデプロイされるリソースを配置。<br>dev/stg/prd/... と環境別に分けるものだけど、<br>今回はユーザーとセッションポリシーだけだからまとめちゃった |
| [~~modules~~](./modules) | モジュール化するほどリソースが無かったので使ってない |
