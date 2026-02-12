[English][] | [日本語][]


[English]:  https://github.com/nomlab/HABitatX/blob/main/README.md       "English"
[日本語]:    https://github.com/nomlab/HABitatX/blob/main/README.ja.md    "日本語"

# HABitatX
HABitatX は，スマートホームシステムである openHAB では煩雑になりがちな複数デバイスの一括管理を支援するツールである．
本システムは，openHAB の一括管理操作を提供するインターフェースとして動作する．事前に openHAB が動作していることが条件である．
本システムは単体で動作し，openHAB が動作するコンピュータ上で動作している．
本システムは openHAB のデバイス設定を担うテキストファイルを一括で作成，変更，削除できる．

openHAB のデバイス設定を担うテキストファイルはテンプレートコードとスプレッドシートから作成される．
テンプレートコードは，openHAB のデバイスを設定するテキストファイルの構造を定義する．
また，テンプレートコードは埋め込み型であり，外部から取得した情報を指定された箇所に埋め込むことでテキストファイルを作成する．形式としてテンプレートエンジンである ERB を用いる．
スプレッドシートは，テンプレートコードに埋め込まれる情報の一覧を持つインタフェースである．
Excel 形式を用いる．

"HABitatX"は，"openHAB"，"habitat"をもとに作られた造語である．
この名前は，openHAB を表す"HAB"と生息地を表す"habitat"，未来への展望を表す"X"を組み合わせたものである．
# Requirements
+ Ruby 3.3.3
+ Ruby on Rails 7.1.3.4
+ openHAB 3.4.3 ~
  + https://www.openhab.org/
+ RDBMS (Relational Data Base Management System)


# Setup
## HABitatX
1. ダウンロードする
   ```bash
   $ git clone https://github.com/SenoOh/HABitatX.git
   ```
## Install RDBMS
本システムは DB との接続に`ActiveRecord`を使用しているため，任意のリレーショナルデータベース管理システム(`RDBMS`)を使用できる．Docker で動かす際は不要である．今回は例として SQLite3 のインストールについて説明する．
1. aptでインストールする
   ```bash
   $ sudo apt install sqlite3
   ```

# Launch
## 事前準備
1. `.env.example` をコピーして `.env` を作成する
2. `.env` の `OPENHAB_PATH`，`OPENHAB_LINK`をそれぞれ自身の情報に置き換える
3. コンテナを利用する際は，`.env` の ポート設定やUID設定を完了させる
4. production 環境で利用する場合は`.env` の `RAILS_ENV` を `production` とし，`SECRET_KEY_BASE` を生成する
5. `OPENHAB_PATH` のアクセス権限を変更する
* Docker の場合
   ```bash
   $ sudo chgrp -R ${UID} ${OPENHAB_PATH}
   $ sudo chmod -R 775 ${OPENHAB_PATH}
   ```
   * 例：UID:1000, OPENHAB_PATH:/etc/openhab の場合
      ```bash
      $ sudo chgrp -R 1000 /etc/openhab
      $ sudo chmod -R 775 /etc/openhab
      ```


## Docker (推奨)
1. コンテナイメージ作成
```bash
$ ./start.sh
```
起動後，ブラウザ上で http://localhost:9000 を開くと HABitatX の画面が開く
* production 環境の場合，起動後，ブラウザ上で http://localhost:9100 を開くと HABitatX の画面が開く

## Linux
1. `bundle install`する
   ```bash
   $ bundle install
   ```
2. DBを作成する
   ```bash
   $ rails db:migrate
   ```
3. 起動
```bash
$ bundle exec rails server
```
起動後，ブラウザ上で http://localhost:9000 を開くと HABitatX の画面が開く

# Usage
![Overview](./docs/HABitatX_overview.png)
1. テンプレートコード作成
   ```ruby
   table.each do |member|
      equipment(name: "#{member[:name]}", label: "#{member[:label]}", icon: "Man_1", parent: "room106") do
         point(name: "#{member[:name]}_position", label: "#{member[:label]} Position", type: "String", icon: "motion", parent: "positions", tags: ["Point", "Presence"])
         point(name: "#{member[:name]}_status", label: "#{member[:label]} Status", type: "String", icon: "status", tags: ["Point", "Presence"])
      end
   end
   ```
2. template管理部でテンプレート名，ベース名，ファイルタイプ，Content を設定
![Template](./docs/make_template.png)
* codeはテンプレートコードである
* ベース名とテンプレート名を組み合わせて設定DSL名を作成する
* ファイルタイプは拡張子を選択する
* Content は 1 で作成したテンプレートコードである

3. スプレッドシート作成

* 作成方法は[spreadsheet](https://github.com/nomlab/habdsl?tab=readme-ov-file#spreadsheet)参照

4. item管理部でアイテム名，スプレッドシート，テンプレートを設定
![Device](./docs/make_device.png)

5. デバイス一括作成
