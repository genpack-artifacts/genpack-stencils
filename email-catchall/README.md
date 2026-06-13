# theme: email-catchall

postfix + dovecot を使い、**宛先を問わずすべてのメールをローカルの `mail` ユーザーに集約**するキャッチオール構成のステンシルです。
TLS なし・パスワードなしで接続できるため、メール送受信を伴う開発・テスト環境に最適です。

## メールクライアントの接続設定

| プロトコル | ホスト      | ポート | TLS | 認証   |
|-----------|------------|-------|-----|--------|
| IMAP      | localhost  | 143   | なし | なし (任意の ID/Pass で可) |
| SMTP      | localhost  | 25    | なし | なし   |

## テストメール送信例

```sh
sendmail -t <<EOF
From: test@example.com
To: johndoe@example.com
Subject: sendmail test

これは sendmail コマンドから送ったテストメールです。
EOF
```

## アーティファクトへの適用

1. `genpack.json5` の `packages` / `services` を対象アーティファクトへマージ。
   - マージ箇所に `// ref: email-catchall/genpack.json5` を残す。
2. `files/build.d/setup-catchall.sh` をコピー。
3. 必要に応じてメールクライアント（例: `mail-client/evolution`）を `packages` に追加。
