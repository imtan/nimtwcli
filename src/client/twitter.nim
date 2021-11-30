import dotenv
import os
import httpclient
import oauth1
import tables
import strutils
import json

let env = initDotEnv("/home/imtan/Repository/Nim/tweetcli/", ".env")
env.load()

type TwitterClient* = ref object
  apiKey: string
  consumerKey: string
  consumerSecret: string
  accessToken: string
  accessSecret: string
  uri*: string
  authorization: string
  header: string

const
  requestTokenUrl = "https://api.twitter.com/oauth/request_token"
  authorizeUrl = "https://api.twitter.com/oauth/authorize"
  accessTokenUrl = "https://api.twitter.com/oauth/access_token"
  requestUrl = "https://api.twitter.com/1.1/statuses/home_timeline.json"
  tweetUrl = "https://api.twitter.com/2/tweets"
  # tweetUrl = "https://api.twitter.com/1.1/statuses/update.json?status=pongpongpain"

# proc createNonce(): string =
#   ## Generate a nonce of 32byte.
#   let epoch = $epochTime()
#   var
#     rst = ""
#     r = 0
    
#   randomize()
#   for i in 0..(23 - len(epoch)):
#     r = rand(26)
#     rst = rst & chr(97 + r)
    
#   result = encode(rst & epoch)
  
proc newTwitterClient*(): TwitterClient =
  let v = TwitterClient(apiKey: "Bearer " & os.getEnv("TWITTER_BEARER"),
                        consumerKey: os.getEnv("TWITTER_API_KEY"),
                        consumerSecret: os.getEnv("TWITTER_API_SECRET_KEY"),
                        accessToken: os.getEnv("TWITTER_USER_ACCESS_TOKEN"),
                        accessSecret: os.getEnv("TWITTER_USER_ACCESS_SECRET"),
                        header: "application/json",
                        uri: "https://api.twitter.com/2/tweets")
  result = v

proc tweet*(twitter: TwitterClient, tweet: string) : Response =
  let 
    twit = %* { "text": tweet }
    client = newHttpClient()
  client.headers = newHttpHeaders({ "Content-Type": "application/json" })
  result = client.oAuth1Request(tweetUrl, twitter.consumerKey, twitter.consumerSecret,
                       twitter.accessToken, twitter.accessSecret,
                       isIncludeVersionToHeader = true, httpMethod = HttpPOST, extraHeaders = client.headers, body= $twit)

proc getTimeline*(twitter: TwitterClient) : string =
  let
    client = newHttpClient()
    timeline = client.oAuth1Request(requestUrl, twitter.consumerKey, twitter.consumerSecret,
                                  twitter.accessToken, twitter.accessSecret, isIncludeVersionToHeader = true)
  echo timeline.body
  

proc auth*(twitter: TwitterClient) : string =
  let client = newHttpClient()
  client.headers = newHttpHeaders({ "Content-Type": "application/json", "Authorization": twitter.apiKey })
  twitter.uri = "https://api.twitter.com/oauth/authorize"
  result = client.getContent(twitter.uri)

proc parseResponseBody(body: string): Table[string, string] =
  let responses = body.split("&")
  result = initTable[string, string]()
  for response in responses:
    let r = response.split("=")
    result[r[0]] = r[1]

proc twitterOAuth*(twitter: TwitterClient) : array[2, string] =
  let client = newHttpClient()
  let requestToken = client.getOAuth1RequestToken("https://api.twitter.com/oauth/request_token",
                               twitter.consumerKey,
                               twitter.consumerSecret,
                               isIncludeVersionToHeader = true)
  if requestToken.status == "200 OK":
    var response = parseResponseBody requestToken.body
    let
      requestToken = response["oauth_token"]
      requestTokenSecret = response["oauth_token_secret"]
    echo "Access the url, please obtain the verifier key."
    echo getAuthorizeUrl(authorizeUrl, requestToken)
    echo "Please enter a verifier key (PIN code)."
    let
      verifier = readLine stdin
      accessToken = client.getOAuth1AccessToken(accessTokenUrl,
                                                twitter.consumerKey, twitter.consumerSecret, requestToken, requestTokenSecret,
                                                verifier, isIncludeVersionToHeader = true)
    if accessToken.status == "200 OK":
      response = parseResponseBody accessToken.body
      let
        accessToken = response["oauth_token"]
        accessTokenSecret = response["oauth_token_secret"]
      result = [accessToken, accessTokenSecret]
