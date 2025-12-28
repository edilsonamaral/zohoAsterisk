#!/bin/bash

# Read AGI environment (mandatory)
while read -r line; do
    [ "$line" = "" ] && break
done

# Request the result string from the channel variable
echo "GET VARIABLE DIDDATA_RESULT"
read -r reply

# Parse AGI response like: 200 result=1 (value)
RESULT=$(echo "$reply" | cut -d'(' -f2 | cut -d')' -f1)

# If RESULT is empty, exit early
if [ -z "$RESULT" ]; then
    echo "VERBOSE \"[split_did_result] No data in DIDDATA_RESULT\" 1"
    echo "SET VARIABLE AGI_RESULT -1"
    exit 1
fi

field_list="DB_DID,DB_ACCOUNT,DB_MAINEXTEN,DB_SERVER,DB_SERVERADD,DB_TIMEOUT,DB_LANGUAGE,DB_FWD1,DB_FWD2,DB_FWD3,DB_DIDPROVIDER,DB_QUEUERINGTIME,DB_QUEUEMOHENABLED,DB_DIDACTIVE,DB_PLAYGREETING,DB_PLAYPRIVACY,DB_PLAYMUSICTRANSFER,DB_QUEUEENABLED,_,DB_ENABLEFW2,DB_RECEPCIONIST_EXT,DB_SHOWMENUOPTION_NAME,DB_SCHEDULENAME,DB_EXTENSIONTORING11,DB_EXTENSIONTORING12,DB_EXTENSIONTORING21,DB_EXTENSIONTORING22,DB_EXTENSIONTORING31,DB_EXTENSIONTORING32,DB_EXTENSIONTORING41,DB_EXTENSIONTORING42,DB_HASMENUOPTION1,DB_HASMENUOPTION2,DB_HASMENUOPTION3,DB_HASMENUOPTION4,DB_HASMENUOPTION5,DB_OPTIONMENU0,DB_OPTIONMENU01,DB_OPTIONMENU02,DB_OPTIONMENU1,DB_OPTIONMENU11,DB_OPTIONMENU12,DB_OPTIONMENU2,DB_OPTIONMENU21,DB_OPTIONMENU22,DB_OPTIONMENU3,DB_OPTIONMENU31,DB_OPTIONMENU32,DB_OPTIONMENU4,DB_OPTIONMENU41,DB_OPTIONMENU42,DB_OPTIONMENU5,DB_OPTIONMENU51,DB_OPTIONMENU52,DB_ALSORING11,DB_ALSORING12,DB_ALSORING13,DB_ALSORING14,DB_ALSORING21,DB_ALSORING22,DB_ALSORING23,DB_ALSORING24,DB_ALSORING31,DB_ALSORING32,DB_ALSORING33,DB_ALSORING34,DB_ALSORING41,DB_ALSORING42,DB_ALSORING43,DB_ALSORING44,DB_LANGUAGE_OPTION_0,DB_LANGUAGE_OPTION_01,DB_LANGUAGE_OPTION_02,DB_LANGUAGE_OPTION_1,DB_LANGUAGE_OPTION_11,DB_LANGUAGE_OPTION_12,DB_LANGUAGE_OPTION_2,DB_LANGUAGE_OPTION_21,DB_LANGUAGE_OPTION_22,DB_LANGUAGE_OPTION_3,DB_LANGUAGE_OPTION_31,DB_LANGUAGE_OPTION_32,DB_LANGUAGE_OPTION_4,DB_LANGUAGE_OPTION_41,DB_LANGUAGE_OPTION_42,DB_LANGUAGE_OPTION_5,DB_LANGUAGE_OPTION_51,DB_LANGUAGE_OPTION_52,DB_RINGTIME2,DB_RINGTIME11,DB_RINGTIME12,DB_RINGTIME21,DB_RINGTIME22,DB_RINGTIME31,DB_RINGTIME32,DB_RINGTIME41,DB_RINGTIME42,DB_PROFILE_NAME,DB_PARKTHECALL"


# Split the result string by comma

# 🔧 Clean line endings
# Convert both field list and result into arrays
IFS=',' read -ra keys <<< "$field_list"
IFS=',' read -ra values <<< "$RESULT"

# Map each key to corresponding value
for index in "${!keys[@]}"; do
    key="${keys[$index]}"
    val="${values[$index]}"
    [ -z "$key" ] && continue
    [ "$key" = "_" ] && continue
    val="${val//\"/\\\"}"
    echo "SET VARIABLE $key \"$val\""
done


# Safely build field list from keys (skipping "_")
safe_field_list=""
for k in "${keys[@]}"; do
    [ "$k" = "_" ] && continue
    safe_field_list+="$k,"
done
# Trim trailing comma
safe_field_list="${safe_field_list%,}"

# Emit cleanly to Asterisk
echo "SET VARIABLE DIDDATA_FIELDNAMES \"$safe_field_list\""




exit 0


: <<'COMMENT_BLOCK'
field_list=(
  DB_DID DB_ACCOUNT DB_MAINEXTEN DB_SERVER DB_SERVERADD DB_TIMEOUT DB_LANGUAGE
  DB_FWD1 DB_FWD2 DB_FWD3 DB_DIDPROVIDER DB_QUEUERINGTIME DB_QUEUEMOHENABLED
  DB_DIDACTIVE DB_PLAYGREETING DB_PLAYPRIVACY DB_PLAYMUSICTRANSFER
  DB_QUEUEENABLED _ DB_ENABLEFW2 DB_RECEPCIONIST_EXT DB_SHOWMENUOPTION_NAME
  DB_SCHEDULENAME DB_EXTENSIONTORING11 DB_EXTENSIONTORING12 DB_EXTENSIONTORING21
  DB_EXTENSIONTORING22 DB_EXTENSIONTORING31 DB_EXTENSIONTORING32
  DB_EXTENSIONTORING41 DB_EXTENSIONTORING42 DB_HASMENUOPTION1
  DB_HASMENUOPTION2 DB_HASMENUOPTION3 DB_HASMENUOPTION4 DB_HASMENUOPTION5
  DB_OPTIONMENU0 DB_OPTIONMENU01 DB_OPTIONMENU02 DB_OPTIONMENU1
  DB_OPTIONMENU11 DB_OPTIONMENU12 DB_OPTIONMENU2 DB_OPTIONMENU21
  DB_OPTIONMENU22 DB_OPTIONMENU3 DB_OPTIONMENU31 DB_OPTIONMENU32
  DB_OPTIONMENU4 DB_OPTIONMENU41 DB_OPTIONMENU42 DB_OPTIONMENU5
  DB_OPTIONMENU51 DB_OPTIONMENU52 DB_ALSORING11 DB_ALSORING12
  DB_ALSORING13 DB_ALSORING14 DB_ALSORING21 DB_ALSORING22 DB_ALSORING23
  DB_ALSORING24 DB_ALSORING31 DB_ALSORING32 DB_ALSORING33 DB_ALSORING34
  DB_ALSORING41 DB_ALSORING42 DB_ALSORING43 DB_ALSORING44
  DB_LANGUAGE_OPTION_0 DB_LANGUAGE_OPTION_01 DB_LANGUAGE_OPTION_02
  DB_LANGUAGE_OPTION_1 DB_LANGUAGE_OPTION_11 DB_LANGUAGE_OPTION_12
  DB_LANGUAGE_OPTION_2 DB_LANGUAGE_OPTION_21 DB_LANGUAGE_OPTION_22
  DB_LANGUAGE_OPTION_3 DB_LANGUAGE_OPTION_31 DB_LANGUAGE_OPTION_32
  DB_LANGUAGE_OPTION_4 DB_LANGUAGE_OPTION_41 DB_LANGUAGE_OPTION_42
  DB_LANGUAGE_OPTION_5 DB_LANGUAGE_OPTION_51 DB_LANGUAGE_OPTION_52
  DB_RINGTIME2 DB_RINGTIME11 DB_RINGTIME12 DB_RINGTIME21 DB_RINGTIME22
  DB_RINGTIME31 DB_RINGTIME32 DB_RINGTIME41 DB_RINGTIME42 DB_PROFILE_NAME
) #  the underscore (_) is acting as a "dummy variable name", because, There appears to be an extra field between DB_QUEUEENABLED and DB_ENABLEFW2
IFS=',' read -ra values <<< "$RESULT"
# Assign each variable to Asterisk
for i in "${!field_list[@]}"; do
    key="${field_list[$i]}"
    val="${values[$i]}"
    [ -z "$key" ] && continue
    [ "$key" = "_" ] && continue
    val="${val//\"/\\\"}"
    echo "SET VARIABLE $key \"$val\""
done
        Set(DB_DID=${CUT(result,\,,1)});
        Set(DB_ACCOUNT=${CUT(result,\,,2)});
        Set(DB_MAINEXTEN=${CUT(result,\,,3)});
        Set(DB_SERVER=${CUT(result,\,,4)});
        Set(DB_SERVERADD=${CUT(result,\,,5)});
        Set(DB_TIMEOUT=${CUT(result,\,,6)});
        Set(DB_LANGUAGE=${CUT(result,\,,7)});

        Set(DB_FWD1=${CUT(result,\,,8)});
        Set(DB_FWD2=${CUT(result,\,,9)});
        Set(DB_FWD3=${CUT(result,\,,10)});

        Set(DB_DIDPROVIDER=${CUT(result,\,,11)});

        Set(DB_QUEUERINGTIME=${CUT(result,\,,12)});
        Set(DB_QUEUEMOHENABLED=${CUT(result,\,,13)});
        Set(DB_DIDACTIVE=${CUT(result,\,,14)});
        Set(DB_PLAYGREETING=${CUT(result,\,,15)});
        Set(DB_PLAYPRIVACY=${CUT(result,\,,16)});
        Set(DB_PLAYMUSICTRANSFER=${CUT(result,\,,17)});
        Set(DB_QUEUEENABLED=${CUT(result,\,,18)});
        Set(DB_ENABLEFW2=${CUT(result,\,,20)});
        Set(DB_RECEPCIONIST_EXT=${CUT(result,\,,21)});
        Set(DB_SHOWMENUOPTION_NAME=${CUT(result,\,,22)});
        Set(DB_SCHEDULENAME=${CUT(result,\,,23)});

        Set(DB_EXTENSIONTORING11=${CUT(result,\,,24)});
        Set(DB_EXTENSIONTORING12=${CUT(result,\,,25)});
        Set(DB_EXTENSIONTORING21=${CUT(result,\,,26)});
        Set(DB_EXTENSIONTORING22=${CUT(result,\,,27)});
        Set(DB_EXTENSIONTORING31=${CUT(result,\,,28)});
        Set(DB_EXTENSIONTORING32=${CUT(result,\,,29)});
        Set(DB_EXTENSIONTORING41=${CUT(result,\,,30)});
        Set(DB_EXTENSIONTORING42=${CUT(result,\,,31)});

        Set(DB_HASMENUOPTION1=${CUT(result,\,,32)});
        Set(DB_HASMENUOPTION2=${CUT(result,\,,33)});
        Set(DB_HASMENUOPTION3=${CUT(result,\,,34)});
        Set(DB_HASMENUOPTION4=${CUT(result,\,,35)});
        Set(DB_HASMENUOPTION5=${CUT(result,\,,36)});

        Set(DB_OPTIONMENU0=${CUT(result,\,,37)});
        Set(DB_OPTIONMENU01=${CUT(result,\,,38)});
        Set(DB_OPTIONMENU02=${CUT(result,\,,39)});
        Set(DB_OPTIONMENU1=${CUT(result,\,,40)});
        Set(DB_OPTIONMENU11=${CUT(result,\,,41)});
        Set(DB_OPTIONMENU12=${CUT(result,\,,42)});
        Set(DB_OPTIONMENU2=${CUT(result,\,,43)});
        Set(DB_OPTIONMENU21=${CUT(result,\,,44)});
        Set(DB_OPTIONMENU22=${CUT(result,\,,45)});
        Set(DB_OPTIONMENU3=${CUT(result,\,,46)});
        Set(DB_OPTIONMENU31=${CUT(result,\,,47)});
        Set(DB_OPTIONMENU32=${CUT(result,\,,48)});
        Set(DB_OPTIONMENU4=${CUT(result,\,,49)});
        Set(DB_OPTIONMENU41=${CUT(result,\,,50)});
        Set(DB_OPTIONMENU42=${CUT(result,\,,51)});
        Set(DB_OPTIONMENU5=${CUT(result,\,,52)});
        Set(DB_OPTIONMENU51=${CUT(result,\,,53)});
        Set(DB_OPTIONMENU52=${CUT(result,\,,54)});

        Set(DB_ALSORING11=${CUT(result,\,,55)});
        Set(DB_ALSORING12=${CUT(result,\,,56)});
        Set(DB_ALSORING13=${CUT(result,\,,57)});
        Set(DB_ALSORING14=${CUT(result,\,,58)});
        Set(DB_ALSORING21=${CUT(result,\,,59)});
        Set(DB_ALSORING22=${CUT(result,\,,60)});
        Set(DB_ALSORING23=${CUT(result,\,,61)});
        Set(DB_ALSORING24=${CUT(result,\,,62)});
        Set(DB_ALSORING31=${CUT(result,\,,63)});
        Set(DB_ALSORING32=${CUT(result,\,,64)});
        Set(DB_ALSORING33=${CUT(result,\,,65)});
        Set(DB_ALSORING34=${CUT(result,\,,66)});
        Set(DB_ALSORING41=${CUT(result,\,,67)});
        Set(DB_ALSORING42=${CUT(result,\,,68)});
        Set(DB_ALSORING43=${CUT(result,\,,69)});
        Set(DB_ALSORING44=${CUT(result,\,,70)});

        Set(DB_LANGUAGE_OPTION_0=${CUT(result,\,,71)});
        Set(DB_LANGUAGE_OPTION_01=${CUT(result,\,,72)});
        Set(DB_LANGUAGE_OPTION_02=${CUT(result,\,,73)});
        Set(DB_LANGUAGE_OPTION_1=${CUT(result,\,,74)});
        Set(DB_LANGUAGE_OPTION_11=${CUT(result,\,,75)});
        Set(DB_LANGUAGE_OPTION_12=${CUT(result,\,,76)});
        Set(DB_LANGUAGE_OPTION_2=${CUT(result,\,,77)});
        Set(DB_LANGUAGE_OPTION_21=${CUT(result,\,,78)});
        Set(DB_LANGUAGE_OPTION_22=${CUT(result,\,,79)});
        Set(DB_LANGUAGE_OPTION_3=${CUT(result,\,,80)});
        Set(DB_LANGUAGE_OPTION_31=${CUT(result,\,,81)});
        Set(DB_LANGUAGE_OPTION_32=${CUT(result,\,,82)});
        Set(DB_LANGUAGE_OPTION_4=${CUT(result,\,,83)});
        Set(DB_LANGUAGE_OPTION_41=${CUT(result,\,,84)});
        Set(DB_LANGUAGE_OPTION_42=${CUT(result,\,,85)});
        Set(DB_LANGUAGE_OPTION_5=${CUT(result,\,,86)});
        Set(DB_LANGUAGE_OPTION_51=${CUT(result,\,,87)});
        Set(DB_LANGUAGE_OPTION_52=${CUT(result,\,,88)});

        Set(DB_RINGTIME2=${CUT(result,\,,89)});
        Set(DB_RINGTIME11=${CUT(result,\,,90)});
        Set(DB_RINGTIME12=${CUT(result,\,,91)});
        Set(DB_RINGTIME21=${CUT(result,\,,92)});
        Set(DB_RINGTIME22=${CUT(result,\,,93)});
        Set(DB_RINGTIME31=${CUT(result,\,,94)});
        Set(DB_RINGTIME32=${CUT(result,\,,95)});
        Set(DB_RINGTIME41=${CUT(result,\,,96)});
        Set(DB_RINGTIME42=${CUT(result,\,,97)});
        Set(DB_PROFILE_NAME=${CUT(result,\,,98)});
COMMENT_BLOCK
