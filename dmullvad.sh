#! /bin/env bash

sudo_app="sudo" # if you have configured an askpass for your sudo, you can add a "-A" here,
#                 so you dont have to only run this through the terminal

# This just kills any previously running openVPN processes
pgrep openvpn &&
     ($sudo_app -A killall openvpn
     notify-send "VPN process found. Disconnecting."
     exit 1)

# Initialize country names. If mullvad adds more new locations, you can simply
# append them to the array here. jsut make sure to add the key that links the
# country's config file to the end of the element. e.g. Arizona_az
countries=(
    "Albania_al"
    "Austrailia_au"
    "Austria_at"
    "Belgium_be"
    "Brazil_br"
    "Bulgaria_bg"
    "Canada_ca"
    "Czech_Republic_cz"
    "Denmark_dk"
    "Finland_fi"
    "France_fr"
    "Germany_de"
    "Greece_gr"
    "Hong_Kong_hk"
    "Hungary_hu"
    "Ireland_ie"
    "Israel_il"
    "Italy_it"
    "Japan_jp"
    "Latvia_lv"
    "Luxembourg_lu"
    "Moldova_md"
    "Netherlands_nl"
    "New_Zealand_nz"
    "Norway_no"
    "Poland_pl"
    "Romania_ro"
    "Serbia_rs"
    "Singapore_sg"
    "Spain_es"
    "Sweden_se"
    "Switzerland_ch"
    "UK_gb"
    "United_Arab_Emerates_ae"
    "USA_us"
)

# just to check if you have OpenVPN installed at all
[ ! -d /etc/openvpn ] &&
    (echo "OpenVPN install not found. Please install OpenVPN to use this script." && exit 1)

# just to check if you have dmenu installed as well.
which dmenu>/dev/null 2>&1 ||
    (echo "Run Launcher not found. Please install either dmenu to use this script" && exit 1)

# Set directory variables
mullvaddir="$HOME/.mullvad/"
mullvad_conf_dir="$mullvaddir/mullvad_config_linux"

# If .mullvad is not found, assume that it has not been installed yet.
if [[ ! -d $mullvaddir ]]; then

    mkdir -p $mullvaddir >/dev/null 2>&1

    # Check for if you have the zip folder for the configurations in the right place
    unzip -u $HOME/mullvad_openvpn_linux_all_all.zip -d $mullvaddir >/dev/null 2>&1 ||
        (echo "Mullvad config zip file not found. Please make sure to download
        the config zip file to your HOME folder." &&  exit 1)

    # correctly configure other various OpenVPN files
    $sudo_app mv "$mullvad_conf_dir/mullvad_userpass.txt" "$mullvaddir/.userpass.txt"
    $sudo_app mv "$mullvad_conf_dir/mullvad_ca.crt" "$mullvaddir/.ca.crt"
    $sudo_app mv "$mullvad_conf_dir/update-resolv-conf" "/etc/openvpn/update-resolv-conf"
    $sudo_app chmod 775 "/etc/openvpn/update-resolv-conf"

    # Generate the country directories
    for country in "${countries[@]}"
    do
        mkdir $mullvaddir/$country
    done

    conf_files=$(ls $mullvad_conf_dir)

    # Link each config file to the right dir, mainly using grep and awk to match the keys
    for file in $conf_files
    do
        file_abb=$(echo "$file" | awk -F "_" '{print "_"$2}')
        dir=$(ls $mullvaddir | grep "$file_abb")

        mv $mullvad_conf_dir/$file $mullvaddir/$dir
    done

    # Remove the empty config directory
    rm -rf "$mullvad_conf_dir"

else
    echo "Install complete"
    echo "OpenVPN set up. Running as per."
fi

# Pipe country choices into dmenu and set up openvpn in the background.
country=$(ls $mullvaddir | dmenu -i -p "Which country would you like to connect to?"  -c -l 20 )

conf=$(ls $mullvaddir/$country/*.conf)

ca="$mullvaddir.ca.crt"
userpass="$mullvaddir.userpass.txt"

$sudo_app openvpn --config "$conf" \
             --auth-user-pass "$userpass" \
             --ca "$ca"
