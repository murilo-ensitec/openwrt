#!/bin/sh

PORTAS="0 1 2 3 4"

ULTIMO_0="down"
ULTIMO_1="down"
ULTIMO_2="down"
ULTIMO_3="down"
ULTIMO_4="down"

while true; do
    for p in $PORTAS; do
        case $p in
            0) LED="wan_led" ;;
            1) LED="lan1_led" ;;
            2) LED="lan2_led" ;;
	        3) LED="lan3_led" ;;
	        4) LED="lan4_led" ;;
        esac

        LINK=$(swconfig dev switch0 port "$p" show | grep "link:up")

        [ -n "$LINK" ] && ESTADO="up" || ESTADO="down"

        eval "ULTIMO=\$ULTIMO_$p"

        if [ "$ESTADO" != "$ULTIMO" ]; then
            if [ "$ESTADO" = "up" ]; then
                echo timer > "/sys/class/leds/$LED/trigger"
                echo 50 > "/sys/class/leds/$LED/delay_on"
                echo 50 > "/sys/class/leds/$LED/delay_off"
            else
                echo none > "/sys/class/leds/$LED/trigger"
                echo 0 > "/sys/class/leds/$LED/brightness"
            fi
            eval "ULTIMO_$p=$ESTADO"
        fi
    done

    sleep 1
done
