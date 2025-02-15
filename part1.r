## ----set-options, echo=FALSE, cache=FALSE-------------------------------------
options(width = 10000)


## ---- include=FALSE, warning=FALSE, message=FALSE-----------------------------
knitr::opts_chunk$set(echo = TRUE, warning=FALSE, message=FALSE)
library(tidyverse)
library(tidytext)
library(textdata)
library(wordcloud)
library(dplyr)
library(rtweet)
library(stringr)
library(pander)
library(vistime)
library(scales)
library(lubridate)
library(datetime)
library(plotly)


## -----------------------------------------------------------------------------
cf <- readRDS("data/campfire-tweets-2020-04-27.Rds")

first_morning <- filter(cf, created_at_pst < "2018-11-08 12:00:00")

first_morning <- filter(first_morning, created_at_pst > "2018-11-08 06:51:46")

# first_morning <- cf %>% filter(created_at_pst < "2018-11-08 12:00:00") %>%
#   filter(created_at_pst > "2018-11-08 06:51:46")

names <- c("CALFIRE_ButteCo", "Cal_Fire", "ButteSheriff", "ChicoPolice", "ChicoFD", "CountyOfButte", "Paradise_CA", "PGE4Me")


first_morning$media <- ifelse(first_morning$screen_name %in% names, "Media", "Public")
first_morning$media <- as.factor(first_morning$media)



#Refine data
first_morningMedia <- first_morning %>%
  filter(media=="Media")

first_morningPublic <- first_morning %>%
   filter(media=="Public") %>%
   filter(str_detect(text, "fire|campfire|sheriff|calfire|CALFIRE|Sheriff")) %>%
   filter(str_detect(text, "concow|butte|paradise|magalia|sheriff|CALFIRE")) %>%
   filter(str_detect(text, "RT", negate=TRUE)) %>%
   filter(str_detect(text, "#Autunno", negate=TRUE))

first_morning <- rbind(first_morningMedia, first_morningPublic)



graph3 <- first_morning %>% 
  filter(media == "Media") %>%
  filter(tweet_min < "2018-11-08 16:00:00") %>%
    group_by(screen_name, tweet_hour) %>%
  summarize(tweet_count=n()) %>%
   ggplot(aes(x=tweet_hour, y=tweet_count, color=screen_name)) + geom_line(size=1) +
   labs(x="Time", y="Total Tweets", title="First Response of Local Media")

graph3



first_morning %>% 
  group_by(tweet_hour) %>%
  summarize(tweet_count=n()) %>%
  ggplot(aes(x=tweet_hour, y=tweet_count)) + geom_line()  + 
   labs(x="Time", y="Total Tweets", title="Total Tweets ")


## -----------------------------------------------------------------------------

graph4 <- first_morning %>% 
  filter(media == "Public") %>%
  filter(tweet_min < "2018-11-08 20:00:00") %>%
  group_by(tweet_hour, is_retweet) %>%
  summarize(tweet_count=n()) %>%
  ggplot(aes(x=tweet_hour, y=tweet_count, fill=is_retweet)) + geom_col()  + 
   labs(x="Time", y="Total Tweets", title="Public Response")

graph4


## -----------------------------------------------------------------------------
#Public Tweets that Retweeted Our Main Accounts
 first_morning %>% 
  filter(media == "Public") %>%
   filter(tweet_min < "2018-11-09 00:00:00") %>%
   filter(retweet_screen_name %in% names) %>%
  group_by(tweet_hour) %>%
  summarize(tweet_count=n()) %>%
  ggplot(aes(x=tweet_hour, y=tweet_count)) + geom_col(fill = "#00AFBB") +
   labs( y="Total Tweets", title="Public Retweets of Local Media Accounts")

colnames(first_morning)[colnames(first_morning) == "screen_name"] <- "User"

media_time <- first_morning %>%
  filter(media=="Media") %>%
  group_by(User) %>%
  summarize("Time of First Tweet" = min(created_at_pst)) 

media_time
colnames(first_morning)[colnames(first_morning) == "User"] <- "screen_name"

par(mfrow=c(2,1))
graph3
media_time
#grid.arrange(graph3, media_time, ncol=2)

overall_time <- first_morning %>% 
  summarize("Time of First Tweet" = min(created_at_pst)) %>%
  pander()


graph1 <- ggplot(first_morning, aes(x=media, fill=media)) + geom_bar() +
  theme(legend.position = "none") + xlab("Tweets") + ylab("") + 
  geom_text(stat="count", aes(label=..count..),  vjust=-1) + ylim(0,440)
graph1

graph2 <- first_morning %>% 
    group_by(tweet_hour) %>%
  summarize(tweet_count=n()) %>%
   ggplot(aes(x=tweet_hour, y=tweet_count, color="#00AFBB")) + geom_line(size=1) +
   labs(x="Time", y="Total Tweets", title="First 6 Hours of Tweets") + 
  theme(legend.position = "none")
graph2



## -----------------------------------------------------------------------------
Sources <- first_morning %>%
   filter(media=="Media")

plot.fav  <- Sources %>% filter(favorite_count>1) %>% ggplot(aes(x=favorite_count, fill=screen_name)) + geom_histogram()
plot.rt  <- Sources %>% filter(retweet_count>1) %>% ggplot(aes(x=retweet_count, fill=screen_name)) + geom_histogram()
plot.quo  <- Sources %>% filter(quote_count>1) %>% ggplot(aes(x=quote_count, fill=screen_name)) + geom_histogram()
plot.rply  <- Sources %>% filter(reply_count>1) %>% ggplot(aes(x=reply_count, fill=screen_name)) + geom_histogram()

gridExtra::grid.arrange(plot.fav, plot.rt, plot.quo, plot.rply, nrow=2)


## -----------------------------------------------------------------------------

first_morning$text <- gsub("(\\. )", "\\.\n", first_morning$text)
first_morning$text <- gsub("(^\\#)", "\n\\#", first_morning$text)
first_morning$text <- gsub("(^\\@)", "\n\\@", first_morning$text)
first_morning$text <- gsub("(\\: )+", "\\:\n", first_morning$text)
first_morning$text <- gsub("(http)", "\nhttp", first_morning$text)


created_at_pst <- as.POSIXct(c("2018-11-08 6:29:00", "2018-11-08 6:33:00", "2018-11-08 6:44:00", 
                 "2018-11-08 6:51:00", "2018-11-08 7:00:00", "2018-11-08 7:17:00", 
                 "2018-11-08 7:23:00", "2018-11-08 7:46:00", "2018-11-08 7:59:00", 
                 "2018-11-08 8:03:00", "2018-11-08 8:07:00", "2018-11-08 8:15:00",
                 "2018-11-08 10:45:00"))

text <- c("Camp Fire Starts", "PG&E field crew reports fire under power transmission lines near Poe Dam to Cal Fire", "Captain Matt McKenzie radios for resources and evacuations", "Fire reaches 10 acres", "Fire enters Concow", "Cal Fire begins sending in firefighters", "Evacuation Order given for entire town of Pulga", "A state fire captain calls for an evacuation order for the eastern side of Paradise", "Fire enters Paradise", "Evacuation Order given to the eastern half of Paradise, including all of Pentz Road", "A fallen tree blocks Hoffman Road, Concow main escape route, trapping a state fire crew and 20 residents. Eight die as the fire passes over them.", "Flames are reported at Feather River Hospital. Staff begins to evacuate patients.", "NASA photo shows 20,000 acres burned")


day_events <- data.frame(text, created_at_pst)
day_events$screen_name <- "Events in Real Time"

timeline_data <- first_morning %>%
  filter(media=="Media") %>%
  filter(is.na(reply_to_status_id))
timeline_data <- filter(timeline_data, is_retweet==FALSE)
timeline_data <- timeline_data[,c("text", "created_at_pst", "screen_name")]
timeline_dat <- rbind(timeline_data, day_events)
timeline_dat$color <- "#00AFBB"
time <- (vistime(timeline_dat, events = "text", start = "created_at_pst", groups="screen_name", show_labels=FALSE, title="Timeline of Events"))

day_timeline <- plotly_build(time)

m <- list(
    l = 50,
    r = 50,
    b = 100,
    t = 100,
    pad = 4
)

plot1 <- day_timeline %>%
  layout(autosize = T, width=950, margin = m)
plot1


## -----------------------------------------------------------------------------
timeline_data <- first_morning %>%
  filter(media=="Media") %>%
  filter(is.na(reply_to_status_id))
timeline_data <- timeline_data[,c("text", "created_at_pst", "screen_name", "media", "is_retweet")]

timeline_data2 <- first_morning %>%
  filter(media=="Public")
 # timeline_data2 <- first_morning %>%
 #   filter(media=="Public") %>%
 #   filter(str_detect(text, "fire|campfire|sheriff|calfire|CALFIRE|Sheriff")) %>%
 #   filter(str_detect(text, "concow|butte|paradise|magalia|sheriff|CALFIRE")) %>%
 #   filter(str_detect(text, "RT", negate=TRUE))
 # 


timeline_data2 <- timeline_data2[,c("text", "created_at_pst", "screen_name", "media", "is_retweet")]
timeline_data2 <- filter(timeline_data2, created_at_pst < "2018-11-09 00:00:00")

timeline_data2 <- filter(timeline_data2, is_retweet=="FALSE")
timeline_data2 <- rbind(timeline_data2, timeline_data)

timeline_data2 <- filter(timeline_data2, created_at_pst < "2018-11-08 10:00:00")
timeline_data2$color <- "#00AFBB"

# timeline_data2$text <- gsub("(\\. )", "\\.\n", timeline_data2$text)
# timeline_data2$text <- gsub("(^\\#)", "\n\\#", timeline_data2$text)
# timeline_data2$text <- gsub("(^\\@)", "\n\\@", timeline_data2$text)
# timeline_data2$text <- gsub("(\\: )+", "\\:\n", timeline_data2$text)
# timeline_data2$text <- gsub("(http)", "\nhttp", timeline_data2$text)

time2 <- (vistime(timeline_data2, events = "text", start = "created_at_pst", groups="media", show_labels=FALSE, title="Public vs Media Timeline of Tweets"))

day_timeline2 <- plotly_build(time2)

m <- list(
    l = 50,
    r = 50,
    b = 100,
    t = 100,
    pad = 4
)

plot2 <- day_timeline2 %>%
  layout(autosize = T, width = 950, margin = m)
plot2


## -----------------------------------------------------------------------------




## -----------------------------------------------------------------------------
news <- cf %>%
  filter(str_detect(screen_name,"news|News") | str_detect(description, "news|News")) %>%
  filter(verified=="TRUE")

news_orgs <- cf %>%
  users_data() %>%
  distinct(screen_name, .keep_all = TRUE) %>%
  filter(str_detect(screen_name, "news|News") | str_detect(description, "news|News")) %>%
  filter(verified=="TRUE") %>%
  arrange(desc(followers_count)) 

news$user_type <- "news"
public <- anti_join(x = cf, y = news_orgs, by = "screen_name")
public$user_type <- "public"

cf <- rbind(public, news)


top.20.users <- news %>% 
  group_by(screen_name) %>% 
  summarise(n=n()) %>% 
  arrange(desc(n)) %>% 
  slice(1:20)

ggplot(top.20.users, aes(x = reorder(screen_name, -n), y=n)) +
  geom_bar(stat="identity", fill="darkslategray")+
  theme_minimal() + coord_flip() + 
  xlab("Users") + ylab("Count")

