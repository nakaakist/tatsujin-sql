# 達人に学ぶ SQL 徹底指南書 第 2 版 を読む

## 概要

本文中に現れる例や演習問題の SQL を考えながらメモ的にまとめる。

## 前提

- VSCode
- docker, docker-compose

## セットアップ

- VSCode でリポジトリを開き、recommend される extension があればインストール。
- docker が動いている前提で、VSCode の run task で setup を実行。docker でローカルホストに PostgreSQL が立ち上がる。
- VSCode の PostgreSQL のプラグインで、新規 connection を作成。ホストネームは localhost、user は postgres、pass は admin、database は postgres、ポートは 5432。
- あとは sql を実行していく。実行したい sql を選択して、右クリック、run query で実行できる。
