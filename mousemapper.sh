#!/bin/bash

# modified to zoom in/out with the thumb wheel
# when a scroll event is detected it emits a CTRL and plus/minus (or equal on english keyboard)

keyboard=$(libinput list-devices | grep keyboard -B4 | grep -iE "keyboard$" -A1 | grep -o '/dev/input/event[1-9]*' | head -1)
event_type=EV_KEY
action_type=POINTER_SCROLL_WHEEL

readarray -t devices <<<$(libinput list-devices | grep pointer -B4 | grep -o '/dev/input/event[0-9]*')

function pressKey(){
    key=$1; value=$2
    #echo "pressing ${key} ${value}"
    #echo "evemu-event ${keyboard} --sync --type ${event_type} --code ${key} --value ${value}"
    evemu-event ${keyboard} --sync --type ${event_type} --code ${key} --value ${value};
}

function pressKeyCombo(){
  keys=$@;
  # press keys
  for key in ${keys}; do
    pressKey ${key} 1
  done

  # release keys
  for key in ${keys}; do
    pressKey ${key} 0
  done | tac
}

function pressCommand(){
    move_h=$1

    if [ ${move_h} != "0.00/0.0" ]; then
        if [ ${move_h:0:1} = "-" ]; then
            # scroll left -> zoom in
            pressKeyCombo KEY_LEFTCTRL KEY_EQUAL
        else
            # scroll right -> zoom out
            pressKeyCombo KEY_LEFTCTRL KEY_MINUS
        fi
    fi
}

function parseEventLine(){
    action=$2
    move_h=$7

    # compute only if right action
    if [ ${action} = ${action_type} ]; then
        #echo "event ${1} ${2} ${3} ${4} ${5} ${6} ${7}"
        pressCommand ${move_h}
    fi
}

function mapDevice(){
    device=$1
    while read line; do
        parseEventLine ${line}
    done < <(stdbuf -oL libinput debug-events --device ${device} & )
}

if [[ ${devices[0]} == '' ]]; then
  echo "No Pointers Found. Try again."
  exit 1
fi

for device in ${devices[@]}; do
    ( mapDevice ${device} ) &
done

wait
