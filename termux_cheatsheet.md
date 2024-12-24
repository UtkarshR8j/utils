# Termux Cheatsheet

## **Package Management**
| Command                         | Functionality                               |
|---------------------------------|-------------------------------------------|
| `apt update`                    | Update package lists                      |
| `apt upgrade`                   | Upgrade installed packages                |
| `apt install [package]`         | Install a package                         |
| `apt remove [package]`          | Remove a package                          |
| `pkg install [package]`         | Shortcut for installing a package         |
| `pkg upgrade`                   | Upgrade installed packages (shortcut)     |
| `pkg uninstall [package]`       | Uninstall a package (shortcut)            |
| `pkg list`                      | List installed packages                   |
| `pkg search [keyword]`          | Search for packages                       |
| `pkg info [package]`            | Display information about a package       |

---

## **File and URL Operations**
| Command                         | Functionality                               |
|---------------------------------|-------------------------------------------|
| `termux-open [file]`            | Open a file with the default application   |
| `termux-open-url [URL]`         | Open a URL with the default application    |
| `termux-share [file]`           | Share a file using Android’s share menu    |

---

## **Device Operations**
| Command                         | Functionality                               |
|---------------------------------|-------------------------------------------|
| `termux-vibrate [time(ms)]`     | Vibrate the device for the specified duration |
| `termux-toast [message]`        | Display a toast message                    |
| `termux-wake-lock`              | Prevent the device from sleeping           |
| `termux-wake-unlock`            | Allow the device to sleep                  |
| `termux-wifi-enable`            | Enable Wi-Fi                               |
| `termux-wifi-disable`           | Disable Wi-Fi                              |
| `termux-battery-status`         | Display battery status                     |

---

## **Utility Commands**
| Command                         | Functionality                               |
|---------------------------------|-------------------------------------------|
| `termux-camera-photo`           | Take a photo with the device’s camera      |
| `termux-contact-list`           | Display a list of contacts                 |
| `termux-sms-list`               | Display a list of SMS messages             |
| `termux-sms-send [number] [message]` | Send an SMS message                  |
| `termux-tts-speak [text]`       | Speak the provided text using text-to-speech |
| `termux-clipboard-get`          | Retrieve contents of the clipboard         |
| `termux-clipboard-set [text]`   | Set the clipboard contents                 |
| `termux-dialog`                 | Display various dialog boxes               |
| `termux-notification`           | Show a notification                        |
