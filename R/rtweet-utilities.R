safe_get_friends <- function(user_id, attempts) {

  token <- find_token("friends/ids")

  for (i in 1:attempts) {

    friends <- tryCatch({
      rtweet::get_friends(users = user_id, token = token)
    }, error = function(cond) {
      NULL
    }, warning = function(cond) {
      NULL
    })

    if (!is.null(friends))
      break
  }

  friends
}

safe_lookup_users <- function(user_id, attempts) {

  token <- find_token("users/lookup")

  for (i in 1:attempts) {

    user_data <- tryCatch({
      rtweet::lookup_users(users = user_id, token = token)
    }, error = function(cond) {
      NULL
    }, warning = function(cond) {
      NULL
    })

    if (!is.null(user_data))
      break
  }

  user_data
}

#' Find a token with remaining API requests
#'
#' @param query type of API request. options in clude ...
#' @param rate rate limit to ask (for use)
#' @param break_time  time interval to wait, in minutes
#' @param strategy 'random' for uniformly at random,
##            'seq' for in ascending order
#'
#' @return TODO
#'
find_token <- function(query,
                       rate = 1,
                       break_time = 2,
                       strategy = "random") {

  tokens <- twittercache:::get_all_tokens()

  found <- FALSE
  while (!found) {
    if (strategy == "random") {
      seq_find <- sample(seq_len(length(tokens)))
    } else if (strategy == "seq") {
      seq_find <- seq_len(length(tokens))
    }

    for (i in seq_find) {
      remaining <- tryCatch({
        rtweet::rate_limit(tokens[[i]], query = query)$remaining
      }, error = function(cond) {
        message(cond, " (find token)")
        return(0)
      }, warning = function(cond) {
        warning(cond, " (find token)")
        return(0)
      }, finally = {
        ## left blank intentionally
      })
      if (is.null(remaining) || !length(remaining)) remaining <- 0
      if (remaining > rate) break
    }

    if (remaining > rate) {
      token <- tokens[[i]]
      found <- TRUE
    } else {
      message(
        "All tokens are exhausted; let them breath... (", break_time,
        " mins) at ", Sys.time()
      )
      Sys.sleep(60 * break_time)
    }
  }
  token
}
