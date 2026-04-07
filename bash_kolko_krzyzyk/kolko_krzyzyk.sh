#!/bin/bash

init_board() { for i in {1..9}; do board[$i]="_"; done; }

print_board() {
    echo ""
    echo " ${board[1]} | ${board[2]} | ${board[3]}"
    echo "---+---+---"
    echo " ${board[4]} | ${board[5]} | ${board[6]}"
    echo "---+---+---"
    echo " ${board[7]} | ${board[8]} | ${board[9]}"
    echo ""
}

check_win() {
    local p=$1 # Znak gracza ('X' lub 'O')
    local wins=("1 2 3" "4 5 6" "7 8 9" "1 4 7" "2 5 8" "3 6 9" "1 5 9" "3 5 7") # Pozycje wygrywające

    # Sprawdzenie, czy któryś z wierszy, kolumn lub przekątnych jest wygrywający
    for line in "${wins[@]}"; do
        read -r a b c <<< "$line"
        [[ ${board[$a]} == "$p" && ${board[$b]} == "$p" && ${board[$c]} == "$p" ]] && return 0
    done

    return 1 # Nikt nie wygrał
}

is_draw() {
    for i in {1..9}; do [[ ${board[$i]} == "_" ]] && return 1; done # Sprawdzanie czy plansza jest pełna

    return 0 # Remis
}

player_move() {
    local mark=$1
    while true; do
        read -rp "Gracz $mark, podaj pole (1-9): " pos
        [[ $pos =~ ^[1-9]$ ]] || { echo "Nieprawidłowe pole."; continue; }
        [[ ${board[$pos]} == "_" ]] || { echo "Pole zajęte."; continue; }
        board[$pos]=$mark
        break
    done
}

end_screen() {
    echo ""
    echo "1) Zagraj jeszcze raz"
    echo "2) Wyjdź"
    echo ""
    read -rp "Wybór: " choice
    case $choice in
        1) current="X"
           init_board; play ;;
        2) exit 1 ;;
        *) echo ""; echo "Nieprawidłowy wybór."; end_screen ;;
    esac
}

play() {
    while true; do
        print_board

        player_move "$current"

        if check_win "$current"; then
            print_board
            echo "Gracz $current wygrał!"
            end_screen
            return
        fi

        if is_draw; then
        	print_board
        	echo "Remis!"
            end_screen
            return
        fi

        [[ $current == "X" ]] && current="O" || current="X"
    done
}

current="X"
init_board
play
