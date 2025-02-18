#!/system/bin/sh

# --- Variables --- #
# Probably you don't need to modify this. Do it if you know what you're doing, I won't blame you (unless you blame me).
DEVICEWIDTH=1080
pvpEvent=false # Set to `true` if "Heroes of Esperia" event is live
totalAmountOakRewards=3

# Do not modify
RGB=00000000
oakRes=0
forceFightCampaign=false
if [ $# -gt 0 ]; then
    SCREENSHOTLOCATION="/$1/scripts/afk-arena/screen.dump"
    # SCREENSHOTLOCATION="/$1/scripts/afk-arena/screen.png"
    source /$1/scripts/afk-arena/config.sh
    forceFightCampaign=$2
else
    SCREENSHOTLOCATION="/storage/emulated/0/scripts/afk-arena/screen.dump"
    # SCREENSHOTLOCATION="/storage/emulated/0/scripts/afk-arena/screen.png"
    source /storage/emulated/0/scripts/afk-arena/config.sh
fi

# --- Functions --- #
# Test function: take screenshot, get rgb, exit. Params: X, Y, amountTimes, waitTime
function test() {
    local COUNT=0
    until [ "$COUNT" -ge "$3" ]; do
        sleep $4
        getColor "$1" "$2"
        echo "RGB: $RGB"
        ((COUNT = COUNT + 1)) # Increment
    done
    exit
}

# Default wait time for actions
function wait() {
    sleep 2
}

# Starts the app
function startApp() {
    monkey -p com.lilithgame.hgame.gp 1 >/dev/null 2>/dev/null
    sleep 1
    disableOrientation
}

# Closes the app
function closeApp() {
    am force-stop com.lilithgame.hgame.gp >/dev/null 2>/dev/null
}

# Switches between last app
function switchApp() {
    input keyevent KEYCODE_APP_SWITCH
    input keyevent KEYCODE_APP_SWITCH
}

# Disables automatic orientation
function disableOrientation() {
    content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0
}

# Takes a screenshot and saves it
function takeScreenshot() {
    screencap "$SCREENSHOTLOCATION"
}

# Gets pixel color. Params: X, Y
function readRGB() {
    let offset="$DEVICEWIDTH"*"$2"+"$1"+3
    RGB=$(dd if="$SCREENSHOTLOCATION" bs=4 skip="$offset" count=1 2>/dev/null | hexdump -C)
    RGB=${RGB:9:9}
    RGB="${RGB// /}"
    # echo "[INFO] X: "$1" Y: "$2" RGB: $RGB"
}

# Sets RGB. Params: X, Y
function getColor() {
    takeScreenshot
    readRGB "$1" "$2"
}

# Verifies if X and Y have specific RGB. Params: X, Y, RGB, MessageSuccess, MessageFailure
function verifyRGB() {
    getColor "$1" "$2"
    if [ "$RGB" != "$3" ]; then
        echo "[ERROR] VerifyRGB: Failure! Expected "$3", but got "$RGB" instead."
        echo
        echo "[ERROR] $5"
        exit
    else
        echo "[OK] $4"
    fi
}

# Click on auto if not already enabled
function doAuto() {
    getColor 760 1440 # On:743b29 Off:332b2b
    if [ "$RGB" == "332b2b" ]; then input tap 760 1440; fi
}

# Click on x4 if not already enabled
function doSpeed() {
    getColor 990 1440 # On:743b2a Off:332b2b
    if [ "$RGB" == "332b2b" ]; then input tap 990 1440; fi
}

# Click on skip if avaible
function doSkip() {
    getColor 760 1440 # Exists: 502e1d
    if [ "$RGB" == "502e1d" ]; then input tap 760 1440; fi
}

# Waits until battle starts
function waitBattleStart() {
    # Check if pause button is present
    getColor 110 1465 # 482f1f
    until [ "$RGB" == "482f1f" ]; do
        # Maybe pause button doesn't exist, so instead check for a skip button
        getColor 760 1440 # 502e1d
        if [ "$RGB" == "502e1d" ]; then return; fi

        # In case none were found, try again starting with the pause button
        getColor 110 1465 # 482f1f
    done
}

# Switches to another tab. Params: Tab name
function switchTab() {
    case "$1" in
    "Campaign")
        input tap 550 1850
        wait
        verifyRGB 450 1775 cc9261 "Switched to the Campaign Tab." "Failed to switch to the Campaign Tab."
        ;;
    "Dark Forest")
        input tap 300 1850
        wait
        verifyRGB 240 1775 d49a61 "Switched to the Dark Forest Tab." "Failed to switch to the Dark Forest Tab."
        ;;
    "Ranhorn")
        input tap 110 1850
        wait
        verifyRGB 20 1775 d49a61 "Switched to the Ranhorn Tab." "Failed to switch to the Ranhorn Tab."
        ;;
    "Chat")
        input tap 970 1850
        wait
        verifyRGB 550 1690 ffffff "Switched to the Chat Tab." "Failed to switch to the Chat Tab."
        ;;
    esac
}

# Loops until RGB is not equal. Params: Seconds, X, Y, RGB
function loopUntilRGB() {
    sleep "$1"
    getColor $2 $3
    while [ "$RGB" != "$4" ]; do
        sleep 1
        getColor $2 $3
    done
}

# Loops until RGB is equal. Params: Seconds, X, Y, RGB
function loopUntilNotRGB() {
    sleep "$1"
    getColor $2 $3
    while [ "$RGB" == "$4" ]; do
        sleep 1
        getColor $2 $3
    done
}

# Waits until a battle has ended. Params: Seconds
function waitBattleFinish() {
    sleep "$1"
    local finished=false
    while [ $finished == false ]; do
        getColor 560 350
        if [ "$RGB" == "b8894d" ] || [ "$RGB" == "b7894c" ]; then # First RGB local device, second bluestacks
            # Victory
            battleFailed=false
            finished=true
        elif [ "$RGB" == "171932" ]; then
            # Failed
            battleFailed=true
            finished=true
        elif [ "$RGB" == "45331d" ] || [ "$RGB" == "44331c" ]; then # First RGB local device, second bluestacks
            # Victory with reward
            battleFailed=false
            finished=true
        fi
        sleep 1
    done
}

# Buys an item from the Store. Params: X, Y
function buyStoreItem() {
    input tap $1 $2
    sleep 1
    input tap 550 1540
    sleep 1
    input tap 550 1700
}

# Searches for a "good" present in oak Inn
function oakSearchPresent() {
    # Swipe all the way down
    input swipe 400 1600 400 310 50
    sleep 1

    getColor 540 990 # 1 red 833f0e blue 903da0
    if [ "$RGB" == "833f0e" ]; then
        input tap 540 990 # Tap present
        sleep 3
        input tap 540 1650 # Ok
        sleep 1
        input tap 540 1650 # Collect reward
        oakRes=1
    else
        getColor 540 800 # 2 red a21a1a blue 9a48ab
        if [ "$RGB" == "a21a1a" ]; then
            input tap 540 800
            sleep 3
            input tap 540 1650 # Ok
            sleep 1
            input tap 540 1650 # Collect reward
            oakRes=1
        else
            getColor 540 610 # 3 red aa2b27 blue b260aa
            if [ "$RGB" == "aa2b27" ]; then
                input tap 540 610
                sleep 3
                input tap 540 1650 # Ok
                sleep 1
                input tap 540 1650 # Collect reward
                oakRes=1
            else
                getColor 540 420 # 4 red bc3f36 blue c58c7b
                if [ "$RGB" == "bc3f36" ]; then
                    input tap 540 420
                    sleep 3
                    input tap 540 1650 # Ok
                    sleep 1
                    input tap 540 1650 # Collect reward
                    oakRes=1
                else
                    getColor 540 220 # 5 red bb3734 blue 9442a5
                    if [ "$RGB" == "bb3734" ]; then
                        input tap 540 220
                        sleep 3
                        input tap 540 1650 # Ok
                        sleep 1
                        input tap 540 1650 # Collect reward
                        oakRes=1
                    else
                        # If no present found, search for other tabs
                        oakRes=0
                    fi
                fi
            fi
        fi
    fi
}

# Search available present tabs in Oak Inn
function oakPresentTab() {
    # TODO: Script not checking for gifts present in tabs correctly. RGB values need to be updated.
    oakPresentTabs=0
    getColor 270 1800 # 1 gift cf9a67
    if [ "$RGB" == "cf9a67" ]; then
        ((oakPresentTabs = oakPresentTabs + 1000)) # Increment
    fi
    getColor 410 1800 # 2 gift be8350
    if [ "$RGB" == "be8350" ]; then
        ((oakPresentTabs = oakPresentTabs + 200)) # Increment
    fi
    getColor 550 1800 # 3 gift ae6c39
    if [ "$RGB" == "ae6c39" ]; then
        ((oakPresentTabs = oakPresentTabs + 30)) # Increment
    fi
    getColor 690 1800 # 4 gift b17940
    if [ "$RGB" == "b17940" ]; then
        ((oakPresentTabs = oakPresentTabs + 4)) # Increment
    fi
}

# Tries to collect a present from one Oak Inn friend
function oakTryCollectPresent() {
    # Search for a "good" present
    oakSearchPresent
    if [ $oakRes == 0 ]; then
        # If no present found, search for other tabs
        oakPresentTab
        case $oakPresentTabs in
        0)
            oakRes=0
            ;;
        4)
            input tap 690 1800
            sleep 3
            oakSearchPresent
            ;;
        30)
            input tap 550 1800
            sleep 3
            oakSearchPresent
            ;;
        34)
            input tap 550 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 690 1800
                sleep 3
                oakSearchPresent
            fi
            ;;
        200)
            input tap 410 1800
            sleep 3
            oakSearchPresent
            ;;
        204)
            input tap 410 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 690 1800
                sleep 3
                oakSearchPresent
            fi
            ;;
        230)
            input tap 410 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 550 1800
                sleep 3
                oakSearchPresent
            fi
            ;;
        234)
            input tap 410 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 550 1800
                sleep 3
                oakSearchPresent
                if [ $oakRes == 0 ]; then
                    input tap 690 1800
                    sleep 3
                    oakSearchPresent
                fi
            fi
            ;;
        1000)
            input tap 270 1800
            sleep 3
            oakSearchPresent
            ;;
        1004)
            input tap 270
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 690
                sleep 3
                oakSearchPresent
            fi
            ;;
        1030)
            input tap 270 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 550 1800
                sleep 3
                oakSearchPresent
            fi
            ;;
        1034)
            input tap 270 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 550 1800
                sleep 3
                oakSearchPresent
                if [ $oakRes == 0 ]; then
                    input tap 690 1800
                    sleep 3
                    oakSearchPresent
                fi
            fi
            ;;
        1200)
            input tap 270 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 410 1800
                sleep 3
                oakSearchPresent
            fi
            ;;
        1204)
            input tap 270 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 410 1800
                sleep 3
                oakSearchPresent
                if [ $oakRes == 0 ]; then
                    input tap 690 1800
                    sleep 3
                    oakSearchPresent
                fi
            fi
            ;;
        1230)
            input tap 270 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 410 1800
                sleep 3
                oakSearchPresent
                if [ $oakRes == 0 ]; then
                    input tap 550 1800
                    sleep 3
                    oakSearchPresent
                fi
            fi
            ;;
        1234)
            input tap 270 1800
            sleep 3
            oakSearchPresent
            if [ $oakRes == 0 ]; then
                input tap 410 1800
                sleep 3
                oakSearchPresent
                if [ $oakRes == 0 ]; then
                    input tap 550 1800
                    sleep 3
                    oakSearchPresent
                    if [ $oakRes == 0 ]; then
                        input tap 690 1800
                        sleep 3
                        oakSearchPresent
                    fi
                fi
            fi
            ;;
        esac
    fi
}

# Checks where to end the script
function checkWhereToEnd() {
    case "$endAt" in
    "oak")
        switchTab "Ranhorn"
        input tap 780 280
        ;;
    "soren")
        switchTab "Ranhorn"
        input tap 380 360
        sleep 3
        input tap 290 860
        sleep 1
        input tap 970 890
        ;;
    "mail")
        input tap 960 630
        ;;
    "chat")
        switchTab "Chat"
        ;;
    "tavern")
        switchTab "Ranhorn"
        input tap 300 1400
        ;;
    "merchants")
        input tap 120 290
        ;;
    "campaign")
        input tap 550 1850
        ;;
    "championship")
        switchTab "Dark Forest"
        input tap 740 1050
        sleep 2
        if [ "$pvpEvent" == false ]; then
            input tap 550 1370
        else
            input tap 550 1680
        fi
        ;;
    *)
        echo "[WARN] Unknown location to end script on. Ignoring..."
        ;;
    esac
}

# Repeat a battle for as long as totalAmountArenaTries
function quickBattleGuildBosses() {
    local COUNT=0
    until [ "$COUNT" -ge "$totalAmountGuildBossTries" ]; do
        input tap 710 1840
        wait
        input tap 720 1300
        sleep 1
        input tap 550 800
        input tap 550 800
        sleep 1
        ((COUNT = COUNT + 1)) # Increment
    done
}

# Loots afk chest
function lootAfkChest() {
    input tap 550 1500
    sleep 1
    input tap 750 1350
    sleep 3

    # Tap campaign in case of level up
    input tap 550 1850
    sleep 1

    wait
    verifyRGB 450 1775 cc9261 "AFK Chest looted." "Failed to loot AFK Chest."
}

# Challenges a boss in the campaign
function challengeBoss() {
    input tap 550 1650
    sleep 1

    # Check if boss
    getColor 550 740
    if [ "$RGB" == "f2d79f" ]; then
        input tap 550 1450
    fi
    sleep 2

    # Fight battle or not
    if [ "$forceFightCampaign" == "true" ]; then
        # Fight in the campaign because of Mythic Trick
        echo "[INFO] Figthing in campaign because of Mythic Trick $maxCampaignFights time(s)."
        local COUNT=0

        # Check for battle screen
        getColor 200 1850
        while [ "$RGB" == "2b1a12" ] && [ "$COUNT" -lt "$maxCampaignFights" ]; do
            input tap 550 1850 # Battle
            waitBattleStart
            doAuto
            doSpeed
            waitBattleFinish 10 # Wait until battle is over

            # Check battle result
            if [ "$battleFailed" == false ]; then # Win
                # Check for next stage
                getColor 550 1670
                if [ "$RGB" == "e2dddc" ]; then
                    input tap 550 1670 # Next Stage
                    sleep 6

                    # TODO: Limited offers will fuck this part of the script up. I'm yet to find a way to close any possible offers.
                    # Tap top of the screen to close any possible Limited Offers
                    # input tap 550 75
                    # sleep 2

                    # Check if boss
                    getColor 550 740
                    if [ "$RGB" == "f2d79f" ]; then
                        input tap 550 1450
                        sleep 5
                    fi
                else
                    input tap 550 1150 # Continue to next battle
                    sleep 3
                fi
            else # Loose
                # Try again
                input tap 550 1720
                sleep 5

                ((COUNT = COUNT + 1)) # Increment
            fi

            # Check for battle screen
            getColor 200 1850
        done

        # Return to campaign
        input tap 60 1850 # Return
        wait

        # Check for confirm to exit button
        getColor 715 1260
        if [ "$RGB" == "feffff" ]; then
            input tap 715 1260 # Confirm
            wait
        fi
    else
        # Quick exit battle
        input tap 550 1850 # Battle
        sleep 1
        input tap 80 1460 # Pause
        wait
        input tap 230 960 # Exit
        sleep 1

        # Check for multi-battle
        getColor 450 1775
        if [ "$RGB" != "cc9261" ]; then
            input tap 70 1810
        fi
    fi

    wait
    verifyRGB 450 1775 cc9261 "Challenged boss in campaign." "Failed to fight boss in Campaign."
}

# Collects fast rewards
function fastRewards() {
    input tap 950 1660
    sleep 1
    input tap 710 1260
    sleep 2
    input tap 560 1800
    sleep 1
    input tap 400 1250

    wait
    verifyRGB 450 1775 cc9261 "Fast rewards collected." "Failed to collect fast rewards."
}

# Collects and sends companion points, as well as auto lending mercenaries
function collectFriendsAndMercenaries() {
    input tap 970 810 # Friends
    sleep 1
    input tap 930 1600 # Send and receive
    wait
    input tap 720 1760 # Short-term
    sleep 5
    input tap 990 190 # Manage
    wait
    input tap 630 1590 # Apply
    wait
    input tap 750 1410 # Auto Lend
    sleep 1
    input tap 70 1810 # Back
    input tap 70 1810 # Back

    # TODO: Check if its necessary to send mercenaries

    wait
    verifyRGB 450 1775 cc9261 "Sent and recieved companion points, as well as auto lending mercenaries." "Failed to collect/send companion points or failed to auto lend mercenaries."
}

# Starts Solo bounties
function soloBounties() {
    input tap 600 1320
    sleep 1

    # Check if there are bounties to collect
    # getColor 660 520
    # until [ "$RGB" != "7af7ee" ]; do
    #     input tap 915 470
    #     sleep 1
    #     getColor 660 520
    # done

    # TODO: Before doing all this, check if there are bounties to send heroes on
    # input tap 915 470
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # input tap 915 680
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # input tap 915 890
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # input tap 915 1100
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # input tap 915 1310
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # input swipe 550 1100 550 800 500
    # wait
    # input tap 915 960
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # input tap 915 1170
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # input tap 915 1380
    # wait
    # input tap 350 1160
    # input tap 750 1160

    input tap 780 1550 # Collect all
    sleep 1            # Fix: Sometimes goes too fast
    input tap 350 1550 # Dispatch all
    wait
    input tap 550 1500 # Confirm

    # Return to Tab if $doTeamBounties == false
    if [ "$doTeamBounties" == false ]; then
        wait
        input tap 70 1810
        wait
        verifyRGB 240 1775 d49a61 "Collected/dispatched solo bounties." "Failed to collect/dispatch solo bounties."
    else
        wait
        verifyRGB 650 1740 a7541a "Collected/dispatched solo bounties." "Failed to collect/dispatch solo bounties."
    fi
}

# Starts Team Bounties. Params: startFromTab
function teamBounties() {
    # Check if starting from tab or already inside activity
    if [ "$1" == true ]; then
        input tap 600 1320
        sleep 1
    fi
    ## For testing only! Keep as comment ##
    # input tap 600 1320
    # sleep 1
    ## End of testing ##
    input tap 910 1770
    wait

    # Check if there are bounties to collect
    # getColor 650 570
    # until [ "$RGB" != "84fff8" ]; do
    #     input tap 930 550
    #     sleep 1
    #     getColor 650 570
    # done

    # input tap 930 550
    # wait
    # input tap 350 1160
    # input tap 750 1160
    # wait
    # input tap 930 770
    # wait
    # input tap 350 1160
    # input tap 750 1160

    input tap 780 1550 # Collect all
    sleep 1            # Fix: Sometimes goes too fast
    input tap 350 1550 # Dispatch all
    wait
    input tap 550 1500 # Confirm

    wait
    input tap 70 1810

    wait
    verifyRGB 240 1775 d49a61 "Collected/dispatched team bounties." "Failed to collect/dispatch team bounties."
}

# Attempts to tap the closest Arena of Heroes opponent. Params: opponent
function tapClosestOpponent() {
    # Depending on the opponent number sent as a parameter ($1), this function
    # would attempt to check if there's an opponent above the one sent.
    # If there isn't, check the one above that one and so on until one is found.
    # When found, tap on the opponent and exit function.
    case $1 in
    1)
        # Refresh
        input tap 815 540
        sleep 2

        # Attempt to fight $arenaHeroesOpponent opponent, and if not present, skip battle
        case $arenaHeroesOpponent in
        1)
            # Check if opponent 1 exists and fight if true
            getColor 820 700
            if [ "$RGB" == "a7f1b7" ]; then input tap 820 700; else return 1; fi
            ;;
        2)
            # Check if opponent 2 exists and fight if true
            getColor 820 870
            if [ "$RGB" == "2daab4" ] || [ "$RGB" == "aff3c0" ]; then input tap 820 870; else return 1; fi
            ;;
        3)
            # Check if opponent 3 exists and fight if true
            getColor 820 1050
            if [ "$RGB" == "a7f1b7" ]; then input tap 820 1050; else return 1; fi
            ;;
        4)
            # Check if opponent 4 exists and fight if true
            getColor 820 1220
            if [ "$RGB" == "2daab4" ] || [ "$RGB" == "aff3c0" ]; then input tap 820 1220; else return 1; fi
            ;;
        5)
            # Check if opponent 5 exists and fight if true
            getColor 820 1400
            if [ "$RGB" == "aaf2bb" ]; then input tap 820 1400; else return 1; fi
            ;;
        esac
        ;;
    2)
        # Check if opponent 1 exists
        getColor 820 700
        if [ "$RGB" == "a7f1b7" ]; then
            # Fight opponent
            input tap 820 700
        else
            # Try to fight the closest opponent to 2
            tapClosestOpponent 1
        fi
        ;;
    3)
        # Check if opponent 2 exists
        getColor 820 870
        if [ "$RGB" == "2daab4" ] || [ "$RGB" == "aff3c0" ]; then
            # Fight opponent
            input tap 820 870
        else
            # Try to fight the closest opponent to 3
            tapClosestOpponent 2
        fi
        ;;
    4)
        # Check if opponent 3 exists
        getColor 820 1050
        if [ "$RGB" == "a7f1b7" ]; then
            # Fight opponent
            input tap 820 1050
        else
            # Try to fight the closest opponent to 4
            tapClosestOpponent 3
        fi
        ;;
    5)
        # Check if opponent 4 exists
        getColor 820 1220
        if [ "$RGB" == "2daab4" ] || [ "$RGB" == "aff3c0" ]; then
            # Fight opponent
            input tap 820 1220
        else
            # Try to fight the closest opponent to 5
            tapClosestOpponent 4
        fi
        ;;
    esac
}

# Does the daily arena of heroes battles
function arenaOfHeroes() {
    input tap 740 1050
    sleep 3
    if [ "$pvpEvent" == false ]; then
        input tap 550 450
    else
        input tap 550 900
    fi
    sleep 3
    input tap 1000 1800
    wait
    input tap 980 410
    sleep 2
    input tap 540 1800
    sleep 2

    # Check for new season
    getColor 200 1800
    if [ "$RGB" != "382314" ] && [ "$RGB" != "382214" ]; then
        # Repeat a battle for as long as totalAmountArenaTries
        local COUNT=0
        until [ "$COUNT" -ge "$totalAmountArenaTries" ]; do
            # Refresh
            # input tap 815 540
            # wait

            # Fight specific opponent
            #                                Free         x1
            #  Opponent 1: 820 700      ->        a7f1b7
            #  Opponent 2: 820 870      ->  2eaab4      aff3c0
            #  Opponent 3: 820 1050     ->        a7f1b7
            #  Opponent 4: 820 1220     ->  2daab4      aff3c0
            #  Opponent 5: 820 1400     ->        aaf2bb
            case $arenaHeroesOpponent in
            1)
                # Check if opponent exists
                getColor 820 700
                if [ "$RGB" == "a7f1b7" ]; then
                    # Fight opponent
                    input tap 820 700
                else
                    # Refresh opponents and try to fight opponent $arenaHeroesOpponent
                    tapClosestOpponent 1
                fi
                ;;
            2)
                # Check if opponent exists
                getColor 820 870
                if [ "$RGB" == "2daab4" ] || [ "$RGB" == "aff3c0" ]; then
                    # Fight opponent
                    input tap 820 870
                else
                    # Try to fight the closest opponent to 2
                    tapClosestOpponent 2
                fi
                ;;
            3)
                # Check if opponent exists
                getColor 820 1050
                if [ "$RGB" == "a7f1b7" ]; then
                    # Fight opponent
                    input tap 820 1050
                else
                    # Try to fight the closest opponent to 3
                    tapClosestOpponent 3
                fi
                ;;
            4)
                # Check if opponent exists
                getColor 820 1220
                if [ "$RGB" == "2daab4" ] || [ "$RGB" == "aff3c0" ]; then
                    # Fight opponent
                    input tap 820 1220
                else
                    # Try to fight the closest opponent to 4
                    tapClosestOpponent 4
                fi
                ;;
            5)
                # Check if opponent exists
                getColor 820 1400
                if [ "$RGB" == "aaf2bb" ]; then
                    # Fight opponent
                    input tap 820 1400
                else
                    # Try to fight the closest opponent to 5
                    tapClosestOpponent 5
                fi
                ;;
            esac

            # Check if return value of tapClosesopponent is 0. If it is 0, then it means a battle has been found.
            if [ $? == 0 ]; then
                sleep 2
                input tap 550 1850 # Battle
                waitBattleStart
                doSkip
                waitBattleFinish 2
                if [ "$battleFailed" == false ]; then
                    input tap 550 1550 # Collect
                    sleep 2
                fi
                input tap 550 1550 # Finish battle
                sleep 3
            fi
            ((COUNT = COUNT + 1)) # Increment
        done

        input tap 1000 380
        sleep 4
    else
        echo "[WARN] Unable to fight in the Arena of Heroes because a new season is soon launching."
    fi

    # Return to Tab if $doLegendsTournament == false
    if [ "$doLegendsTournament" == false ]; then
        input tap 70 1810
        sleep 2
        input tap 70 1810
        wait
        verifyRGB 240 1775 d49a61 "Checked the Arena of Heroes out." "Failed to check the Arena of Heroes out."
    else
        input tap 70 1810
        wait
        verifyRGB 760 70 1f2d3a "Checked the Arena of Heroes out." "Failed to check the Arena of Heroes out."
    fi
}

# Does the daily Legends tournament battles. Params: startFromTab
function legendsTournament() {
    # Check if starting from tab or already inside activity
    if [ "$1" == true ]; then
        input tap 740 1050
        sleep 2
    fi
    ## For testing only! Keep as comment ##
    # input tap 740 1050
    # sleep 1
    ## End of testing ##
    if [ "$pvpEvent" == false ]; then
        input tap 550 900 # Legend's Challenger Tournament
    else
        input tap 550 1450 # Legend's Challenger Tournament
    fi
    sleep 2
    input tap 550 280 # Chest
    sleep 3
    input tap 550 1550 # Collect
    sleep 3
    input tap 1000 1800 # Record
    wait
    input tap 990 380 # Close
    wait

    # Repeat a battle for as long as totalAmountArenaTries
    local COUNT=0
    until [ "$COUNT" -ge "$totalAmountArenaTries-2" ]; do
        input tap 550 1840 # Challenge
        sleep 4
        input tap 800 1140 # Third opponent
        sleep 4
        input tap 550 1850 # Begin Battle
        sleep 4
        waitBattleStart
        doSkip
        sleep 4
        input tap 550 800 # Tap anywhere to close
        sleep 4
        ((COUNT = COUNT + 1)) # Increment
    done

    input tap 70 1810
    sleep 2
    input tap 70 1810
    wait
    verifyRGB 240 1775 d49a61 "Battled at the Legends Tournament." "Failed to battle at the Legends Tournament."
}

# Battles in King's Towers. Params: X, Y
function battleKingsTower() {
    local COUNT=0
    input tap $1 $2 # Tap chosen tower
    sleep 3

    # Check if inside tower
    getColor 550 150
    if [ "$RGB" == "1a1212" ]; then
        input tap 540 1350 # Challenge
        wait

        # Battle while less than maxKingsTowerFights & we haven't reached daily limit of 10 floors
        getColor 550 150
        while [ "$COUNT" -lt "$maxKingsTowerFights" ] && [ "$RGB" != "1a1212" ]; do
            input tap 550 1850 # Battle
            waitBattleFinish 2

            # Check if win or lose battle
            if [ "$battleFailed" == false ]; then
                input tap 550 1850 # Collect
                sleep 4

                # Tap on the top to close possible limited offer
                input tap 550 170
                sleep 2

                # TODO: Limited offers might screw this up though I'm not sure they actually spawn in here, maybe only at the main tabs
                # Tapping 550 170 might close an offer
                # Tap top of the screen to close any possible Limited Offers
                # getColor 550 150
                # if [ "$RGB" != "1a1212" ]; then # not on screen with Challenge button
                #     input tap 550 75 # Tap top of the screen to close Limited Offer
                #     wait
                #     getColor 550 150
                #     if [ "$RGB" != "1a1212" ]; then # think i remember it needs two taps to close offer
                #         input tap 550 75 # Tap top of the screen to close Limited Offer
                #         wait
                # fi

                input tap 540 1350 # Challenge
                sleep 2
            elif [ "$battleFailed" == true ]; then
                input tap 550 1720    # Try again
                ((COUNT = COUNT + 1)) # Increment
                wait
            fi

            # Check if reached daily limit / kicked us out of battle screen
            getColor 550 150
        done

        # Return from chosen tower / battle
        input tap 70 1810
        sleep 3
        getColor 550 150
        if [ "$RGB" = "1a1212" ]; then input tap 70 1810; fi # In case still in tower, exit once more
        sleep 2
    fi
}

# Battles once in the kings tower
function kingsTower() {
    input tap 500 870 # King's Tower
    sleep 5

    # Towers
    battleKingsTower 550 800  # Main Tower
    battleKingsTower 300 970  # Tower of Light
    battleKingsTower 400 1250 # The Brutal Citadel
    battleKingsTower 780 700  # The World Tree
    battleKingsTower 780 1190 # The Forsaken Necropolis
    battleKingsTower 280 500  # Celestial Sanctum
    battleKingsTower 615 1500 # Infernal Fortress

    # Exit
    input tap 70 1810
    wait
    verifyRGB 240 1775 d49a61 "Battled at the Kings Tower." "Failed to battle at the Kings Tower."
}

# Battles against Guild boss Wrizz
function guildHunts() {
    input tap 380 360
    sleep 10

    # Check for fortune chest
    getColor 380 500
    if [ "$RGB" == "8e4633" ]; then
        input tap 560 1300
        sleep 2
        input tap 540 1830
    fi
    wait

    input tap 290 860
    sleep 3

    # TODO: Make sure 2x and Auto are enabled
    # TODO: Have a variable decide if fight wrizz or not
    # Start checking for a finished Battle after 40 seconds
    # loopUntilRGB 85 420 380 ca9c5d
    # wait
    # input tap 550 800
    # input tap 550 800
    #wait

    # Wrizz
    # TODO: Check if possible to fight wrizz
    # Repeat a battle for as long as totalAmountArenaTries
    local COUNT=0
    until [ "$COUNT" -ge "$totalAmountGuildBossTries" ]; do
        # Check if its possible to fight wrizz
        # getColor 710 1840
        # if [ "$RGB" != "9de7bd" ]; then
        #     echo "Enough of wrizz! Going out."
        #     break
        # fi

        input tap 710 1840
        # TODO: I think right here should be done a check for "some resources have exceeded their maximum limit". I have ascreenshot somewhere of this.
        wait
        input tap 720 1300
        sleep 1
        input tap 550 800
        input tap 550 800
        sleep 1
        ((COUNT = COUNT + 1)) # Increment
    done

    # Soren
    input tap 970 890
    sleep 1

    getColor 715 1815
    # If Soren is open
    if [ "$RGB" == "8ae5c4" ]; then
        quickBattleGuildBosses

    # If Soren is closed
    elif [ "$canOpenSoren" == true ]; then
        getColor 580 1753

        # If soren is "openable"
        if [ "$RGB" == "fae0ac" ]; then
            input tap 550 1850
            wait
            input tap 700 1250
            sleep 1
            quickBattleGuildBosses
        fi
    fi

    # Return to Tab if $doTwistedRealmBoss == false
    if [ "$doTwistedRealmBoss" == false ]; then
        input tap 70 1810
        sleep 3
        input tap 70 1810
        sleep 3
        verifyRGB 20 1775 d49a61 "Battled Wrizz and possibly Soren." "Failed to battle Wrizz and possibly Soren."
    else
        input tap 70 1810
        sleep 2
        verifyRGB 70 1000 a9a95f "Battled Wrizz and possibly Soren." "Failed to battle Wrizz and possibly Soren."
    fi
}

# Battles against the Twisted Realm Boss. Params: startFromTab
function twistedRealmBoss() {
    # TODO: Choose if 2x or not
    # TODO: Choose a formation (Would be dope!)
    # Check if starting from tab or already inside activity
    if [ "$1" == true ]; then
        input tap 380 360
        sleep 10
    fi
    ## For testing only! Keep as comment ##
    # input tap 380 360
    # sleep 10
    ## End of testing ##

    input tap 820 820
    sleep 2

    # Check if TR is being calculated
    getColor 540 1220
    if [ "$RGB" == "9aedc1" ]; then
        echo "[WARN] Unable to fight in the Twisted Realm because it's being calculated."
    else
        input tap 550 1850 # Twisted Realm
        sleep 2
        input tap 550 1850 # Challenge
        waitBattleStart
        doAuto
        doSpeed

        # Start checking for a finished Battle after 40 seconds
        loopUntilRGB 30 420 380 ca9c5d

        sleep 1
        input tap 550 800
        sleep 3
        input tap 550 800
        wait
        # TODO: Repeat battle if variable says so
    fi

    input tap 70 1810
    wait
    input tap 70 1810
    sleep 1
    verifyRGB 20 1775 d49a61 "Checked Twisted Realm Boss out." "Failed to check the Twisted Realm out."
}

# Buy items from store
function buyFromStore() {
    input tap 330 1650
    sleep 3

    # Dust
    if [ "$buyStoreDust" == true ]; then
        buyStoreItem 175 1100
        wait
    fi
    # Poe Coins
    if [ "$buyStorePoeCoins" == true ]; then
        buyStoreItem 675 1690
        wait
    fi
    # Emblems
    if [ "$buyStoreEmblems" == true ]; then
        buyStoreItem 175 1690
        wait
    fi
    input tap 70 1810

    wait
    verifyRGB 20 1775 d49a61 "Visited the Store." "Failed to visit the Store."
}

# Collects
function collectQuestChests() {
    # TODO: I think right here should be done a check for "some resources have exceeded their maximum limit". I have a screenshot somewhere of this.
    input tap 960 250 # Quests
    wait

    # Collect daily Quests
    getColor 700 670
    while [ "$RGB" == "7dfff1" ]; do
        input tap 930 680
        wait
        getColor 700 670
    done

    # Collect daily Chests
    input tap 330 430 # Chest 20
    wait
    input tap 580 600 # Collect
    input tap 500 430 # Chest 40
    wait
    input tap 580 600 # Collect
    input tap 660 430 # Chest 60
    wait
    input tap 580 600 # Collect
    input tap 830 430 # Chest 80
    wait
    input tap 580 600 # Collect
    input tap 990 430 # Chest 100
    wait
    input tap 580 600 # Collect
    wait

    # Weekly quests
    input tap 650 1650 # Weeklies
    wait

    # Collect weekly Quests
    getColor 700 670
    while [ "$RGB" == "7dfff1" ]; do
        input tap 930 680
        wait
        getColor 700 670
    done

    # Collect weekly Chests
    input tap 330 430 # Chest 20
    wait
    input tap 580 600 # Collect
    input tap 500 430 # Chest 40
    wait
    input tap 580 600 # Collect
    input tap 660 430 # Chest 60
    wait
    input tap 580 600 # Collect
    input tap 830 430 # Chest 80
    wait
    input tap 580 600 # Collect
    input tap 990 430 # Chest 100
    wait
    input tap 580 600 # Collect
    wait

    # Return
    input tap 70 1650
    sleep 1
    verifyRGB 20 1775 d49a61 "Collected daily and weekly quest chests." "Failed to collect daily and weekly quest chests."
}

# Collects mail
collectMail() {
    # TODO: I think right here should be done a check for "some resources have exceeded their maximum limit". I have ascreenshot somewhere of this.
    input tap 960 630
    wait
    input tap 790 1470
    wait
    input tap 110 1850
    wait
    input tap 110 1850

    wait
    verifyRGB 20 1775 d49a61 "Collected Mail." "Failed to collect Mail."
}

# Collects Daily/Weekly/Monthly from the merchants page
function collectMerchants() {
    input tap 120 300 # Merchants
    sleep 3
    input tap 510 1820 # Merchant Ship
    sleep 2

    # Check for Special Daily Bundles
    getColor 375 940
    if [ "$RGB" != "0b080a" ]; then
        input tap 200 1200
    else
        input tap 200 750
    fi
    sleep 1
    input tap 550 300 # Collect rewards
    sleep 1
    input tap 280 1620 # Weekly Deals
    sleep 1

    # Check for Special Weekly Bundles
    getColor 375 940
    if [ "$RGB" != "050a0f" ]; then
        input tap 200 1200
    else
        input tap 200 750
    fi
    sleep 1
    input tap 550 300 # Collect rewards
    sleep 1
    input tap 460 1620 # Monthly Deals
    sleep 1

    # Check for Special Monthly Bundles
    getColor 375 940
    if [ "$RGB" != "0b080a" ]; then
        input tap 200 1200
    else
        input tap 200 750
    fi
    sleep 1
    input tap 550 300 # Collect rewards
    sleep 1
    input tap 70 1810

    sleep 1
    verifyRGB 20 1775 d49a61 "Collected daily/weekly/monthly offer." "Failed to collect daily/weekly/monthly offer."
}

# If red square, strenghen Crystal
function strengthenCrystal() {
    input tap 760 1030 # Crystal
    sleep 5

    # Check if possible to buy a slot
    getColor 380 890
    if [ "$RGB" == "f5be5a" ]; then
        input tap 710 1265
        sleep 4
    fi

    # TODO Can have a special bundle window. Only happens if a player actually levels the crystal up by a level. The window is closable by tapping the very top of the screen
    input tap 550 1850 # Strenghen Crystal
    sleep 2
    input tap 200 1850 # Close level up window
    sleep 2

    input tap 70 1810
    wait
    verifyRGB 20 1775 d49a61 "Strengthened resonating Crystal." "Failed to Strenghen Resonating Crystal."
}

# Let's do a "free" summon
function nobleTavern() {
    input tap 280 1370 # The Noble Tavern
    sleep 3
    input tap 600 1820 # The noble tavern again
    sleep 1

    # Looking for heart
    getColor 875 835
    until [ "$RGB" == "f6936a" ]; do
        input tap 870 1630 # Next pannel
        sleep 1
        getColor 875 835
    done

    input tap 320 1450 # Summon
    sleep 3
    input tap 540 900 # Click on the card
    sleep 3
    input tap 70 1810 # close
    sleep 2
    input tap 550 1820 # Collect rewards
    sleep 1

    input tap 70 1810
    wait
    verifyRGB 20 1775 d49a61 "Summoned one hero with Companion Points." "Failed to summon one hero with Companion Points."
}

# Collect Oak Inn
function oakInn() {
    input tap 780 270 # Oak Inn
    sleep 5

    local COUNT=0
    until [ "$COUNT" -ge "$totalAmountOakRewards" ]; do
        input tap 1050 950 # Friends
        wait
        input tap 1025 400 # Top Friend
        sleep 5

        oakTryCollectPresent
        # If return value is still 0, no presents were found at first friend
        if [ $oakRes == 0 ]; then
            # Switch friend and search again
            input tap 1050 950 # Friends
            wait
            input tap 1025 530 # Second friend
            sleep 5

            oakTryCollectPresent
            # If return value is again 0, no presents were found at second friend
            if [ $oakRes == 0 ]; then
                # Switch friend and search again
                input tap 1050 950 # Friends
                wait
                input tap 1025 650 # Third friend
                sleep 5

                oakTryCollectPresent
                # If return value is still freaking 0, I give up
                if [ $oakRes == 0 ]; then
                    echo "[WARN] Couldn't collect Oak Inn presents, sowy."
                    break
                fi
            fi
        fi

        sleep 2
        ((COUNT = COUNT + 1)) # Increment
    done

    input tap 70 1810
    sleep 3
    input tap 70 1810

    wait
    verifyRGB 20 1775 d49a61 "Attempted to collect Oak Inn presents." "Failed to collect Oak Inn presents."
}

# Test function (X, Y, amountTimes, waitTime)
# test 550 740 3 0.5 # Check for Boss in Campaign
# test 660 520 3 0.5 # Check for Solo Bounties RGB
# test 650 570 3 0.5 # Check for Team Bounties RGB
# test 380 500 3 0.5 # Check for fortune chest collection RGG
# test 700 670 3 0.5 # Check for Quest collection RGB
# test 715 1815 3 0.5 # Check if Soren is open
# test 740 205 3 0.5 # Check if game is updating
# test 380 890 3 0.5 # Check for being able to spend coins in the crystal
# test 270 1800 3 0.5 # Oak Inn Present Tab 1
# test 410 1800 3 0.5 # Oak Inn Present Tab 2
# test 550 1800 3 0.5 # Oak Inn Present Tab 3
# test 690 1800 3 0.5 # Oak Inn Present Tab 4
# test 760 1440 3 0.5 # Auto button inside battle
# test 990 1440 3 0.5 # Speed x4 button inside battle
# test 760 1440 3 0.5 # Skip button inside battle
# test 875 835 3 0.5 # Check for companion summon

# --- Script Start --- #
echo "[INFO] Starting script... ($(date)) "

closeApp
sleep 0.5
startApp
sleep 10

# Loops until the game has launched
getColor 450 1775
while [ "$RGB" != "cc9261" ]; do
    sleep 1
    getColor 450 1775
done
sleep 1

input tap 970 380 # Open menu for friends, etc

switchTab "Campaign"
sleep 3
switchTab "Dark Forest"
sleep 1
switchTab "Ranhorn"
sleep 1
switchTab "Campaign"

# Check if game is being updated
getColor 740 205
if [ "$RGB" == "ffc359" ]; then
    echo "[WARN] Game is being updated!"
    if [ "$waitForUpdate" == true ]; then
        echo "[INFO] Waiting for game to finish update..."
        loopUntilNotRGB 5 740 205 ffc359
        echo "[OK] Game finished updating."
    else
        echo "[WARN] Not waiting for update to finish."
    fi
fi

# CAMPAIGN TAB
switchTab "Campaign"
if [ "$doLootAfkChest" == true ]; then lootAfkChest; fi
if [ "$doChallengeBoss" == true ]; then challengeBoss; fi
if [ "$doFastRewards" == true ]; then fastRewards; fi
if [ "$doCollectFriendsAndMercenaries" == true ]; then collectFriendsAndMercenaries; fi
if [ "$doLootAfkChest" == true ]; then lootAfkChest; fi

# DARK FOREST TAB
switchTab "Dark Forest"
if [ "$doSoloBounties" == true ]; then soloBounties; fi
if [ "$doTeamBounties" == true ]; then
    if [ "$doSoloBounties" == true ]; then teamBounties; else teamBounties true; fi
fi
if [ "$doArenaOfHeroes" == true ]; then arenaOfHeroes; fi
if [ "$doLegendsTournament" == true ]; then
    if [ "$doArenaOfHeroes" == true ]; then legendsTournament; else legendsTournament true; fi
fi
if [ "$doKingsTower" == true ]; then kingsTower; fi

# RANHORN TAB
switchTab "Ranhorn"
if [ "$doGuildHunts" == true ]; then guildHunts; fi
if [ "$doTwistedRealmBoss" == true ]; then
    if [ "$doGuildHunts" == true ]; then twistedRealmBoss; else twistedRealmBoss true; fi
fi
if [ "$doBuyFromStore" == true ]; then buyFromStore; fi
if [ "$doStrengthenCrystal" == true ]; then strengthenCrystal; fi
if [ "$doCompanionPointsSummon" == true ]; then nobleTavern; fi
if [ "$doCollectOakPresents" == true ]; then oakInn; fi

# END
if [ "$doCollectQuestChests" == true ]; then collectQuestChests; fi
if [ "$doCollectMail" == true ]; then collectMail; fi
if [ "$doCollectMerchantFreebies" == true ]; then collectMerchants; fi

# Ends at given location
sleep 1
checkWhereToEnd

echo
echo "[INFO] End of script! ($(date)) "
exit
