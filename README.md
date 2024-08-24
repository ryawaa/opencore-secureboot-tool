# OpenCore SecureBoot Tool

A bash script designed to make it easier for you to enable UEFI Secure Boot for OpenCore. 

### Features

- **Automated Key Generation**: Generates new secure boot keys with user-defined common names.
- **Certificate Management**: Downloads necessary Microsoft certificates if not present.
- **EFI Signing**: Signs all `.efi` files in the provided EFI directory using the generated keys.
- **KeyTool Preparation**: Prepares KeyTool for use with the generated keys and provides guidance on its usage.

### Prerequisites

The script requires the following dependencies:

- `efitools`
- `sbsign`
- `curl`
- `wget`
- `openssl`
- `unzip`
- `python3`

The script will attempt to install any missing dependencies using your system's package manager (`apt-get`, `dnf`, or `pacman`).

### Usage

> [!IMPORTANT]
> In order to sign your EFI files, you must have your `EFI` folder in the same directory as the script. The script will sign and override all `.efi` files in this folder.

> [!NOTE]
> The Microsoft Certificates and KeyTool is provided in this repository by default. If you do not wish to use these, you can provide your own Microsoft certificates and KeyTool or delete them so they could be downloaded from the internet.

- **Clone the repository and run the script**:
    ```bash
    git clone https://github.com/ryanamay/opencore-secureboot-tool.git
    cd opencore-secureboot-tool
    chmod +x ocsb-tool.sh
    ./ocsb-tool.sh
    ```

### Outputs

- Generated keys are stored in the `data/keys` directory.
- Signed EFI files are in your provided `EFI` folder.
- Preconfigured KeyTool is in the `data/keytool` directory.

### Notes

- **GUID**: A unique identifier (GUID) is generated during the key creation process and stored in `data/myGUID.txt`.
- **Key Overwriting**: Be cautious when generating new keys, as it will overwrite any existing keys in the `data/keys` directory.

### License

This script is licensed under the Apache License 2.0. See the [LICENSE](./LICENSE) file for details.

OpenCore is licensed under the BSD-3-Clause License. See the [OpenCore License](https://github.com/acidanthera/OpenCorePkg/blob/master/LICENSE.txt) for details.

This script is based on the guide and tools from the Matebook-X-Pro-2018 repository, which is licensed under the Apache License 2.0. For more information, visit [Matebook-X-Pro-2018 Wiki](https://github.com/profzei/Matebook-X-Pro-2018/wiki/Enable-BIOS-Secure-Boot-with-OpenCore).


### Credits
- [Microsoft Windows Production CA 2011](http://go.microsoft.com/fwlink/?LinkID=321192)
- [Microsoft UEFI Driver Signing CA](http://go.microsoft.com/fwlink/?LinkId=321194)
- [profzei's UEFI Guide](https://github.com/profzei/Matebook-X-Pro-2018/wiki/Enable-BIOS-Secure-Boot-with-OpenCore)