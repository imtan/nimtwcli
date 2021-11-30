# Package

version       = "0.1.0"
author        = "imtan"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["tweetcli"]
binDir        = "bin"


# Dependencies

requires "nim >= 1.4.8, oauth, dotenv"
