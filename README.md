# HABitatX
HABitatX は，openHAB では煩雑になりがちな複数デバイスの一括管理を支援するツールである．
本システムは，openHAB の一括管理操作を提供するインターフェースとして動作する．事前に openHAB が動作していることが条件である．
本システムは単体で動作し， 同じコンピュータ上で動作している openHAB のデバイス設定を担うテキストファイルを一括で作成，変更，削除できる．
openHAB のデバイス設定を担うテキストファイルはテンプレートコードとスプレッドシートから作成される．
テンプレートコードとは，openHAB のデバイスを設定するテキストファイルの構造やフォーマットを定義し、
必要な情報を指定された箇所に埋め込むことができるコードである．形式として ERB を用いる．
スプレッドシートは，テキストファイル作成に必要な，テンプレートコードに埋め込まれる情報をもつインタフェースである．Excel 形式を用いる．

"HABitatX"は，"openHAB"，"habitat"をもとに作られた造語である．
この名前は，openHAB を表す"HAB"と生息地を表す"habitat"，未来への展望を表す"X"を組み合わせたものである．
# Requirements
+ Ruby 3.x
+ openHAB 3~
  + https://www.openhab.org/
+ PostgreSQL 14.x
  + https://www.postgresql.org/


# Setup
## HABitatX
1. ダウンロードする
   ```bash
   $ git clone https://github.com/SenoOh/HABitatX.git
   ```
## Install SQL
本システムは DB との接続に`ActiveRecord`を使用しているため，任意のリレーショナルデータベース管理システム(`RDBMS`)を使用できる．今回は例として PostgreSQL のインストールについて説明する．

### Install PostgreSQL
+ PostgreSQL 14 の公式リポジトリを追加する
```
$ sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
```
+ 公開鍵を追加する
```
$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
```
+ インストールして起動確認する
```
$ sudo apt update
$ sudo apt install postgresql-14 postgresql-client-14
$ sudo systemctl status postgresql
```
+ ROLE を追加して postgres ユーザーとしてシェルにログインする
```
$ sudo -u postgres createuser -s habitatx
$ sudo -i -u postgres
```
+ データベースに接続して ROLE の password を変更する
```
$ psql
postgres=# ALTER USER habitatx PASSWORD 'your_password'; 
```
+ シェルからログアウトし，PostgreSQLの pg_hba.conf ファイルの認証方式を`peer`から`trust`に書き換える
```
$ sudo nano /etc/postgresql/14/main/pg_hba.conf
```
+ PostgreSQL を再起動する
```
$ sudo systemctl restart postgresql
```
+ PostgreSQLに関連するライブラリをインストールする
```
$ sudo apt install libpq-dev
```

# Launch
## 事前準備
1. `habitatx.rb` の `OPENHAB_PATH` を自分の openHAB の設定ファイルが置かれるディレクトリに変更する
2. `ActiveRecord::Base.establish_connection()`について自身の SQL の情報に変更する
3. `config/database.yml` の SQL の情報を自身の SQL の情報に変更する
4. 任意の SQL の gem をインストールする
5. `bundle install`する
   ```bash
   $ bundle install
   ```
4. DBを作成する
  ```bash
  $ bundle exec rake db:migrate
  ```

## Linux
1. 起動
```bash
$ bundle exec ruby habitatx.rb
```
起動後，ブラウザ上で http://localhost:4567 を開くと HABitatX の画面が開く

## Docker
1. コンテナイメージ作成
```bash
$ docker build -t habitatx_docker .
```
2. 起動 (openHAB がコンテナで動いていない場合)
```shell
$ docker run -it -p 4567:4567 --name habitatx -v ${PWD}/:/var/www habitatx_docker
```
3. 起動 (openHAB がコンテナで動いている場合)
```shell
$ docker run -it -p 4567:4567 --name habitatx -v ${PWD}/:/var/www --volumes-from <openHABのコンテナ名> habitatx_docker
```
起動後，ブラウザ上で http://localhost:4567 を開くと HABitatX の画面が開く