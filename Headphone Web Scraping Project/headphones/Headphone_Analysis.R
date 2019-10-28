library(stringr)
library(dplyr)
library(ggthemes)
library(tm)
library(topicmodels)
library(SnowballC)
#library(beepr)

rm(list = ls())

setwd("~/Headphone Web Scraping Project/headphones")

#### HEADPHONE DESCRIPTION DATA

headphone_data = read.csv("Headphone.csv", stringsAsFactors = FALSE)
headphone_data$review_score[headphone_data$review_score == 0] = NA
headphone_data$views = gsub("K","000", headphone_data$views)
headphone_data$views = as.numeric(headphone_data$views)

headphone_description_data = read.csv("HeadphoneDescription.csv", stringsAsFactors = FALSE)
headphone_description_data$review_score[headphone_description_data$review_score == 0] = NA
headphone_description_data$views = gsub("K","000", headphone_description_data$views)
headphone_description_data$views = as.numeric(headphone_description_data$views)

textcleaning <- function(input_vector, delete_punctuation = FALSE){
  output_vector = iconv(input_vector, "latin1", "ASCII", sub="")
  output_vector = gsub(" ?(f|ht)tp(s?)://(.*)[.][a-z]+"," ", output_vector)
  if (delete_punctuation == TRUE){
    
    output_vector = gsub("&", "", output_vector)
    output_vector = gsub("-", "", output_vector)
  }
  output_vector = gsub("[^[:alnum:]]", " ", output_vector)
  output_vector = str_replace(gsub("\\s+", " ", str_trim(output_vector)), "B", "b")
  output_vector = tolower(output_vector)
  return(output_vector)
}


headphone_description_data$title = textcleaning(headphone_description_data$title, delete_punctuation = TRUE)
headphone_data$title = textcleaning(headphone_data$title, delete_punctuation = TRUE)

headphone_description_data$description_text = textcleaning(headphone_description_data$description_text)


setup_dtm <- function(input_vector, names_vector){
  new_vector = as.vector(t(input_vector))
  docs = Corpus(VectorSource(new_vector))
  
  docs <- tm_map(docs, removeWords, stopwords("english"))
  docs <- tm_map(docs, removeWords, "sound")
  docs <- tm_map(docs, stemDocument)
  docs <- tm_map(docs, removeWords, "headphon")
  docs <- tm_map(docs, removeWords, "audio")
  docs <- tm_map(docs, stripWhitespace)
  docs <- tm_map(docs, removeNumbers)
  
  dtm <- DocumentTermMatrix(docs)
  
  rownames(dtm) <- as.vector(names_vector)
  rowTotals <- apply(dtm , 1, sum)
  dtm   <- dtm[rowTotals> 0, ]   
  return(dtm)
}

dtm = setup_dtm(headphone_description_data$description_text, headphone_description_data$title)

freq <- colSums(as.matrix(dtm))
length(freq)
ord <- order(freq,decreasing=TRUE)
freq[ord]

k<-10
burnin <- 60
iter <- 2000
thin <- 2000
seed <-list(2003,5,63,100001,765)
nstart <- 5
ldaOut<-LDA(dtm,k,method="Gibbs", control=list(burnin = burnin, iter = iter, thin=thin, verbose = 1))
ldaOut.terms <-as.matrix(terms(ldaOut,10))
ldaOut.terms

ldaOut.topics<-as.data.frame(ldaOut@gamma)
ldaOut.topics$title = rownames(dtm)

headphone_description_merged = merge(headphone_description_data, ldaOut.topics, by=c("title"))
headphone_description_merged = merge(headphone_data, headphone_description_merged, by=c("title", "user_name", "views"))

hist(headphone_description_merged$review_score.y)
cor(headphone_description_merged$review_score.y, headphone_description_merged$V1, use = "pairwise.complete.obs") 
headphone_description_merged$is_reviewed = as.numeric(!(is.na(headphone_description_merged$review_score.y)))

cor(headphone_description_merged$is_reviewed, headphone_description_merged[c(12:21)], use = "pairwise.complete.obs") 
cor(headphone_description_merged$review_score.y, headphone_description_merged[c(12:21)], use = "pairwise.complete.obs") 

headphone_description_merged$word_count = sapply(headphone_description_merged$description_text.y, function(x) length(unlist(strsplit(as.character(x), "\\W+"))))
cor(headphone_description_merged$is_reviewed, headphone_description_merged$word_count, use = "pairwise.complete.obs") 

headphone_description_merged$brand =  word(headphone_description_merged$title, 1)

rm(headphone_data)
rm(headphone_description_data)

headphone_summary_data = headphone_description_merged %>%
  filter(!is.na(review_score.y)) %>%
  group_by(brand) %>%
  mutate(n_brand = n()) %>%
  group_by(brand, n_brand) %>%
  summarise_all(list(mean, var)) %>%
  filter(n_brand >= 40 | brand == "bose" | brand == "beats" | brand == "apple") %>%
  mutate(max_value = pmax(V1_fn1, V1_fn2, V3_fn1, V4_fn1, V5_fn1, V6_fn1, V7_fn1, V8_fn1, V9_fn1, V10_fn1)) %>%
  mutate(largest_brand = case_when(
    max_value == V1_fn1 ~ "Topic 1",
    max_value == V2_fn1 ~ "Topic 2",
    max_value == V3_fn1 ~ "Topic 3",
    max_value == V4_fn1 ~ "Topic 4",
    max_value == V5_fn1 ~ "Topic 5",
    max_value == V6_fn1 ~ "Topic 6",
    max_value == V7_fn1 ~ "Topic 7",
    max_value == V8_fn1 ~ "Topic 8",
    max_value == V9_fn1 ~ "Topic 9",
    max_value == V10_fn1 ~ "Topic 10",
    TRUE ~ "N/A"
  )) %>%
  select(brand, largest_brand)


headphone_summary_data2 = headphone_description_merged %>%
  filter(!is.na(review_score.y)) %>%
  group_by(brand) %>%
  mutate(n_brand = n()) %>%
  group_by(brand, n_brand) %>%
  summarise_all(list(mean, var)) %>%
  filter(n_brand >= 2) %>%
  mutate(max_value = pmax(V1_fn1, V1_fn2, V3_fn1, V4_fn1, V5_fn1, V6_fn1, V7_fn1, V8_fn1, V9_fn1, V10_fn1)) %>%
  mutate(largest_brand = case_when(
    max_value == V1_fn1 ~ "Topic 1",
    max_value == V2_fn1 ~ "Topic 2",
    max_value == V3_fn1 ~ "Topic 3",
    max_value == V4_fn1 ~ "Topic 4",
    max_value == V5_fn1 ~ "Topic 5",
    max_value == V6_fn1 ~ "Topic 6",
    max_value == V7_fn1 ~ "Topic 7",
    max_value == V8_fn1 ~ "Topic 8",
    max_value == V9_fn1 ~ "Topic 9",
    max_value == V10_fn1 ~ "Topic 10",
    TRUE ~ "N/A"
  ))

#### HEADPHONE REVIEW DATA
headphone_review_data = read.csv("HeadphoneReview.csv", stringsAsFactors = FALSE)
headphone_review_data$review_title = make.unique(headphone_review_data$review_title, sep = " ")
headphone_review_data$pros_text = textcleaning(headphone_review_data$pros_text)
headphone_review_data$cons_text = textcleaning(headphone_review_data$cons_text)
headphone_review_data$remaining_text = textcleaning(headphone_review_data$remaining_text)

dtm1 = setup_dtm(headphone_review_data$pros_text, headphone_review_data$review_title)
dtm2 = setup_dtm(headphone_review_data$cons_text, headphone_review_data$review_title)
dtm3 = setup_dtm(headphone_review_data$remaining_text, headphone_review_data$review_title)

freq <- colSums(as.matrix(dtm1))
length(freq)
ord <- order(freq,decreasing=TRUE)
freq[ord]

freq <- colSums(as.matrix(dtm2))
length(freq)
ord <- order(freq,decreasing=TRUE)
freq[ord]

freq <- colSums(as.matrix(dtm3))
length(freq)
ord <- order(freq,decreasing=TRUE)
freq[ord]

k<-10
burnin <- 60
iter <- 2000
thin <- 2000
seed <-list(2003,5,63,100001,765)
nstart <- 5

ldaOut1<-LDA(dtm1,k,method="Gibbs", control=list(burnin = burnin, iter = iter, thin=thin, verbose = 1))
ldaOut1.terms <-as.matrix(terms(ldaOut1,10))
ldaOut1.terms

ldaOut1.topics<-as.data.frame(ldaOut1@gamma)
ldaOut1.topics$title = rownames(dtm1)

ldaOut2<-LDA(dtm2,k,method="Gibbs", control=list(burnin = burnin, iter = iter, thin=thin, verbose = 1))
ldaOut2.terms <-as.matrix(terms(ldaOut2,10))
ldaOut2.terms

ldaOut2.topics<-as.data.frame(ldaOut2@gamma)
ldaOut2.topics$title = rownames(dtm2)


ldaOut3<-LDA(dtm3,k,method="Gibbs", control=list(burnin = burnin, iter = iter, thin=thin, verbose = 1))
ldaOut3.terms <-as.matrix(terms(ldaOut3,10))
ldaOut3.terms

ldaOut3.topics<-as.data.frame(ldaOut3@gamma)
ldaOut3.topics$title = rownames(dtm3)


headphone_review_data$title = headphone_review_data$review_title

headphone_review_data = merge(headphone_review_data, ldaOut2.topics, by=c("title"))


cor(headphone_review_data$individual_review_score, headphone_review_data[c(9:18)], use = "pairwise.complete.obs") 


save.image(file='myEnvironment.RData')

