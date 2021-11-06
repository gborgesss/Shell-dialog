#!/usr/bin/env bash

# ------------------------------- VARIÁVEIS ----------------------------------------- #
DADOS_ESTOQUE="estoque_loja.txt"
SEP=:
TEMP=temp.$$

#Cores
VERDE="\033[32;1m"
VERMELHO="\033[31;1m"
# ------------------------------------------------------------------------ #

# ------------------------------- TESTES ----------------------------------------- #
[ ! -f "$DADOS_ESTOQUE" ] && echo "ERRO. Arquivo de dados não existe." && exit 1
[ ! -r "$DADOS_ESTOQUE" ] && echo "ERRO. Arquivo de dados não tem permissão de leitura." && exit 1
[ ! -w "$DADOS_ESTOQUE" ] && echo "ERRO. Arquivo de dados não tem permissão de escrita." && exit 1
[ ! -x "$(which dialog)" ] && sudo apt omstall dialog 1> /dev/null 2>&1
# ------------------------------------------------------------------------ #

# ------------------------------- FUNÇÕES ----------------------------------------- #
ListaProdutos () {
  egrep -v "^#|^$" "$DADOS_ESTOQUE" | tr : ' ' > "$TEMP"
  dialog --title "Lista de Produtos" --textbox "$TEMP" 20 40
  rm -f "$TEMP"
}

ValidaExistenciaProduto () {
  grep -i -q "$1$SEP" "$DADOS_ESTOQUE"
}

ApagaProduto () {
  ValidaExistenciaProduto "$1" || return

  grep -i -v "$1$SEP" "$DADOS_ESTOQUE" > "$TEMP"
  mv "$TEMP" "$DADOS_ESTOQUE"

  echo "Produto removido com sucesso!"
}

# ------------------------------------------------------------------------ #

# ------------------------------- EXECUÇÃO ----------------------------------------- #
while :
do
  acao=$(dialog --title "Controle loja 2.0" \
                --stdout \
                --menu "Escolha uma das opções abaixo:" \
                0 0 0 \
                listar "Listar todos os produtos em estoque" \
                remover "Remover um produto do estoque" \
                inserir "Inserir um novo produto no estoque")
  [ $? -ne 0 ] && exit

  case $acao in
      listar) ListaProdutos   ;;
      inserir)
          ultimo_id="$(egrep -v "^#|^$" $DADOS_ESTOQUE | sort | tail -n 1 | cut -d $SEP -f 1)"
          proximo_id=$(($ultimo_id+1))

          produto=$(dialog --title "Cadastro de Produtos" --stdout --inputbox "Digite o nome do Produto" 0 0)
          [ ! "$produto" ] && exit

          ValidaExistenciaProduto "$produto" && {
            dialog --title "ERRO FATAL!" --msgbox "Produto já cadastrado!" 6 40
            exit
          }
          local estoque=$(dialog --title "Cadastro de Produtos" --stdout --inputbox "Digite o número em estoque" 0 0)
          [ $? -ne 0 ] && continue

          echo "$ultimo_id$SEP$produto$SEP$estoque" >> "$DADOS_ESTOQUE"
          dialog --title "SUCESSO!" --msgbox "Produto cadastrado com sucesso!" 6 40

          ListaProdutos
      ;;
      remover)
          produtos=$(egrep "^#|^$" -v "$DADOS_ESTOQUE" | sort -h | cut -d $SEP -f 1,2 | sed 's/:/ "/;s/$/"/')
          id_produt_rmv=$(eval dialog --stdout --menu \"Remover produto:\" 0 0 0 $produtos)
          [ $? -ne 0 ] && continue

          grep -i -v "^$id_produt_rmv$SEP" "$DADOS_ESTOQUE" > "$TEMP"
          mv "$TEMP" "$DADOS_ESTOQUE"

          dialog --msgbox "Produto removido com sucesso!"
          ListaProdutos
       ;;
    esac
done
# ------------------------------------------------------------------------ #
