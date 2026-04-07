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
	# Sprawdzanie czy plansza jest pełna
    for i in {1..9}; do [[ ${board[$i]} == "_" ]] && return 1; done

    return 0 # Remis
}

player_move() {
    local mark=$1
    while true; do
		read -rp "Gracz $mark, podaj pole (1-9) lub 's' aby zapisać i wyjść: " pos
		[[ $pos == "s" ]] && { save_game; menu; continue; }
        [[ $pos =~ ^[1-9]$ ]] || { echo "Nieprawidłowe pole."; continue; }
        [[ ${board[$pos]} == "_" ]] || { echo "Pole zajęte."; continue; }
        board[$pos]=$mark
        break
    done
}

cpu_move() {
    local mark=$1
    local opp;
    [[ $mark == "X" ]] && opp="O" || opp="X"

	# Próba ruchu - najpierw wygrana, potem blokada, a potem losowy ruch
	# 1. Wygrana - jeśli można wygrać, wykonujemy ruch
	# 2. Blokada - jeśli przeciwnik może wygrać, blokujemy
	# 3. Losowy ruch - wybieramy pierwsze wolne pole
    for p in "$mark" "$opp"; do
        for i in {1..9}; do
            if [[ ${board[$i]} == "_" ]]; then
                board[$i]=$p
                check_win "$p" && { [[ $p == "$mark" ]] || board[$i]="_"; [[ $p == "$mark" ]] && return; }
                board[$i]="_"
            fi
        done
    done

	# Losowy ruch
    for pos in 5 1 3 7 9 2 4 6 8; do # Piorytety: środek, narożniki, pozostałe
        [[ ${board[$pos]} == "_" ]] && { board[$pos]=$mark; return; }
    done
}

save_game() {
    if [[ "$mode" == "cpu" ]]; then
        echo "$mode $current $cpu_mark $cpu_first ${board[*]}" > "$SAVE_FILE"
    else
        echo "$mode $current ${board[*]}" > "$SAVE_FILE"
    fi
    echo ""; echo "Gra zapisana."
}

load_game() {
    [[ -f $SAVE_FILE ]] || { echo ""; echo "Brak zapisanej gry."; return 1; }
    read -r -a saved_data < "$SAVE_FILE"

    mode="${saved_data[0]}"
    current="${saved_data[1]}"
    local board_start_idx=2 # Offset dla trybu PVP

    if [[ "$mode" == "cpu" ]]; then
        cpu_mark="${saved_data[2]}"
        cpu_first="${saved_data[3]}"
        board_start_idx=4 # Offset dla trybu CPU
    fi

    for i in {1..9}; do
        board[$i]="${saved_data[$((board_start_idx + i - 1))]}"
    done
    echo ""; echo "Gra wczytana.";
    return 0
}

end_screen() {
	rm -f "$SAVE_FILE"
    echo ""
    echo "1) Zagraj jeszcze raz"
    echo "2) Wróć do menu"
    echo "3) Wyjdź z gry"
    echo ""
    read -rp "Wybór: " choice
    case $choice in
	    1) if [[ $mode == "cpu" ]]; then
	           [[ $cpu_first == 1 ]] && cpu_first=0 || cpu_first=1
	           if [[ $cpu_first == 1 ]]; then
	               cpu_mark="X"; current="X"
	           else
	               cpu_mark="O"; current="X"
	           fi
	       else
	           current="X"
	       fi
	       init_board; play ;;
        2) menu ;;
        3) exit 1 ;;
        *) echo ""; echo "Nieprawidłowy wybór."; end_screen ;;
    esac
}

play() {
    while true; do
        print_board

        if [[ $mode == "cpu" && $current == "$cpu_mark" ]]; then
            echo "Ruch komputera..."
            cpu_move "$cpu_mark"
        else
            player_move "$current"
        fi

        if check_win "$current"; then
            print_board
            [[ $mode == "cpu" && $current == "$cpu_mark" ]] \
                && echo "Komputer wygrał!" \
                || echo "Gracz $current wygrał!"
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

menu() {
    echo ""
    echo "=== KÓŁKO I KRZYŻYK ==="
    echo ""
    echo "1) Gra na dwóch graczy"
    echo "2) Gra z komputerem"
    echo "3) Wczytaj zapisaną grę"
    echo "4) Wyjdź z gry"
    echo ""
    read -rp "Wybór: " choice

    case $choice in
    	1) mode="pvp"; current="X"; starter="X"; init_board; play ;;
	    2) mode="cpu"; cpu_first=0; cpu_mark="O"; current="X"; starter="X"; init_board; play ;;
        3) load_game && play || menu ;;
        4) exit 0 ;;
        *) echo ""; echo "Nieprawidłowy wybór."; menu ;;
    esac
}

SAVE_FILE="kk_zapis.txt"

menu
