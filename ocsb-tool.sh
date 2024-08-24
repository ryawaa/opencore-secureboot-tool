#!/bin/bash
# Opencore SecureBoot Tool 0.0.1
# Author: ryanamay, inspo: profzei
echo "============================================================="
echo "OpenCore SecureBoot Tool 0.0.1 by ryanamay, inspired by profzei"
echo "https://github.com/ryanamay/opencore-secureboot-tool"
echo "============================================================="
echo ""


check_and_install() {
    local package=$1
    local command=$2
    if ! command -v $command &>/dev/null; then
        echo "INFO: $package not found, installing..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y $package
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y $package
        elif command -v pacman &>/dev/null; then
            sudo pacman -S --noconfirm $package
        else
            echo "ERROR: Unable to install $package, please install manually!"
            exit 1
        fi
    fi
}


generate_keys() {
    echo "Generating new keys..."
    rm -rf data/keys
    rm -f data/myGUID.txt
    mkdir -p data/keys

    GUID=$(python3 -c 'import uuid; print(str(uuid.uuid1()))')
    echo $GUID >data/myGUID.txt
    echo "Using Generated GUID: $GUID"

    echo -n "Enter a common name to embed in the keys: "
    read NAME

    openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=$NAME Platform Key" -keyout data/keys/PK.key -out data/keys/PK.pem
    openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=$NAME Key Exchange Key" -keyout data/keys/KEK.key -out data/keys/KEK.pem
    openssl req -new -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes -subj "/CN=$NAME Image Signing Key" -keyout data/keys/ISK.key -out data/keys/ISK.pem

    # Convert certificates and keys
    cert-to-efi-sig-list -g "$GUID" data/keys/PK.pem data/keys/PK.esl
    cert-to-efi-sig-list -g "$GUID" data/keys/KEK.pem data/keys/KEK.esl
    cert-to-efi-sig-list -g "$GUID" data/keys/ISK.pem data/keys/ISK.esl

    openssl x509 -in data/certs/MicWinProPCA2011_2011-10-19.crt -inform DER -out data/keys/MsWin.pem -outform PEM
    openssl x509 -in data/certs/MicCorUEFCA2011_2011-06-27.crt -inform DER -out data/keys/UEFI.pem -outform PEM
    cert-to-efi-sig-list -g "$GUID" data/keys/MsWin.pem data/keys/MsWin.esl
    cert-to-efi-sig-list -g "$GUID" data/keys/UEFI.pem data/keys/UEFI.esl
    cat data/keys/ISK.esl data/keys/MsWin.esl data/keys/UEFI.esl >data/keys/db.esl

    # Sign the lists
    sign-efi-sig-list -k data/keys/PK.key -c data/keys/PK.pem PK data/keys/PK.esl data/keys/PK.auth
    sign-efi-sig-list -k data/keys/PK.key -c data/keys/PK.pem KEK data/keys/KEK.esl data/keys/KEK.auth
    sign-efi-sig-list -k data/keys/KEK.key -c data/keys/KEK.pem db data/keys/db.esl data/keys/db.auth

    chmod 0600 data/keys/*.key

    echo "INFO: Keys generated successfully!"
}


download_if_not_exists() {
    local url=$1
    local output=$2
    if [ ! -f "$output" ]; then
        echo "INFO: Missing Certificate! Downloading $1..."
        curl -s -o "$output" "$url"
    fi
}


sign_efi_files() {

    if [ ! -d "EFI" ]; then
        echo "WARN: EFI folder not found. Please place your EFI folder in the same directory as this script."
        echo "Unable to sign EFI files!"
    else

        find EFI -name "*.efi" ! -name "._*.efi" -exec sh -c '
            for file; do
                echo "Signing $file..."
                sbsign --key data/keys/ISK.key --cert data/keys/ISK.pem --output "$file" "$file"
            done
        ' sh {} +

        echo "EFI files signed successfully!"
    fi
}

echo "Checking dependencies..."

if [ "$(uname)" != "Linux" ]; then
    echo "ERROR: This script is only supported on Linux."
    exit 1
fi

check_and_install efitools sbsign
check_and_install curl curl
check_and_install wget wget
check_and_install openssl openssl
check_and_install unzip unzip
check_and_install python3 python3

mkdir -p data/keys

if [ ! -f "data/keys/ISK.key" ] || [ ! -f "data/keys/ISK.pem" ] || [ ! -f "data/myGUID.txt" ]; then
    echo "Checking if certificates are present..."
    mkdir -p data/certs
    download_if_not_exists "https://www.microsoft.com/pkiops/certs/MicCorUEFCA2011_2011-06-27.crt" "data/certs/MicCorUEFCA2011_2011-06-27.crt"
    download_if_not_exists "https://www.microsoft.com/pkiops/certs/MicWinProPCA2011_2011-10-19.crt" "data/certs/MicWinProPCA2011_2011-10-19.crt"
fi

if [ ! -d "data/keytool" ]; then
    mkdir -p data/keytool
fi

if [ ! -f "data/keytool/EFI/BOOT/bootx64.efi" ]; then
    echo "INFO: Missing KeyTool! Downloading https://github.com/profzei/Matebook-X-Pro-2018/raw/master/Wiki/UEFI/KeyTool.zip..."
    wget -q https://github.com/profzei/Matebook-X-Pro-2018/raw/master/Wiki/UEFI/KeyTool.zip -O data/keytool/KeyTool.zip
    unzip -q -o data/keytool/KeyTool.zip -d data/keytool
    rm -f data/keytool/KeyTool.zip
fi

if [ -f "data/keys/ISK.key" ] && [ -f "data/keys/ISK.pem" ] && [ -f "data/myGUID.txt" ] && [ -f "data/keys/db.auth" ] && [ -f "data/keys/KEK.auth" ] && [ -f "data/keys/PK.auth" ]; then
    echo ""
    echo "Hey! It looks like you have keys ready to use!"
    echo "The current keys are located in the 'data/keys' folder."
    echo "GUID (Unique Identifier): $(cat data/myGUID.txt)"
    echo ""
    echo "Warning: Generating new keys will overwrite the existing ones in the 'data/keys' folder."
    echo -n "Do you want to use the existing keys? (y/n) [default: y]: "

    read generate_new_keys
    if [ "$generate_new_keys" == "n" ]; then
        generate_keys
    else
        echo "Keeping existing keys. Skipping key generation."
    fi
else
    echo "INFO: No existing keys found in data/keys."
    generate_keys
fi

echo "Copying keys to keytool..."

cp data/keys/db.auth data/keytool/EFI/db.auth
cp data/keys/KEK.auth data/keytool/EFI/KEK.auth
cp data/keys/PK.auth data/keytool/EFI/PK.auth

echo "Keys copied to keytool successfully!"

sign_efi_files

echo ""
echo "============================================================="
echo "Script completed!"
echo "GUID (Unique Identifier): $(cat data/myGUID.txt)"
echo "============================================================="
echo "KeyTool is ready to use!"
echo "- To use, copy the contents of the 'data/keytool' folder to a usb drive."
echo "- Your keys can be found in something like: PciRoot(0)/Pci(0x14,0x0)/Usb ... (depends on your system)"
echo "- Start with db.auth, then KEK.auth, then PK.auth"
echo "============================================================="
echo "Your keys are located in the 'data/keys' folder."
if [ -d "EFI" ]; then
    echo "Your EFI folder has been signed and ready to use."
else
    echo "Your EFI folder has not been signed. Please place your EFI folder in the same directory as this script and rerun."
fi
echo "============================================================="