# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import client/twitter
import os

when isMainModule:
  let v = newTwitterClient()
  # echo v.twitterOAuth()
  echo v.tweet($os.commandLineParams()[0]).status
  
