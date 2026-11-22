#!/bin/zsh
cd "$(dirname "$0")"
umask 077
if [ ! -f "servidor_ia/.env" ]; then
  cp "servidor_ia/.env.example" "servidor_ia/.env"
  chmod 600 "servidor_ia/.env"
  echo "Arquivo criado: servidor_ia/.env"
  echo "Cole sua chave da OpenAI depois de OPENAI_API_KEY= e abra este arquivo novamente."
  read "?Pressione Enter para fechar..."
  exit 0
fi

chmod 600 "servidor_ia/.env"
/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart run servidor_ia/servidor_ia.dart
