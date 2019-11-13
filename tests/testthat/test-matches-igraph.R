
skip_if_not_installed("igraph")

library(igraph)

prefer <- function(node, total_nodes = 100) {
  alpha <- numeric(total_nodes)
  alpha[node] <- 1
  alpha
}

test_that("in_degree.igraph", {
  # TODO
})

test_that("out_degree.igraph", {
  # TODO
})

test_that("neighborhood.igraph", {
  # TODO
})

test_that("matches igraph calculations on connected graph", {

  # graph without sink nodes (i.e. every node has an outgoing edge)
  g3 <- make_ring(10)

  # make every node a seed node to recover page rank
  appr_pr <- appr(g3, seeds = as.character(1:10))

  # close enough but currently failing
  expect_equal(sum(appr_pr$p), 1, tolerance = 1e-4)

  appr_ppr <- appr(g3, seeds = "1")

  igraph_ppr <- page_rank(g3, personalized = prefer(1, 10))$vector

  # tolerance off by an order of magnitude again?
  expect_equal(sort(appr_ppr$p), sort(igraph_ppr), tolerance = 1e-5)
})

test_that("matches igraph calculations on graph with sink nodes", {

  set.seed(27)

  ig <- sample_pa(100)

  # make every node a seed node to recover page rank
  appr_pr <- appr(ig, seeds = as.character(1:10))

  # close enough but currently failing
  expect_equal(sum(appr_pr$p), 1, tolerance = 1e-5)

  appr_ppr <- appr(ig, seeds = "1")

  igraph_ppr <- page_rank(ig, personalized = prefer(1, 10))$vector

  # tolerance off by an order of magnitude again?
  expect_equal(sort(appr_ppr$p), sort(igraph_ppr), tolerance = 1e-5)
})
