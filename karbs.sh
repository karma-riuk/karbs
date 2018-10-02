#!/bin/bash

# Karma's Auto Rice Boostrapping Script (KARBS)
# by Luke Smith <luke@lukesmith.xyz>
# License: GNU GPLv3

# You can provide a custom repository with -r or a custom programs csv with -p.
# Otherwise, the script will use my defaults.

### DEPENDENCIES: git and make . Make sure these are either in the progs.csv file or installed beforehand.

###
### FUNCTIONS ###
###


progressBar () {\
    nbar=$1
    totalbar=$2
    barLen=47
    barProg=$((barLen*$nbar/$totalbar))
    perc=$((100*$nbar/$totalbar))
    if [[ $nbar -eq $totalbar ]]; #since the barProgress bar has an empty space at
                                #the end because of printf, if progress is equal
                                #to the total, the bar is full
    then 
        bar="["$(printf '#%.0s' $(eval echo "{0..$barLen}"))"]"
    else
        bar="["$(printf '#%.0s' $(eval echo "{0..$barProg}"))$(printf " %.0s" $(eval echo "{0..$((barLen-barProg))}"))"]"
    fi
    echo "$bar $perc% ($nbar of $totalbar)"
    #sudo apt-get install $1;
}

networkName () { \
    nmcli -t -f active,ssid dev wifi | egrep '^yes' | cut -d ":" -f2
}

remoteInfoMsg() {\
    int=$(networkName)
    while ! [[ "$int" != "" ]]; do
        unset int;
        dialog --title "Internet Connection" --msgbox "KARBS detected that you do not have an internet connection, that's a problem... Please connect yourself to your local network" 10 60;
        int=$(networkName)
    done;
    dialog --title "!!! ATTENTION !!!" --yes-label "Did it!" --no-label "No, nevermind..." --yesno "\\nBefore we start, make sure that the remote machine from which you want to take the dofiles is turned on and connected to the local network \"$(networkName)\". If it is, execute the command: \\n\\n $ ssh-copy-id -i ~/.ssh/id_rsa.pub $(hostname -I | awk "{print \$1}")\\n\\nto be able to sync the configs files needed to have a read-to-use system without having to manually modify the configs"  20 60 ;
}

changePermsMsg() {\
    a=1
    dialog --title "!!! ATTENTION !!!" --yes-label "Okay, perfect, did it!" --no-label "No, nevermind..." --yesno "\\nJust one last thing you have to execute this command: \\n\\n $ sudo visudo \\n\\nIt will open a file. You have to add the line: \\n\\n $(whoami) ALL=(ALL) NOPASSWD: ALL #KARBS \\n\\nat the end of that file. That will allow KARBS to have all permissions to install every package that needs to be installed and do whatever it wants ^^"  20 60 ;
}

preinstallmsg () { \
    a=1
	dialog --title "Let's get this party started!" --yes-label "Let's go!" --no-label "No, nevermind..." --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\\n\\nIt will take some time, but when done, you can relax even more with your complete system.\\n\\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
}

aptInstall () {\
    #check if package is already installed 
    if  [[ "$(dpkg -s "$1" 2>&1 | grep "Status: install ok installed")" = "Status: install ok installed" ]]; then 
        msg="It seems that \`$1\` has already been installed.\\n\\n$1: $2 $capo$(progressBar $n $total)\\n " 
    else
        msg="Installing \`$1\`\\n\\n$1: $2 $capo$(progressBar $n $total)\\n" 
        if [[ "$(sudo apt-cache search "^$1$")" = "" ]]; then
            notFound="$notFound \n $1"
        else
            a=1 #tbd
            #sudo apt-get install $1
        fi
    fi
    dialog --title "Aptitude install" --infobox "$msg" 15 $width

}

gitInstall () {\
    ### TODO: check if you can catch if there is an error when building the gits, so that you can address it in a dialog box and tell the user to FUCK OFF AND DO IT ON IT'S OWN, THAT FUCKING RETARDED
    case "$1" in
    "i3-gaps")
        total1=$(wc -l ./i3-deps.txt)
        readyToGit="True"
        notFoundi3=""
        while read -r dep; do
            n1=$((n1+1))
            msg="Installing dependecies for \`$1\`\\n\\n$1: $2 $capo$(progressBar $n1 $total1)\\n " 
            if [[ "$(sudo apt-cache search "^$dep$")" = "" ]]; then
                notFoundi3="$notFoundi3 \n $dep"
                readyToGit="False"
            else
                a=1 #tbd
                #sudo apt-get install "$dep"
            fi

            dialog --title "Git install" --infobox "$msg" 15 $width
        done < ./i3-deps.txt;
        if [[ "$readyToGit" = "True" ]]; then
            dialog --title "Git install" --infobox "Compiling and installing \`i3-gaps\`..." 5 $width
            #git clone https://www.github.com/Airblader/i3 i3-gaps

        else
            dialog --title "Git install" --msgbox "Unfortunatelly we encountered a problem while downloading and installing the dependecies for i3-gaps. No worries. Just look at the list below and check out how to install these dependecies and then follow how to compile i3-gaps from the site.\\n\\nThe dependecies that were missing:\\n$notFoundi3 \\n\\n " 20 $width

        fi
        ;;
    "polybar") 
        total2=$(wc -l ./polybar-deps.txt)
        while read -r dependencie; do
            n2=$((n2+1))
            msg="Installing dependecies for \`$1\`\\n\\n$1: $2 $capo$(progressBar $n2 $total2)\\n " 
            #sudo apt-get install "$dependencie"
            dialog --title "Git install" --infobox "$msg" 15 $width
        done < ./polybar-deps.txt;
        #apt-get install every single dependencie
        #modify polybar build.sh :
        # comment out line 40-51 (included, both)
        # change the line 35, replace ON by OFF
        #git clone https://github.com/jaagr/polybar
        ;;
    esac
}

installationLoop () {\
    notFound=""
	total=$(cat progs.csv | grep "A," | wc -l)
	while IFS=, read -r tag program comment; do
        n=$((n+1))
        text="$program: $comment"
        lines=${#text}
        width=70
        if [[ $lines -gt $width ]]; then capo="\\n\\n\\n\\n"; else capo="\\n\\n\\n\\n\\n"; fi
        case "$tag" in
            "A") aptInstall "$program" "$comment" ;;
            "G") gitInstall "$program" "$comment" ;;
        esac
	done < ./progs.csv ;
    if ! [[ "$notFound" == "" ]]; then
        dialog --title "Packages not found on APT" --msgbox "Not found pacakges: \\n $notFound \\n\\nNothing to worry about, just check them out if they really interest you." 30 60
    fi
}
    
###
### THE ACTUAL SCRIPT ###
###
### This is how everything happens in an intuitive format and order.
###



remoteInfoMsg || { clear; exit; }

changePermsMsg || { clear; exit; } 

preinstallmsg || { clear; exit; }

installationLoop

