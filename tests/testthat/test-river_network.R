Q = rep(1, 4)
adj = matrix(0, nrow = 4, ncol = 4)
adj[1,2] = adj[2,3] = adj[4,3] = 1

test_that("River network creation", {
	# Invalid topologies
	# not a matrix
	expect_error(river_network(as.vector(adj), Q), regex = "validation")

	# invalid weights
	adj[2,2] = -1
	expect_error(river_network(adj, Q), regex = "validation")
	adj[2,2] = Inf
	expect_error(river_network(adj, Q), regex = "validation")
	adj[2,2] = 0

	# cycles and loops
	adj[3,1] = 1
	expect_error(river_network(adj, Q), regex = "validation")
	adj[3,1] = 0
	adj[1,1] = 1
	expect_error(river_network(adj, Q), regex = "validation")
	adj[1,1] = 0

	# single node upstream of two downstream nodes
	adj[1,4] = 1
	expect_error(river_network(adj, Q), regex = "validation")
	adj[1,4] = 0

	# isolated nodes
	adj[4,3] = 0
	expect_error(river_network(adj, Q), regex = "validation")
	adj[4,3] = 1

	# invalid discharge
	expect_error(river_network(adj, Q[1:3]), regex = "nrow\\(discharge\\)")

	# works with regular and Matrix matrices
	expect_error(river_network(adj, Q), regex = NA)
	expect_error(river_network(Matrix::Matrix(adj), Q), regex = NA)
})

test_that("River network state manipulation", {
	rn = river_network(adj, Q)
	expect_true(is.null(state(rn)))

	st = matrix(seq(0, 1, length.out = length(Q)), ncol = 1, dimnames = list(NULL, 'R'))
	# construction with state

	expect_error(state(rn) <- st, regex=NA)
	expect_equal(state(rn), st, check.names = FALSE, check.attributes = FALSE)

	# try to add invalid states
	expect_error(state(rn) <- st[1:3, , drop=FALSE], regex = "one row per reach")

	# try to change state dimensionality
	expect_error(state(rn) <- cbind(st, st), regex = "one column per resource")

	# update state and retrieve history
	expect_error(state(rn) <- st + 1, regex=NA)
	expect_equal(state(rn), st + 1, , check.names = FALSE, check.attributes = FALSE)
	expect_equal(state(rn, history = TRUE)[[1]], st, , check.names = FALSE,
		check.attributes = FALSE)
	expect_equal(state(rn, history = TRUE)[[2]], state(rn), , check.names = FALSE,
		check.attributes = FALSE)

	# reset state
	expect_error(rn <- reset_state(rn, 1:nrow(adj)), regex=NA)
	expect_equal(length(state(rn, history = TRUE)), 1)
	expect_equal(dim(state(rn, history = TRUE)[[1]]), c(nrow(adj), 1))
})

test_that("River network community matrix", {
	rn = river_network(adj, Q)
	comm <- metacommunity()
	expect_error(site_by_species(rn), regex = "missing")
	expect_error(site_by_species(rn) <- community_random(rn, comm), regex = NA)
})
